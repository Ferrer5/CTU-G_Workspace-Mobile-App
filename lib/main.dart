import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ctug_mobile/app/app.dart';
import 'package:ctug_mobile/app/providers.dart';
import 'package:ctug_mobile/core/config/app_config.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const CtugApp(),
    ),
  );
}
