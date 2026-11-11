import 'environment.dart';

export 'environment.dart' show AppConfigException, Environment, LogLevel;

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.isPlaceholderUrl,
  });

  final Environment environment;
  final Uri apiBaseUrl;
  final LogLevel logLevel;
  final bool isPlaceholderUrl;

  factory AppConfig.fromValues({
    String? appEnv,
    String? apiBaseUrl,
    String? logLevel,
  }) {
    final environment = Environment.parse(appEnv);
    if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
      throw const AppConfigException('API_BASE_URL is required.');
    }

    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.isAbsolute) {
      throw const AppConfigException('API_BASE_URL must be an absolute URL.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const AppConfigException(
        'API_BASE_URL must use the http or https scheme.',
      );
    }
    if (uri.host.isEmpty) {
      throw const AppConfigException('API_BASE_URL must include a host.');
    }
    if (uri.userInfo.isNotEmpty ||
        uri.authority.contains('@') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const AppConfigException(
        'API_BASE_URL must not contain user-info, a query, or a fragment.',
      );
    }

    final normalizedUri = uri.path.endsWith('/')
        ? uri
        : uri.replace(path: '${uri.path}/');
    final isPlaceholderUrl = normalizedUri.host.endsWith('.invalid');

    if (environment == Environment.production) {
      if (normalizedUri.scheme != 'https') {
        throw const AppConfigException(
          'Production API_BASE_URL must use https.',
        );
      }
      if (isPlaceholderUrl) {
        throw const AppConfigException(
          'Production API_BASE_URL must not use a placeholder host.',
        );
      }
    }

    return AppConfig(
      environment: environment,
      apiBaseUrl: normalizedUri,
      logLevel: logLevel == null ? LogLevel.info : LogLevel.parse(logLevel),
      isPlaceholderUrl: isPlaceholderUrl,
    );
  }

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromValues(
      appEnv: const String.fromEnvironment('APP_ENV'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      logLevel: const String.fromEnvironment('LOG_LEVEL', defaultValue: 'info'),
    );
  }
}
