import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ctug_mobile/app/app.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/app/server_settings.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final activeApiBaseUrl = await const ServerSettingsStore(
    FlutterSecureStorage(),
  ).load(config.apiBaseUrl, enabled: kDebugMode);
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        initialActiveApiBaseUrlProvider.overrideWithValue(activeApiBaseUrl),
      ],
      child: const CtugApp(),
    ),
  );
}
