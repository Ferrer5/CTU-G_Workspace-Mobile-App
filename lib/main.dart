import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/server_settings.dart';
import 'app/startup.dart';
import 'app/startup_error.dart';
import 'core/config/app_config.dart';

void main() {
  final startupErrorState = StartupErrorState();
  var appStarted = false;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        if (kDebugMode) {
          debugPrint(
            'Flutter error: ${details.exception.runtimeType}: ${details.exception}',
          );
          debugPrintStack(stackTrace: details.stack);
        }
        startupErrorState.report();
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          debugPrint('Platform error: ${error.runtimeType}: $error');
          debugPrintStack(stackTrace: stack);
        }
        startupErrorState.report();
        return true;
      };

      final config = AppConfig.fromEnvironment();
      final activeApiBaseUrl = await loadStartupApiBaseUrl(
        defaultApiBaseUrl: config.apiBaseUrl,
        loadSavedApiBaseUrl: () =>
            const ServerSettingsStore(FlutterSecureStorage())
                .load(config.apiBaseUrl, enabled: kDebugMode),
      );
      runApp(
        StartupErrorBoundary(
          errorState: startupErrorState,
          child: ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(config),
              initialActiveApiBaseUrlProvider.overrideWithValue(
                activeApiBaseUrl,
              ),
            ],
            child: const CtugApp(),
          ),
        ),
      );
      appStarted = true;
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught zone error: ${error.runtimeType}: $error');
        debugPrintStack(stackTrace: stack);
      }
      startupErrorState.report();
      if (!appStarted) {
        runApp(const StartupFallbackApp());
        appStarted = true;
      }
    },
  );
}
