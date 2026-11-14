sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackendAuthFailure extends AuthFailure {
  const BackendAuthFailure({
    required this.statusCode,
    required this.code,
    required String message,
    this.fields,
  }) : super(message);

  final int statusCode;
  final String code;
  final Map<String, dynamic>? fields;
}

class RequestTimeoutFailure extends AuthFailure {
  const RequestTimeoutFailure()
    : super('The authentication request timed out.');
}

class NetworkUnavailableFailure extends AuthFailure {
  const NetworkUnavailableFailure()
    : super('The authentication server is unreachable.');
}

class NonJsonResponseFailure extends AuthFailure {
  const NonJsonResponseFailure()
    : super('The authentication server returned a non-JSON response.');
}

class MalformedJsonResponseFailure extends AuthFailure {
  const MalformedJsonResponseFailure()
    : super('The authentication server returned malformed JSON.');
}

class InvalidApiResponseFailure extends AuthFailure {
  const InvalidApiResponseFailure()
    : super('The authentication server returned an unexpected response.');
}

class MissingCsrfCookieFailure extends AuthFailure {
  const MissingCsrfCookieFailure()
    : super('The authentication server did not provide a CSRF cookie.');
}

class ApiTransportFailure extends AuthFailure {
  const ApiTransportFailure()
    : super('The authentication request could not be completed.');
}
