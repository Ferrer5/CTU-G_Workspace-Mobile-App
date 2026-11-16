import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/app/server_settings.dart';
import 'package:ctug_mobile/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaultApiUrl = 'https://api.example.test/api/v1/';
  const savedApiUrl = 'http://192.168.113.168:8000/api/v1/';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('settings enabled defaults to kDebugMode and can be overridden', () {
    final defaultContainer = ProviderContainer();
    addTearDown(defaultContainer.dispose);
    expect(defaultContainer.read(serverSettingsEnabledProvider), kDebugMode);

    final disabledContainer = ProviderContainer(
      overrides: [serverSettingsEnabledProvider.overrideWithValue(false)],
    );
    addTearDown(disabledContainer.dispose);
    expect(disabledContainer.read(serverSettingsEnabledProvider), isFalse);
  });

  test('stored server URL loads only when settings are enabled', () async {
    const store = ServerSettingsStore(FlutterSecureStorage());
    await store.save(Uri.parse(savedApiUrl));

    expect(
      await store.load(Uri.parse(defaultApiUrl), enabled: true),
      Uri.parse(savedApiUrl),
    );
    expect(
      await store.load(Uri.parse(defaultApiUrl), enabled: false),
      Uri.parse(defaultApiUrl),
    );
  });

  test('active server URL persists and resets to compiled default', () async {
    final config = AppConfig.fromValues(
      appEnv: 'production',
      apiBaseUrl: defaultApiUrl,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        serverSettingsEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(activeApiBaseUrlProvider), Uri.parse(defaultApiUrl));
    await container
        .read(activeApiBaseUrlProvider.notifier)
        .set(Uri.parse(savedApiUrl));
    expect(container.read(activeApiBaseUrlProvider), Uri.parse(savedApiUrl));

    await container.read(activeApiBaseUrlProvider.notifier).resetToDefault();
    expect(container.read(activeApiBaseUrlProvider), Uri.parse(defaultApiUrl));
    expect(
      await const FlutterSecureStorage().read(
        key: ServerSettingsStore.storageKey,
      ),
      isNull,
    );
  });

  test('disabled server settings cannot change the active URL', () async {
    final config = AppConfig.fromValues(
      appEnv: 'production',
      apiBaseUrl: defaultApiUrl,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        serverSettingsEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(activeApiBaseUrlProvider.notifier)
          .set(Uri.parse(savedApiUrl)),
      throwsA(isA<StateError>()),
    );
    expect(container.read(activeApiBaseUrlProvider), Uri.parse(defaultApiUrl));
  });

  test('stored server URL rejects credentials and non-API paths', () async {
    const store = ServerSettingsStore(FlutterSecureStorage());
    for (final invalidUrl in [
      'http://user:pass@192.168.113.168:8000/api/v1/',
      'http://192.168.113.168:8000/other/',
    ]) {
      await const FlutterSecureStorage().write(
        key: ServerSettingsStore.storageKey,
        value: invalidUrl,
      );
      await expectLater(
        store.load(Uri.parse(defaultApiUrl), enabled: true),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('parses host, optional port, scheme, and trailing slash', () {
    expect(
      ServerAddress.parse(
        host: ' 192.168.113.168/// ',
        port: '8000',
        useHttps: false,
      ).apiBaseUrl,
      Uri.parse('http://192.168.113.168:8000/api/v1/'),
    );
    expect(
      ServerAddress.parse(
        host: 'api.example.test',
        port: '',
        useHttps: true,
      ).apiBaseUrl,
      Uri.parse('https://api.example.test/api/v1/'),
    );
  });

  test('rejects userinfo, paths, and an embedded port', () {
    for (final host in [
      'user:pass@example.test',
      'example.test/api',
      'example.test:8000',
    ]) {
      expect(
        () => ServerAddress.parse(host: host, port: '', useHttps: false),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('rejects ports outside the TCP port range', () {
    for (final port in ['0', '65536', '-1', 'abc']) {
      expect(
        () => ServerAddress.parse(
          host: 'example.test',
          port: port,
          useHttps: false,
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
