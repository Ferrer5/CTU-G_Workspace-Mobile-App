import 'package:flutter/foundation.dart';

const startupServerSettingsTimeout = Duration(seconds: 3);

Future<Uri> loadStartupApiBaseUrl({
  required Uri defaultApiBaseUrl,
  required Future<Uri> Function() loadSavedApiBaseUrl,
  Duration timeout = startupServerSettingsTimeout,
}) async {
  try {
    return await loadSavedApiBaseUrl().timeout(timeout);
  } catch (_) {
    debugPrint('Secure storage unavailable; using the compiled API URL.');
    return defaultApiBaseUrl;
  }
}
