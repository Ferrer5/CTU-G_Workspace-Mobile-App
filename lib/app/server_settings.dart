import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../features/auth/data/auth_api_client.dart';
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

class ServerAddress {
  const ServerAddress(this.apiBaseUrl);

  final Uri apiBaseUrl;

  static ServerAddress parse({
    required String host,
    required String port,
    required bool useHttps,
  }) {
    var normalizedHost = host.trim();
    while (normalizedHost.endsWith('/')) {
      normalizedHost = normalizedHost.substring(0, normalizedHost.length - 1);
    }
    if (normalizedHost.isEmpty ||
        normalizedHost.contains('/') ||
        normalizedHost.contains('@') ||
        normalizedHost.contains('?') ||
        normalizedHost.contains('#')) {
      throw const FormatException('Enter a host name or IP address only.');
    }

    final parsedHost = Uri.tryParse('http://$normalizedHost');
    if (parsedHost == null ||
        parsedHost.host.isEmpty ||
        parsedHost.userInfo.isNotEmpty ||
        parsedHost.path.isNotEmpty ||
        parsedHost.hasQuery ||
        parsedHost.hasFragment ||
        parsedHost.hasPort) {
      throw const FormatException(
        'Enter a host only; use the Port field for a port number.',
      );
    }

    final normalizedPort = port.trim();
    int? portNumber;
    if (normalizedPort.isNotEmpty) {
      if (!RegExp(r'^\d+$').hasMatch(normalizedPort)) {
        throw const FormatException('Port must be a number from 1 to 65535.');
      }
      portNumber = int.tryParse(normalizedPort);
      if (portNumber == null || portNumber < 1 || portNumber > 65535) {
        throw const FormatException('Port must be a number from 1 to 65535.');
      }
    }

    return ServerAddress(
      Uri(
        scheme: useHttps ? 'https' : 'http',
        host: parsedHost.host,
        port: portNumber,
        path: '/api/v1/',
      ),
    );
  }
}

final serverSettingsStoreProvider = Provider<ServerSettingsStore>(
  (ref) => ServerSettingsStore(const FlutterSecureStorage()),
);

typedef ServerConnectionTester = Future<void> Function(Uri apiBaseUrl);

final serverConnectionTesterProvider = Provider<ServerConnectionTester>(
  (ref) => (apiBaseUrl) async {
    final client = createAuthApiClient(
      baseUrl: apiBaseUrl,
      cookieJar: CookieJar(),
    );
    try {
      await client.testConnection();
    } finally {
      client.close();
    }
  },
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

String displayServerAddress(Uri apiBaseUrl) {
  final host = apiBaseUrl.host.contains(':')
      ? '[${apiBaseUrl.host}]'
      : apiBaseUrl.host;
  final port = apiBaseUrl.hasPort
      ? apiBaseUrl.port
      : apiBaseUrl.scheme == 'https'
      ? 443
      : 80;
  return '$host:$port';
}
