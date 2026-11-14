import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/application/auth_state.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:ctug_mobile/features/auth/data/auth_api_client.dart';
import 'package:ctug_mobile/features/auth/data/auth_failure.dart';
import 'package:ctug_mobile/features/auth/data/auth_repository.dart';
import 'package:ctug_mobile/features/auth/domain/authenticated_account.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAuthApiClient extends AuthApiClient {
  StubAuthApiClient() : super(dio: Dio(), cookieJar: CookieJar());

  AuthFailure? restoreFailure;
  AuthFailure? logoutFailure;
  AuthenticatedAccount? restoredAccount;
  AuthenticatedAccount? loginAccount;

  @override
  Future<AuthenticatedAccount?> currentSession() async {
    if (restoreFailure case final failure?) {
      throw failure;
    }
    return restoredAccount;
  }

  @override
  Future<void> clearCookies() async {}

  @override
  Future<AuthenticatedAccount> login({
    required String schoolId,
    required String password,
  }) async {
    if (loginAccount case final account?) {
      return account;
    }
    throw const BackendAuthFailure(
      statusCode: 401,
      code: 'invalid_credentials',
      message: 'Invalid credentials.',
    );
  }

  @override
  Future<void> logout() async {
    if (logoutFailure case final failure?) {
      throw failure;
    }
  }
}

void main() {
  const account = AuthenticatedAccount(
    schoolId: '1234567',
    roles: ['Student'],
    permissions: [],
  );

  test('restoring an unreachable session becomes an explicit error', () async {
    final apiClient = StubAuthApiClient()
      ..restoreFailure = const NetworkUnavailableFailure();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepository(apiClient)),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    expect(container.read(authControllerProvider).status, AuthStatus.restoring);
    await controller.restoreSession();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.error);
    expect(state.account, isNull);
    expect(state.isAuthenticated, isFalse);
    expect(state.failure, isA<NetworkUnavailableFailure>());
  });

  test(
    'failed logout retains the account and exposes a retryable error',
    () async {
      final apiClient = StubAuthApiClient()
        ..loginAccount = account
        ..logoutFailure = const NetworkUnavailableFailure();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(apiClient)),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);

      await controller.login(schoolId: account.schoolId, password: 'secret');
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );

      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.account, account);
      expect(state.isAuthenticated, isTrue);
      expect(state.failure, isA<NetworkUnavailableFailure>());
    },
  );
}
