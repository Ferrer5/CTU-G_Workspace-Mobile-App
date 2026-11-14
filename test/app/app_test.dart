import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ctug_mobile/app/app.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

void main() {
  testWidgets('opens the sign-in screen by default', (tester) async {
    final config = AppConfig.fromValues(
      appEnv: 'development',
      apiBaseUrl: 'https://example.invalid/api/v1/',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const CtugApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CTU-G WORKSPACE'), findsOneWidget);
    expect(find.byKey(const Key('schoolId')), findsOneWidget);
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
