import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/app/router.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

void main() {
  late AppConfig config;

  setUp(() {
    config = AppConfig.fromValues(
      appEnv: 'test',
      apiBaseUrl: 'https://example.invalid/api/v1/',
    );
  });

  testWidgets('renders the startup screen at /', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: MaterialApp.router(
          routerConfig: buildRouter(initialLocation: '/'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CTU-G'), findsOneWidget);
    expect(find.text('test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Page not found for an unknown route', (tester) async {
    final router = buildRouter(initialLocation: '/nope');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });
}
