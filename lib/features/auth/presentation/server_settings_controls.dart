import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/server_settings.dart';

class ServerSettingsAction extends ConsumerWidget {
  const ServerSettingsAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(serverSettingsEnabledProvider)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: const Key('serverSettingsAction'),
      tooltip: 'Server settings',
      onPressed: () => context.go('/server-settings'),
      icon: const Icon(Icons.settings, color: Colors.white),
    );
  }
}

class ActiveServerLabel extends ConsumerWidget {
  const ActiveServerLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(serverSettingsEnabledProvider)) {
      return const SizedBox.shrink();
    }
    final address = displayServerAddress(ref.watch(activeApiBaseUrlProvider));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Server: $address',
        key: const Key('activeServerLabel'),
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
