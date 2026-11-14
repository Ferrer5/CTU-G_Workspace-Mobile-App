import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../domain/authenticated_account.dart';
import '../domain/registration_request.dart';
import 'auth_failure.dart';

class RegistrationAcknowledgement {
  const RegistrationAcknowledgement(this.message);

  final String message;
}

class AuthApiClient {
  AuthApiClient({required this.dio, required this.cookieJar}) {
    dio.interceptors.add(CookieManager(cookieJar));
  }

  static const csrfPath = 'auth/csrf/';
  static const registerPath = 'auth/register/';
  static const loginPath = 'auth/login/';
  static const logoutPath = 'auth/logout/';
  static const sessionPath = 'auth/session/';
  static const _csrfCookieNames = {'csrftoken', 'ctug_review_sandbox_csrf'};

  final Dio dio;
  final CookieJar cookieJar;
  bool _csrfReady = false;
  Future<void>? _csrfBootstrap;
  String? _latestBootstrapCsrfCookieName;

  Future<AuthenticatedAccount> login({
    required String schoolId,
    required String password,
  }) async {
    final response = await _post(loginPath, {
      'school_id': schoolId,
      'password': password,
    });
    if (response.statusCode != 200 || response.body['authenticated'] != true) {
      throw const InvalidApiResponseFailure();
    }
    return AuthenticatedAccount.fromResponse(response.body);
  }

  Future<RegistrationAcknowledgement> register(
    RegistrationRequest request,
  ) async {
    final response = await _post(registerPath, request.toJson());
    final message = response.body['message'];
    if (response.statusCode != 202 || message is! String || message.isEmpty) {
      throw const InvalidApiResponseFailure();
    }
    return RegistrationAcknowledgement(message);
  }

  Future<AuthenticatedAccount?> currentSession() async {
    final response = await _get(sessionPath);
    if (response.statusCode != 200) {
      throw const InvalidApiResponseFailure();
    }
    final authenticated = response.body['authenticated'];
    if (authenticated == false) {
      return null;
    }
    if (authenticated != true) {
      throw const InvalidApiResponseFailure();
    }
    return AuthenticatedAccount.fromResponse(response.body);
  }

  Future<void> logout() async {
    final response = await _post(logoutPath, const <String, Object?>{});
    if (response.statusCode != 200 || response.body['authenticated'] != false) {
      throw const InvalidApiResponseFailure();
    }
    await clearCookies();
  }

  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
    _csrfReady = false;
    _csrfBootstrap = null;
    _latestBootstrapCsrfCookieName = null;
  }

  void close() => dio.close(force: true);

  Future<_ApiResponse> _get(String path) => _send('GET', path);

  Future<_ApiResponse> _post(String path, Map<String, Object?> body) async {
    await _ensureCsrf();
    final csrfCookie = await _readCurrentCsrfCookie();
    return _send(
      'POST',
      path,
      body: body,
      headers: {'X-CSRFToken': csrfCookie.value},
    );
  }

  Future<void> _ensureCsrf() async {
    if (_csrfReady) {
      return;
    }
    final bootstrap = _csrfBootstrap ??= _bootstrapCsrf();
    try {
      await bootstrap;
      _csrfReady = true;
    } finally {
      if (!_csrfReady) {
        _csrfBootstrap = null;
      }
    }
  }

  Future<void> _bootstrapCsrf() async {
    final response = await _get(csrfPath);
    if (response.statusCode != 200 ||
        response.body['csrfToken'] is! String ||
        (response.body['csrfToken'] as String).isEmpty) {
      throw const InvalidApiResponseFailure();
    }
    _latestBootstrapCsrfCookieName = null;
    for (final header in response.setCookieHeaders) {
      final separator = header.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final name = header.substring(0, separator).trim();
      if (_csrfCookieNames.contains(name)) {
        _latestBootstrapCsrfCookieName = name;
      }
    }
    await _readCurrentCsrfCookie();
  }

  Future<Cookie> _readCurrentCsrfCookie() async {
    final cookies = await cookieJar.loadForRequest(
      Uri.parse(dio.options.baseUrl),
    );
    final preferredName = _latestBootstrapCsrfCookieName;
    if (preferredName != null) {
      for (final cookie in cookies) {
        if (cookie.name == preferredName && cookie.value.isNotEmpty) {
          return cookie;
        }
      }
      throw const MissingCsrfCookieFailure();
    }
    for (final cookie in cookies) {
      if (_csrfCookieNames.contains(cookie.name) && cookie.value.isNotEmpty) {
        return cookie;
      }
    }
    throw const MissingCsrfCookieFailure();
  }

  Future<_ApiResponse> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?>? headers,
  }) async {
    late final Response<dynamic> response;
    try {
      response = await dio.request<dynamic>(
        path,
        data: body,
        options: Options(
          method: method,
          headers: headers,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (error) {
      throw _mapDioFailure(error);
    }

    final decoded = _decodeJsonResponse(response);
    final statusCode = response.statusCode;
    if (statusCode == null) {
      throw const InvalidApiResponseFailure();
    }
    if (statusCode >= 400) {
      if ({400, 401, 403, 429, 503}.contains(statusCode)) {
        throw _parseBackendFailure(statusCode, decoded);
      }
      throw const InvalidApiResponseFailure();
    }
    if (decoded is! Map<String, dynamic>) {
      throw const InvalidApiResponseFailure();
    }
    return _ApiResponse(
      statusCode,
      decoded,
      response.headers['set-cookie'] ?? const [],
    );
  }

  Object? _decodeJsonResponse(Response<dynamic> response) {
    final contentType = response.headers.value(Headers.contentTypeHeader);
    final mediaType = contentType?.split(';').first.trim().toLowerCase();
    if (mediaType != 'application/json' &&
        !(mediaType?.endsWith('+json') ?? false)) {
      throw const NonJsonResponseFailure();
    }
    final data = response.data;
    if (data is! String) {
      throw const InvalidApiResponseFailure();
    }
    try {
      return jsonDecode(data);
    } on FormatException {
      throw const MalformedJsonResponseFailure();
    }
  }

  AuthFailure _parseBackendFailure(int statusCode, Object? body) {
    if (body is! Map<String, dynamic> ||
        body['error'] is! Map<String, dynamic>) {
      return const InvalidApiResponseFailure();
    }
    final error = body['error'] as Map<String, dynamic>;
    final code = error['code'];
    final message = error['message'];
    final fields = error['fields'];
    if (code is! String ||
        code.isEmpty ||
        message is! String ||
        message.isEmpty ||
        (fields != null && fields is! Map<String, dynamic>)) {
      return const InvalidApiResponseFailure();
    }
    return BackendAuthFailure(
      statusCode: statusCode,
      code: code,
      message: message,
      fields: fields as Map<String, dynamic>?,
    );
  }

  AuthFailure _mapDioFailure(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const RequestTimeoutFailure();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return const NetworkUnavailableFailure();
    }
    return const ApiTransportFailure();
  }
}

class _ApiResponse {
  const _ApiResponse(this.statusCode, this.body, this.setCookieHeaders);

  final int statusCode;
  final Map<String, dynamic> body;
  final List<String> setCookieHeaders;
}

AuthApiClient createAuthApiClient({
  required Uri baseUrl,
  required CookieJar cookieJar,
  Dio? dio,
}) {
  final client =
      dio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl.toString(),
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
          headers: {Headers.acceptHeader: 'application/json'},
        ),
      );
  return AuthApiClient(dio: client, cookieJar: cookieJar);
}
