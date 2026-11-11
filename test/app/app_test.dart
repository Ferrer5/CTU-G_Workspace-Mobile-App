import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ctug_mobile/app/app.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

void main() {
  testWidgets('shows the initialized startup screen', (tester) async {
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

    expect(find.text('CTU-G'), findsOneWidget);
    expect(find.text('App initialized'), findsOneWidget);
    expect(find.text('development'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
