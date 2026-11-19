class RegistrationVerification {
  const RegistrationVerification({
    required this.status,
    this.deliverySent = false,
    this.expiresIn = 0,
    this.retryAfter = 0,
    this.resendsRemaining = 0,
    this.attemptsRemaining = 0,
    this.codeValidSeconds,
    this.requestedRole,
  });

  final String status;
  final bool deliverySent;
  final int expiresIn;
  final int retryAfter;
  final int resendsRemaining;
  final int attemptsRemaining;
  final int? codeValidSeconds;
  final String? requestedRole;

  bool get isComplete => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory RegistrationVerification.fromResponse(Map<String, dynamic> body) {
    final status = body['status'];
    if (status is! String ||
        !{
          'verification_required',
          'existing_verification',
          'completed',
          'cancelled',
        }.contains(status)) {
      throw const FormatException(
        'Unexpected registration verification status.',
      );
    }
    final role = body['requested_role'];
    if (role != null && role != 'Student' && role != 'Instructor') {
      throw const FormatException('Unexpected registration role.');
    }
    if (status == 'completed' || status == 'cancelled') {
      return RegistrationVerification(
        status: status,
        requestedRole: role as String?,
      );
    }
    int count(String key) {
      final value = body[key];
      if (value is! int || value < 0 || value > 86400) {
        throw const FormatException('Unexpected registration timing data.');
      }
      return value;
    }

    final deliverySent = body['delivery_sent'];
    if (deliverySent is! bool) {
      throw const FormatException('Unexpected registration delivery data.');
    }
    final codeSeconds = body['code_valid_seconds'];
    return RegistrationVerification(
      status: status,
      deliverySent: deliverySent,
      expiresIn: count('expires_in'),
      retryAfter: count('retry_after'),
      resendsRemaining: count('resends_remaining'),
      attemptsRemaining: count('attempts_remaining'),
      codeValidSeconds:
          codeSeconds is int && codeSeconds > 0 && codeSeconds <= 86400
          ? codeSeconds
          : null,
      requestedRole: role as String?,
    );
  }
}
