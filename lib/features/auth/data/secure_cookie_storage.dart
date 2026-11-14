import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCookieStorage extends Storage {
  SecureCookieStorage({
    required this.secureStorage,
    this.keyPrefix = 'ctug.auth.cookies.',
  });

  final FlutterSecureStorage secureStorage;
  final String keyPrefix;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => secureStorage.read(key: '$keyPrefix$key');

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
