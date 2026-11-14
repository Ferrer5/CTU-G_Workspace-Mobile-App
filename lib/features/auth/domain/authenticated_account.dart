import '../data/auth_failure.dart';

class AuthenticatedAccount {
  const AuthenticatedAccount({
    required this.schoolId,
    required this.roles,
    required this.permissions,
  });

  final String schoolId;
  final List<String> roles;
  final List<String> permissions;

  factory AuthenticatedAccount.fromResponse(Map<String, dynamic> response) {
    final account = response['account'];
    final schoolId = account is Map<String, dynamic>
        ? account['school_id']
        : null;
    final roles = account is Map<String, dynamic> ? account['roles'] : null;
    final permissions = response['permissions'];

    if (schoolId is! String ||
        schoolId.isEmpty ||
        roles is! List ||
        roles.isEmpty ||
        roles.any((role) => role is! String || role.isEmpty) ||
        permissions is! List ||
        permissions.any((permission) => permission is! String)) {
      throw const InvalidApiResponseFailure();
    }

    return AuthenticatedAccount(
      schoolId: schoolId,
      roles: List.unmodifiable(roles.cast<String>()),
      permissions: List.unmodifiable(permissions.cast<String>()),
    );
  }
}
