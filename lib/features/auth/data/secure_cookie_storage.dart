import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

import 'auth_failure.dart';

class SecureCookieStorage extends Storage {
  SecureCookieStorage({required this.secureStorage, required this.keyPrefix});

  static String keyPrefixFor(Uri apiBaseUrl) =>
      'ctug.auth.cookies.${Uri.encodeComponent('${apiBaseUrl.host}:${apiBaseUrl.port}')}.';

  final FlutterSecureStorage secureStorage;
  final String keyPrefix;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async {
    try {
      return await secureStorage
          .read(key: '$keyPrefix$key')
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const RequestTimeoutFailure();
    } on PlatformException {
      throw const ApiTransportFailure();
    }
  }

  @override
  Future<void> write(String key, String value) =>
      secureStorage.write(key: '$keyPrefix$key', value: value);

  @override
  Future<void> delete(String key) =>
      secureStorage.delete(key: '$keyPrefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}
