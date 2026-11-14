import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

class MemoryCookieStorage extends Storage {
  final values = <String, String>{};

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}

class RecordedRequest {
  const RecordedRequest({required this.options, required this.body});

  final RequestOptions options;
  final String? body;
}

typedef RequestHandler = Future<ResponseBody> Function(RecordedRequest request);

class ScriptedHttpAdapter implements HttpClientAdapter {
  ScriptedHttpAdapter(this.handle);

  final RequestHandler handle;
  final requests = <RecordedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final requestBytes = requestStream == null
        ? null
        : await requestStream.fold<List<int>>(
            <int>[],
            (bytes, chunk) => bytes..addAll(chunk),
          );
    final request = RecordedRequest(
      options: options,
      body: requestBytes == null ? null : utf8.decode(requestBytes),
    );
    requests.add(request);
    return handle(request);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  Object? value, {
  int statusCode = 200,
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(value),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      ...headers,
    },
  );
}

ResponseBody rawResponse(
  String value, {
  int statusCode = 200,
  String contentType = 'application/json',
}) {
  return ResponseBody.fromString(
    value,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [contentType],
    },
  );
}

({Dio dio, PersistCookieJar jar}) createMockTransport(
  ScriptedHttpAdapter adapter, {
  MemoryCookieStorage? storage,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://auth.example.test/api/v1/',
      contentType: Headers.jsonContentType,
      responseType: ResponseType.plain,
      headers: {Headers.acceptHeader: 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..httpClientAdapter = adapter;
  final jar = PersistCookieJar(
    persistSession: true,
    storage: storage ?? MemoryCookieStorage(),
  );
  return (dio: dio, jar: jar);
}
