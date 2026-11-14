import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/data/secure_cookie_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persisted cookies are isolated by API host and port', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const secureStorage = FlutterSecureStorage();
    final sandboxUri = Uri.parse('http://127.0.0.1:8001/api/v1/');
    final realUri = Uri.parse('http://127.0.0.1:8000/api/v1/');
    final sandboxStorage = SecureCookieStorage(
      secureStorage: secureStorage,
      keyPrefix: SecureCookieStorage.keyPrefixFor(sandboxUri),
    );
    final realStorage = SecureCookieStorage(
      secureStorage: secureStorage,
      keyPrefix: SecureCookieStorage.keyPrefixFor(realUri),
    );
    final sandboxJar = PersistCookieJar(
      persistSession: true,
      storage: sandboxStorage,
    );
    final realJar = PersistCookieJar(
      persistSession: true,
      storage: realStorage,
    );
    await sandboxJar.saveFromResponse(sandboxUri, [
      Cookie('sessionid', 'sandbox-session')..path = '/',
    ]);

    expect(await realJar.loadForRequest(realUri), isEmpty);

    await realJar.saveFromResponse(realUri, [
      Cookie('sessionid', 'real-session')..path = '/',
    ]);
    expect(
      (await sandboxJar.loadForRequest(sandboxUri)).single.value,
      'sandbox-session',
    );
  });

  test(
    'PersistCookieJar reloads session cookies from secure storage',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const secureStorage = FlutterSecureStorage();
      final storage = SecureCookieStorage(
        secureStorage: secureStorage,
        keyPrefix: 'test.auth.cookies.',
      );
      final uri = Uri.parse('https://auth.example.test/api/v1/');
      final firstJar = PersistCookieJar(persistSession: true, storage: storage);

      await firstJar.saveFromResponse(uri, [
        Cookie('sessionid', 'session-secret')..path = '/',
        Cookie('csrftoken', 'csrf-secret')..path = '/',
      ]);

      final restoredJar = PersistCookieJar(
        persistSession: true,
        storage: storage,
      );
      final restored = await restoredJar.loadForRequest(uri);

      expect(
        restored.map((cookie) => cookie.name),
        containsAll(['sessionid', 'csrftoken']),
      );
      await restoredJar.deleteAll();
      expect(await storage.read('.index'), isNull);
    },
  );
}
