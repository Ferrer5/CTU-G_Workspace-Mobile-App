import '../domain/authenticated_account.dart';
import '../domain/registration_request.dart';
import 'auth_api_client.dart';

class AuthRepository {
  const AuthRepository(this._apiClient);

  final AuthApiClient _apiClient;

  Future<AuthenticatedAccount> login({
    required String schoolId,
    required String password,
  }) => _apiClient.login(schoolId: schoolId, password: password);

  Future<RegistrationAcknowledgement> register(RegistrationRequest request) =>
      _apiClient.register(request);

  Future<void> requestPasswordReset({
    required String schoolId,
    required String email,
  }) => _apiClient.requestPasswordReset(schoolId: schoolId, email: email);

  Future<AuthenticatedAccount?> restoreSession() async {
    final account = await _apiClient.currentSession();
    if (account == null) {
      await _apiClient.clearCookies();
    }
    return account;
  }

  Future<void> logout() => _apiClient.logout();
}
