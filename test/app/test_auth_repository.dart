import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/data/auth_api_client.dart';
import 'package:ctug_mobile/features/auth/data/auth_repository.dart';
import 'package:ctug_mobile/features/auth/domain/authenticated_account.dart';
import 'package:ctug_mobile/features/auth/domain/registration_request.dart';
import 'package:dio/dio.dart';

typedef RestoreHandler = Future<AuthenticatedAccount?> Function();
typedef LoginHandler = Future<AuthenticatedAccount> Function({
  required String schoolId,
  required String password,
});
typedef LogoutHandler = Future<void> Function();

class TestAuthRepository extends AuthRepository {
  TestAuthRepository({
    RestoreHandler? restoreHandler,
    LoginHandler? loginHandler,
    LogoutHandler? logoutHandler,
  }) : restoreHandler = restoreHandler ?? _restoreUnauthenticated,
       loginHandler = loginHandler ?? _loginSuccessfully,
       logoutHandler = logoutHandler ?? _logoutSuccessfully,
       super(AuthApiClient(dio: Dio(), cookieJar: CookieJar()));

  static const account = AuthenticatedAccount(
    schoolId: '1234567',
    roles: ['Student', 'Instructor'],
    permissions: ['not.displayed.permission'],
  );

  final RestoreHandler restoreHandler;
  final LoginHandler loginHandler;
  final LogoutHandler logoutHandler;
  int restoreCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  static Future<AuthenticatedAccount?> _restoreUnauthenticated() async => null;

  static Future<AuthenticatedAccount> _loginSuccessfully({
    required String schoolId,
    required String password,
  }) async => account;

  static Future<void> _logoutSuccessfully() async {}

  @override
  Future<AuthenticatedAccount?> restoreSession() {
    restoreCalls++;
    return restoreHandler();
  }

  @override
  Future<AuthenticatedAccount> login({
    required String schoolId,
    required String password,
  }) {
    loginCalls++;
    return loginHandler(schoolId: schoolId, password: password);
  }

  @override
  Future<RegistrationAcknowledgement> register(RegistrationRequest request) =>
      Future.value(const RegistrationAcknowledgement('Request received.'));

  @override
  Future<void> logout() {
    logoutCalls++;
    return logoutHandler();
  }
}
