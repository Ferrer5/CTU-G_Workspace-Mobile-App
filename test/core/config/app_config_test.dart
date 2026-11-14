import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig.fromValues', () {
    test('validates every tracked environment example', () async {
      final examples =
          Directory('env')
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.example.json'))
              .toList()
            ..sort((left, right) => left.path.compareTo(right.path));

      expect(examples, isNotEmpty);

      for (final example in examples) {
        final values = Map<String, dynamic>.from(
          jsonDecode(await example.readAsString()) as Map,
        );
        final appEnv = values['APP_ENV'] as String;
        final apiBaseUrl = values['API_BASE_URL'] as String;
        final logLevel = values['LOG_LEVEL'] as String;

        if (appEnv == 'production') {
          expect(
            () => AppConfig.fromValues(
              appEnv: appEnv,
              apiBaseUrl: apiBaseUrl,
              logLevel: logLevel,
            ),
            throwsA(isA<AppConfigException>()),
            reason: '${example.path} should not accept a placeholder host',
          );
          continue;
        }

        final config = AppConfig.fromValues(
          appEnv: appEnv,
          apiBaseUrl: apiBaseUrl,
          logLevel: logLevel,
        );

        expect(config.environment, Environment.parse(appEnv));
        expect(config.apiBaseUrl.toString(), apiBaseUrl);
        expect(config.logLevel, LogLevel.parse(logLevel));
      }
    });

    test('sandbox example targets the API v1 root', () async {
      final values = Map<String, dynamic>.from(
        jsonDecode(await File('env/sandbox.example.json').readAsString())
            as Map,
      );
      final apiBaseUrl = Uri.parse(values['API_BASE_URL'] as String);

      expect(apiBaseUrl.path, '/api/v1/');
    });

    test('creates a development configuration', () {
      final config = AppConfig.fromValues(
        appEnv: 'development',
        apiBaseUrl: 'http://localhost/api/v1/',
        logLevel: 'debug',
      );

      expect(config.environment, Environment.development);
      expect(config.apiBaseUrl.toString(), 'http://localhost/api/v1/');
      expect(config.logLevel, LogLevel.debug);
      expect(config.isPlaceholderUrl, isFalse);
    });

    test('creates a test configuration', () {
      final config = AppConfig.fromValues(
        appEnv: 'test',
        apiBaseUrl: 'https://test.example.com/api/v1/',
      );

      expect(config.environment, Environment.test);
      expect(config.logLevel, LogLevel.info);
    });

    test('creates a production configuration with https', () {
      final config = AppConfig.fromValues(
        appEnv: 'production',
        apiBaseUrl: 'https://api.example.com/api/v1/',
        logLevel: 'warning',
      );

      expect(config.environment, Environment.production);
      expect(config.isPlaceholderUrl, isFalse);
      expect(config.logLevel, LogLevel.warning);
    });

    test('rejects missing APP_ENV', () {
      expect(
        () => AppConfig.fromValues(apiBaseUrl: 'https://example.com/api/v1/'),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects an empty APP_ENV', () {
      expect(
        () => AppConfig.fromValues(
          appEnv: '',
          apiBaseUrl: 'https://example.com/api/v1/',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects unsupported APP_ENV', () {
      expect(
        () => AppConfig.fromValues(
          appEnv: 'staging',
          apiBaseUrl: 'https://example.com/api/v1/',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects missing API_BASE_URL', () {
      expect(
        () => AppConfig.fromValues(appEnv: 'development'),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects relative, unsupported-scheme, and hostless URLs', () {
      for (final url in [
        'api/v1/',
        'ftp://example.com/api/v1/',
        'http:///api/v1/',
      ]) {
        expect(
          () => AppConfig.fromValues(appEnv: 'development', apiBaseUrl: url),
          throwsA(isA<AppConfigException>()),
          reason: 'Expected $url to be rejected',
        );
      }
    });

    test('rejects URL user-info', () {
      expect(
        () => AppConfig.fromValues(
          appEnv: 'development',
          apiBaseUrl: 'https://user@example.com/api/v1/',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects query and fragment components', () {
      for (final url in [
        'https://example.com/api/v1/?key=value',
        'https://example.com/api/v1/#section',
      ]) {
        expect(
          () => AppConfig.fromValues(appEnv: 'development', apiBaseUrl: url),
          throwsA(isA<AppConfigException>()),
        );
      }
    });

    test('normalizes the URL with a trailing slash', () {
      final config = AppConfig.fromValues(
        appEnv: 'development',
        apiBaseUrl: 'https://example.com/api/v1',
      );

      expect(config.apiBaseUrl.toString(), 'https://example.com/api/v1/');
    });

    test('detects placeholder hosts', () {
      final config = AppConfig.fromValues(
        appEnv: 'development',
        apiBaseUrl: 'https://example.invalid/api/v1/',
      );

      expect(config.isPlaceholderUrl, isTrue);
    });

    test('rejects http and placeholder URLs in production', () {
      for (final url in [
        'http://api.example.com/api/v1/',
        'https://example.invalid/api/v1/',
      ]) {
        expect(
          () => AppConfig.fromValues(appEnv: 'production', apiBaseUrl: url),
          throwsA(isA<AppConfigException>()),
          reason: 'Expected production URL $url to be rejected',
        );
      }
    });

    test('uses the default info log level and rejects invalid values', () {
      final config = AppConfig.fromValues(
        appEnv: 'development',
        apiBaseUrl: 'https://example.com/api/v1/',
      );

      expect(config.logLevel, LogLevel.info);
      expect(
        () => AppConfig.fromValues(
          appEnv: 'development',
          apiBaseUrl: 'https://example.com/api/v1/',
          logLevel: 'trace',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
