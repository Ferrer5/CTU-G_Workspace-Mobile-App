import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_state.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/presentation/auth_screen_background.dart';
import '../features/auth/presentation/auth_screen_header.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(authControllerProvider.notifier).restoreSession());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restoring =
        ref.watch(authControllerProvider).status == AuthStatus.restoring;

    return AuthScreenBackground(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthScreenHeader(
                  title: restoring
                      ? 'Checking your session'
                      : 'We couldn’t verify your session',
                  subtitle: restoring
                      ? 'Please wait while we securely restore your account.'
                      : 'Check your connection, then try again.',
                  showRequiredNote: false,
                ),
                const SizedBox(height: 27),
                if (restoring)
                  const Center(
                    child: CircularProgressIndicator(
                      key: Key('startupLoading'),
                      color: Colors.white,
                    ),
                  )
                else
                  ElevatedButton(
                    key: const Key('retrySessionRestore'),
                    onPressed: () => unawaited(
                      ref
                          .read(authControllerProvider.notifier)
                          .restoreSession(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF197747),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(51),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
