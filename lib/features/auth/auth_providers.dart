import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/providers.dart';
import 'application/auth_controller.dart';
import 'application/auth_state.dart';
import 'data/auth_api_client.dart';
import 'data/auth_repository.dart';
import 'data/secure_cookie_storage.dart';

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final jar = PersistCookieJar(
    persistSession: true,
    storage: SecureCookieStorage(secureStorage: const FlutterSecureStorage()),
  );
  final client = createAuthApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    cookieJar: jar,
  );
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authApiClientProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
