import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_providers.dart';
import '../data/auth_api_client.dart';
import '../data/auth_failure.dart';
import '../domain/registration_request.dart';
import 'auth_state.dart';

class AuthController extends Notifier<AuthState> {
  Future<void>? _restoreSessionOperation;
  int _authGeneration = 0;

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
    final generation = _authGeneration;
    state = const AuthState.restoring();
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .restoreSession()
          .timeout(const Duration(seconds: 15));
      if (generation != _authGeneration) {
        return;
      }
      state = account == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(account);
    } on AuthFailure catch (failure) {
      if (generation == _authGeneration) {
        state = AuthState.error(failure);
      }
    } on TimeoutException {
      if (generation == _authGeneration) {
        state = const AuthState.error(RequestTimeoutFailure());
      }
    }
  }

  void resetForServerChange() {
    _authGeneration++;
    _restoreSessionOperation = null;
    state = const AuthState.restoring();
  }

  Future<void> login({
    required String schoolId,
    required String password,
  }) async {
    final generation = _authGeneration;
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .login(schoolId: schoolId, password: password);
      if (generation == _authGeneration) {
        state = AuthState.authenticated(account);
      }
    } on AuthFailure catch (failure) {
      if (generation == _authGeneration) {
        state = AuthState.error(failure);
      }
    }
  }

  Future<RegistrationAcknowledgement> register(
    RegistrationRequest request,
  ) async {
    final generation = _authGeneration;
    try {
      return await ref.read(authRepositoryProvider).register(request);
    } on AuthFailure catch (failure) {
      if (generation == _authGeneration) {
        state = AuthState.error(failure, account: state.account);
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final generation = _authGeneration;
    final account = state.account;
    try {
      await ref.read(authRepositoryProvider).logout();
      if (generation == _authGeneration) {
        state = const AuthState.unauthenticated();
      }
    } on AuthFailure catch (failure) {
      if (generation == _authGeneration) {
        state = AuthState.error(failure, account: account);
      }
    }
  }
}
