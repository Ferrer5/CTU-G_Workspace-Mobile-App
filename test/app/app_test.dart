import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctug_mobile/app/app.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

import 'test_auth_repository.dart';

void main() {
  testWidgets('restores an unauthenticated launch to the sign-in screen', (
    tester,
  ) async {
    final config = AppConfig.fromValues(
      appEnv: 'development',
      apiBaseUrl: 'https://example.invalid/api/v1/',
    );
    final repository = TestAuthRepository();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CtugApp()),
    );
    await tester.pumpAndSettle();

    expect(repository.restoreCalls, 1);
    expect(find.byKey(const Key('schoolId')), findsOneWidget);
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
