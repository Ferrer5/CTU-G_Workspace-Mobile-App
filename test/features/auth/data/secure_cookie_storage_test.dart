import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/data/secure_cookie_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
