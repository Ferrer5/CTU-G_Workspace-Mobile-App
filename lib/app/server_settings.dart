import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'providers.dart';

class ServerSettingsStore {
  const ServerSettingsStore(this._storage);

  static const storageKey = 'ctug.server.api_base_url';

  final FlutterSecureStorage _storage;

  Future<Uri> load(Uri defaultApiBaseUrl, {required bool enabled}) async {
    if (!enabled) {
      return defaultApiBaseUrl;
    }

    final savedUrl = await _storage.read(key: storageKey);
    if (savedUrl == null) {
      return defaultApiBaseUrl;
    }
    return _parseApiBaseUrl(savedUrl);
  }

  Future<void> save(Uri apiBaseUrl) =>
      _storage.write(key: storageKey, value: apiBaseUrl.toString());

  Future<void> reset() => _storage.delete(key: storageKey);
}

final serverSettingsStoreProvider = Provider<ServerSettingsStore>(
  (ref) => ServerSettingsStore(const FlutterSecureStorage()),
);

final initialActiveApiBaseUrlProvider = Provider<Uri>(
  (ref) => ref.watch(appConfigProvider).apiBaseUrl,
);

final activeApiBaseUrlProvider =
    NotifierProvider<ActiveApiBaseUrlController, Uri>(
      ActiveApiBaseUrlController.new,
    );

class ActiveApiBaseUrlController extends Notifier<Uri> {
  @override
  Uri build() => ref.watch(initialActiveApiBaseUrlProvider);

  Future<void> set(Uri apiBaseUrl) async {
    if (!ref.read(serverSettingsEnabledProvider)) {
      throw StateError('Server settings are disabled in this build.');
    }
    final normalizedUrl = _parseApiBaseUrl(apiBaseUrl.toString());
    await ref.read(serverSettingsStoreProvider).save(normalizedUrl);
    state = normalizedUrl;
  }

  Future<void> resetToDefault() async {
    if (!ref.read(serverSettingsEnabledProvider)) {
      throw StateError('Server settings are disabled in this build.');
    }
    await ref.read(serverSettingsStoreProvider).reset();
    state = ref.read(appConfigProvider).apiBaseUrl;
  }
}

Uri _parseApiBaseUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.isAbsolute ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.authority.contains('@') ||
      uri.path != '/api/v1/' ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException('Invalid API base URL in server settings.');
  }
  return uri;
}
