import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/app/router.dart';
import 'package:ctug_mobile/app/server_settings.dart';
import 'package:ctug_mobile/core/config/app_config.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:ctug_mobile/features/auth/data/auth_api_client.dart';
import 'package:ctug_mobile/features/auth/data/auth_failure.dart';
import 'package:ctug_mobile/features/auth/domain/authenticated_account.dart';
import 'package:ctug_mobile/features/auth/presentation/server_settings_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../app/test_auth_repository.dart';

class _TrackingAuthApiClient extends AuthApiClient {
  _TrackingAuthApiClient(this.jar) : super(dio: Dio(), cookieJar: jar);

  final CookieJar jar;
  bool cancelled = false;

  @override
  void cancelInFlightRequests() {
    cancelled = true;
    super.cancelInFlightRequests();
  }
}

Widget _standaloneScreen({
  required ServerConnectionTester tester,
  Uri? initialUrl,
}) {
  final config = AppConfig.fromValues(
    appEnv: 'development',
    apiBaseUrl: 'http://127.0.0.1:8000/api/v1/',
  );
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      if (initialUrl != null)
        initialActiveApiBaseUrlProvider.overrideWithValue(initialUrl),
      serverSettingsEnabledProvider.overrideWithValue(true),
      serverConnectionTesterProvider.overrideWithValue(tester),
      authRepositoryProvider.overrideWithValue(TestAuthRepository()),
    ],
    child: const MaterialApp(home: ServerSettingsScreen()),
  );
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('renders host, optional port, URL preview, and HTTP warning', (
    tester,
  ) async {
    await tester.pumpWidget(_standaloneScreen(tester: (_) async {}));

    expect(find.text('Server settings'), findsOneWidget);
    expect(
      find.text(
        'Passwords are sent unencrypted. Use only on a network you trust.',
      ),
      findsOneWidget,
    );
    expect(find.text('http://127.0.0.1:8000/api/v1/'), findsOneWidget);

    await _enter(tester, 'serverHost', 'api.example.test///');
    await _enter(tester, 'serverPort', '8443');
    await tester.pump();
    expect(find.text('http://api.example.test:8443/api/v1/'), findsOneWidget);

    await tester.tap(find.byKey(const Key('useHttpsSwitch')));
    await tester.pump();
    expect(find.text('https://api.example.test:8443/api/v1/'), findsOneWidget);
    expect(find.byKey(const Key('httpWarning')), findsNothing);
  });

  testWidgets('rejects userinfo, paths, and invalid ports before testing', (
    tester,
  ) async {
    var testCalls = 0;
    await tester.pumpWidget(
      _standaloneScreen(tester: (_) async => testCalls++),
    );
    await _enter(tester, 'serverHost', 'user:pass@example.test');
    await tester.tap(find.byKey(const Key('testServerConnection')));
    await tester.pumpAndSettle();

    expect(testCalls, 0);
    expect(find.text('Enter a host name or IP address only.'), findsOneWidget);

    await _enter(tester, 'serverHost', 'example.test/path');
    await _enter(tester, 'serverPort', '65536');
    await tester.tap(find.byKey(const Key('testServerConnection')));
    await tester.pumpAndSettle();
    expect(testCalls, 0);
    expect(find.text('Port must be a number from 1 to 65535.'), findsOneWidget);
  });

  testWidgets('test connection shows success and safe failure messages', (
    tester,
  ) async {
    var shouldFail = false;
    Uri? testedUrl;
    await tester.pumpWidget(
      _standaloneScreen(
        tester: (url) async {
          testedUrl = url;
          if (shouldFail) {
            throw const NonJsonResponseFailure();
          }
        },
      ),
    );

    await tester.tap(find.byKey(const Key('testServerConnection')));
    await tester.pumpAndSettle();
    expect(find.text('Connection successful.'), findsOneWidget);
    expect(testedUrl, Uri.parse('http://127.0.0.1:8000/api/v1/'));

    shouldFail = true;
    await tester.ensureVisible(find.byKey(const Key('testServerConnection')));
    await tester.tap(find.byKey(const Key('testServerConnection')));
    await tester.pumpAndSettle();
    expect(
      find.text('The server returned HTML or another non-JSON response.'),
      findsOneWidget,
    );
  });

  testWidgets('saving a changed server clears auth state and old cookies', (
    tester,
  ) async {
    const oldUrl = 'http://127.0.0.1:8000/api/v1/';
    const nextUrl = 'http://192.168.113.168:8000/api/v1/';
    final oldUri = Uri.parse(oldUrl);
    final jar = CookieJar();
    await jar.saveFromResponse(oldUri, [
      Cookie('sessionid', 'old-session')..path = '/',
      Cookie('csrftoken', 'old-csrf')..path = '/',
    ]);
    final client = _TrackingAuthApiClient(jar);
    final loginPending = Completer<AuthenticatedAccount>();
    final repository = TestAuthRepository(
      loginHandler: ({required schoolId, required password}) =>
          loginPending.future,
      restoreHandler: () async => null,
    );
    final config = AppConfig.fromValues(
      appEnv: 'development',
      apiBaseUrl: 'https://default.example.test/api/v1/',
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        initialActiveApiBaseUrlProvider.overrideWithValue(oldUri),
        serverSettingsEnabledProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(repository),
        authApiClientProvider.overrideWithValue(client),
        serverConnectionTesterProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final pendingLogin = container
        .read(authControllerProvider.notifier)
        .login(schoolId: 'stale', password: 'pending');
    router.go('/server-settings');
    await tester.pumpAndSettle();

    await _enter(tester, 'serverHost', '192.168.113.168');
    await _enter(tester, 'serverPort', '8000');
    await tester.tap(find.byKey(const Key('saveServerSettings')));
    await tester.pumpAndSettle();

    expect(client.cancelled, isTrue);
    expect(await jar.loadForRequest(oldUri), isEmpty);
    expect(container.read(activeApiBaseUrlProvider), Uri.parse(nextUrl));
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(repository.restoreCalls, 2);

    loginPending.complete(TestAuthRepository.account);
    await pendingLogin;
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  testWidgets('reset to default restores the compiled URL', (tester) async {
    const savedUrl = 'http://192.168.113.168:8000/api/v1/';
    const defaultUrl = 'https://default.example.test/api/v1/';
    final config = AppConfig.fromValues(
      appEnv: 'development',
      apiBaseUrl: defaultUrl,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        initialActiveApiBaseUrlProvider.overrideWithValue(Uri.parse(savedUrl)),
        serverSettingsEnabledProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        serverConnectionTesterProvider.overrideWithValue((_) async {}),
      ],
    );
    await container
        .read(activeApiBaseUrlProvider.notifier)
        .set(Uri.parse(savedUrl));
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/server-settings');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('resetServerSettings')));
    await tester.tap(find.byKey(const Key('resetServerSettings')));
    await tester.pumpAndSettle();

    expect(container.read(activeApiBaseUrlProvider), Uri.parse(defaultUrl));
    expect(
      await const FlutterSecureStorage().read(
        key: ServerSettingsStore.storageKey,
      ),
      isNull,
    );
  });
}
