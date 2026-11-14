import '../data/auth_failure.dart';
import '../domain/authenticated_account.dart';

enum AuthStatus { restoring, authenticated, unauthenticated, error }

class AuthState {
  const AuthState._({required this.status, this.account, this.failure});

  const AuthState.restoring() : this._(status: AuthStatus.restoring);

  const AuthState.authenticated(AuthenticatedAccount account)
    : this._(status: AuthStatus.authenticated, account: account);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.error(AuthFailure failure, {AuthenticatedAccount? account})
    : this._(status: AuthStatus.error, account: account, failure: failure);

  final AuthStatus status;
  final AuthenticatedAccount? account;
  final AuthFailure? failure;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated ||
      (status == AuthStatus.error && account != null);
}
