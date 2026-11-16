import 'dart:async';

import 'package:ctug_mobile/app/app.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/app/startup.dart';
import 'package:ctug_mobile/app/startup_error.dart';
import 'package:ctug_mobile/core/config/app_config.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_auth_repository.dart';

final _defaultApiBaseUrl = Uri.parse('https://api.example.test/api/v1/');

Future<void> _pumpAppWithDefaultUrl(WidgetTester tester, Uri apiBaseUrl) async {
  final config = AppConfig.fromValues(
    appEnv: 'development',
    apiBaseUrl: apiBaseUrl.toString(),
  );
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      authRepositoryProvider.overrideWithValue(TestAuthRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CtugApp()),
  );
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('schoolId')), findsOneWidget);
  expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
}

void main() {
  testWidgets('a throwing saved URL read still starts with the default URL', (
    tester,
  ) async {
    final apiBaseUrl = await loadStartupApiBaseUrl(
      defaultApiBaseUrl: _defaultApiBaseUrl,
      loadSavedApiBaseUrl: () async {
        throw StateError('sensitive storage error');
      },
    );

    expect(apiBaseUrl, _defaultApiBaseUrl);
    await _pumpAppWithDefaultUrl(tester, apiBaseUrl);
  });

  testWidgets('a stalled saved URL read still starts with the default URL', (
    tester,
  ) async {
    final stalledRead = Completer<Uri>();
    final loading = loadStartupApiBaseUrl(
      defaultApiBaseUrl: _defaultApiBaseUrl,
      loadSavedApiBaseUrl: () => stalledRead.future,
      timeout: const Duration(seconds: 3),
    );

    await tester.pump(const Duration(seconds: 4));
    final apiBaseUrl = await loading;

    expect(apiBaseUrl, _defaultApiBaseUrl);
    await _pumpAppWithDefaultUrl(tester, apiBaseUrl);
  });

  testWidgets('the global error boundary displays its fallback screen', (
    tester,
  ) async {
    final errorState = StartupErrorState();
    await tester.pumpWidget(
      StartupErrorBoundary(
        errorState: errorState,
        child: const MaterialApp(home: Text('Application content')),
      ),
    );

    errorState.report();
    await tester.pump();

    expect(find.text('Unable to start the app'), findsOneWidget);
    expect(find.text('Application content'), findsNothing);
  });
}
