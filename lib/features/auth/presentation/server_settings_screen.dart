import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/server_settings.dart';
import '../auth_providers.dart';
import '../data/auth_failure.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';
import 'auth_text_field.dart';

class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() =>
      _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  late bool _useHttps;
  bool _isWorking = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    final activeUrl = ref.read(activeApiBaseUrlProvider);
    _hostController.text = activeUrl.host.contains(':')
        ? '[${activeUrl.host}]'
        : activeUrl.host;
    _portController.text = activeUrl.hasPort ? activeUrl.port.toString() : '';
    _useHttps = activeUrl.scheme == 'https';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  ServerAddress? _currentAddress() {
    try {
      return ServerAddress.parse(
        host: _hostController.text,
        port: _portController.text,
        useHttps: _useHttps,
      );
    } on FormatException {
      return null;
    }
  }

  String? _validateHost(String? value) {
    try {
      ServerAddress.parse(host: value ?? '', port: '', useHttps: _useHttps);
      return null;
    } on FormatException catch (error) {
      return error.message.toString();
    }
  }

  String? _validatePort(String? value) {
    final port = value?.trim() ?? '';
    if (port.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+$').hasMatch(port)) {
      return 'Port must be a number from 1 to 65535.';
    }
    final parsed = int.tryParse(port);
    if (parsed == null || parsed < 1 || parsed > 65535) {
      return 'Port must be a number from 1 to 65535.';
    }
    return null;
  }

  String _connectionFailureMessage(AuthFailure failure) {
    if (failure is RequestTimeoutFailure) {
      return 'Connection timed out. Check the server and try again.';
    }
    if (failure is NetworkUnavailableFailure) {
      return 'Could not reach this server. Check the host, port, and server availability.';
    }
    if (failure is NonJsonResponseFailure) {
      return 'The server returned HTML or another non-JSON response.';
    }
    if (failure is BackendAuthFailure) {
      if (failure.statusCode >= 500) {
        return 'The server encountered an error during the connection test.';
      }
      return 'The server returned an unexpected status. Check the API address.';
    }
    if (failure is MalformedJsonResponseFailure ||
        failure is InvalidApiResponseFailure) {
      return 'The server returned an unexpected response or status.';
    }
    return 'The connection test could not be completed. Please try again.';
  }

  Future<void> _testConnection() async {
    if (_isWorking || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final address = _currentAddress();
    if (address == null) {
      return;
    }
    setState(() {
      _isWorking = true;
      _feedback = null;
    });

    try {
      await ref.read(serverConnectionTesterProvider)(address.apiBaseUrl);
      if (mounted) {
        setState(() => _feedback = 'Connection successful.');
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _feedback = _connectionFailureMessage(failure));
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _activateServer(Uri apiBaseUrl, {required bool reset}) async {
    final activeApiBaseUrl = ref.read(activeApiBaseUrlProvider);
    if (apiBaseUrl != activeApiBaseUrl) {
      final oldClient = ref.read(authApiClientProvider);
      oldClient.cancelInFlightRequests();
      await oldClient.clearCookies();
      ref.read(authControllerProvider.notifier).resetForServerChange();
    }

    if (reset) {
      await ref.read(activeApiBaseUrlProvider.notifier).resetToDefault();
    } else {
      await ref.read(activeApiBaseUrlProvider.notifier).set(apiBaseUrl);
    }
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _save() async {
    if (_isWorking || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final address = _currentAddress();
    if (address == null) {
      return;
    }
    setState(() {
      _isWorking = true;
      _feedback = null;
    });
    try {
      await _activateServer(address.apiBaseUrl, reset: false);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _feedback = 'Could not save server settings. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _resetToDefault() async {
    if (_isWorking) {
      return;
    }
    final defaultUrl = ref.read(appConfigProvider).apiBaseUrl;
    setState(() {
      _isWorking = true;
      _feedback = null;
    });
    try {
      await _activateServer(defaultUrl, reset: true);
    } on PlatformException {
      if (mounted) {
        setState(
          () =>
              _feedback = 'Could not reset server settings. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = _currentAddress();
    return AuthScreenBackground(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthScreenHeader(
                    title: 'Server settings',
                    subtitle: 'Choose the server for this debug build.',
                    showRequiredNote: false,
                  ),
                  const SizedBox(height: 27),
                  AuthTextField(
                    fieldKey: const Key('serverHost'),
                    label: 'Host (IP address or name)',
                    controller: _hostController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    maxLength: 255,
                    validator: _validateHost,
                    onChanged: (_) => setState(() => _feedback = null),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    fieldKey: const Key('serverPort'),
                    label: 'Port',
                    requiredField: false,
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 5,
                    validator: _validatePort,
                    onChanged: (_) => setState(() => _feedback = null),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('useHttpsSwitch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Use HTTPS',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _useHttps,
                    onChanged: _isWorking
                        ? null
                        : (value) => setState(() {
                            _useHttps = value;
                            _feedback = null;
                          }),
                    activeThumbColor: const Color(0xFF81D59B),
                  ),
                  if (!_useHttps)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Passwords are sent unencrypted. Use only on a network you trust.',
                        key: Key('httpWarning'),
                        style: TextStyle(
                          color: Color(0xFFFFCC80),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Text(
                    address?.apiBaseUrl.toString() ?? 'Enter a valid host and port to preview the API address.',
                    key: const Key('serverUrlPreview'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 17),
                    AuthFeedback(message: _feedback!),
                  ],
                  const SizedBox(height: 22),
                  OutlinedButton(
                    key: const Key('testServerConnection'),
                    onPressed: _isWorking ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: _isWorking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Test connection'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('saveServerSettings'),
                    onPressed: _isWorking ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF197747),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(51),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const Key('resetServerSettings'),
                    onPressed: _isWorking ? null : _resetToDefault,
                    child: const Text(
                      'Reset to default',
                      style: TextStyle(color: Color(0xFF9BE2AA)),
                    ),
                  ),
                  TextButton(
                    key: const Key('cancelServerSettings'),
                    onPressed: _isWorking ? null : () => context.go('/sign-in'),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
