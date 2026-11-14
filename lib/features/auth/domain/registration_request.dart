class RegistrationRequest {
  const RegistrationRequest({
    required this.schoolId,
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffix,
    required this.requestedRole,
    required this.password,
    required this.passwordConfirmation,
  });

  final String schoolId;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String requestedRole;
  final String password;
  final String passwordConfirmation;

  Map<String, String> toJson() => {
    'school_id': schoolId,
    'email': email,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'suffix': suffix,
    'requested_role': requestedRole,
    'password': password,
    'password_confirmation': passwordConfirmation,
  };
}
