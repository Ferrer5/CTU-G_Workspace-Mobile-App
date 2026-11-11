class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

enum Environment {
  development,
  test,
  production;

  static Environment parse(String? value) {
    return switch (value) {
      'development' => Environment.development,
      'test' => Environment.test,
      'production' => Environment.production,
      _ => throw AppConfigException(
        'APP_ENV must be development, test, or production.',
      ),
    };
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error;

  static LogLevel parse(String? value) {
    return switch (value) {
      'debug' => LogLevel.debug,
      'info' => LogLevel.info,
      'warning' => LogLevel.warning,
      'error' => LogLevel.error,
      _ => throw AppConfigException(
        'LOG_LEVEL must be debug, info, warning, or error.',
      ),
    };
  }
}
