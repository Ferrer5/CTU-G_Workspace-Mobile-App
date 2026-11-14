import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_providers.dart';
import '../data/auth_api_client.dart';
import '../data/auth_failure.dart';
import '../domain/registration_request.dart';
import 'auth_state.dart';

class AuthController extends Notifier<AuthState> {
  Future<void>? _restoreSessionOperation;

  @override
  AuthState build() => const AuthState.restoring();

  Future<void> restoreSession() {
    final operation = _restoreSessionOperation;
    if (operation != null) {
      return operation;
    }
    final restore = _restoreSession();
    _restoreSessionOperation = restore;
    return restore.whenComplete(() {
      if (identical(_restoreSessionOperation, restore)) {
        _restoreSessionOperation = null;
      }
    });
  }

  Future<void> _restoreSession() async {
    state = const AuthState.restoring();
    try {
      final account = await ref.read(authRepositoryProvider).restoreSession();
      state = account == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(account);
    } on AuthFailure catch (failure) {
      state = AuthState.error(failure);
    }
  }

  Future<void> login({
    required String schoolId,
    required String password,
  }) async {
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .login(schoolId: schoolId, password: password);
      state = AuthState.authenticated(account);
    } on AuthFailure catch (failure) {
      state = AuthState.error(failure);
    }
  }

  Future<RegistrationAcknowledgement> register(
    RegistrationRequest request,
  ) async {
    try {
      return await ref.read(authRepositoryProvider).register(request);
    } on AuthFailure catch (failure) {
      state = AuthState.error(failure, account: state.account);
      rethrow;
    }
  }

  Future<void> logout() async {
    final account = state.account;
    try {
      await ref.read(authRepositoryProvider).logout();
      state = const AuthState.unauthenticated();
    } on AuthFailure catch (failure) {
      state = AuthState.error(failure, account: account);
    }
  }
}
