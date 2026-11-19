import '../domain/authenticated_account.dart';
import '../domain/registration_request.dart';
import '../domain/registration_verification.dart';
import 'auth_api_client.dart';

class AuthRepository {
  const AuthRepository(this._apiClient);

  final AuthApiClient _apiClient;

  Future<AuthenticatedAccount> login({
    required String schoolId,
    required String password,
  }) => _apiClient.login(schoolId: schoolId, password: password);

  Future<RegistrationVerification> register(RegistrationRequest request) =>
      _apiClient.register(request);

  Future<RegistrationVerification> registrationStatus({String? role}) =>
      _apiClient.registrationStatus(role: role);

  Future<RegistrationVerification> verifyRegistrationCode({
    required String code,
    String? role,
  }) => _apiClient.verifyRegistrationCode(code: code, role: role);

  Future<RegistrationVerification> resendRegistrationCode({String? role}) =>
      _apiClient.resendRegistrationCode(role: role);

  Future<void> cancelRegistration({String? role}) =>
      _apiClient.cancelRegistration(role: role);

  Future<PasswordResetCodeRequest> requestPasswordResetCode({
    required String email,
  }) => _apiClient.requestPasswordResetCode(email: email);

  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) => _apiClient.verifyPasswordResetCode(email: email, code: code);

  Future<void> confirmPasswordReset({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => _apiClient.confirmPasswordReset(
    email: email,
    password: password,
    passwordConfirmation: passwordConfirmation,
  );

  Future<void> requestPasswordReset({
    required String schoolId,
    required String email,
  }) async {
    await _apiClient.requestPasswordResetCode(email: email);
  }

  Future<AuthenticatedAccount?> restoreSession() async {
    final account = await _apiClient.currentSession();
    if (account == null) {
      await _apiClient.clearCookies();
    }
    return account;
  }

  Future<void> logout() => _apiClient.logout();
}
