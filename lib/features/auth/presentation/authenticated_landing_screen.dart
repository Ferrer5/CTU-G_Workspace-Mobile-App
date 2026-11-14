import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_state.dart';
import '../auth_providers.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';

class AuthenticatedLandingScreen extends ConsumerStatefulWidget {
  const AuthenticatedLandingScreen({super.key});

  @override
  ConsumerState<AuthenticatedLandingScreen> createState() =>
      _AuthenticatedLandingScreenState();
}

class _AuthenticatedLandingScreenState
    extends ConsumerState<AuthenticatedLandingScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }
    setState(() => _isLoggingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final account = authState.account;
    final logoutFailure =
        authState.status == AuthStatus.error && account != null;

    return AuthScreenBackground(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: account == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthScreenHeader(
                        title: 'Your Workspace',
                        subtitle: 'More features are coming soon.',
                        showRequiredNote: false,
                      ),
                      const SizedBox(height: 27),
                      const Text(
                        'School ID',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        account.schoolId,
                        key: const Key('accountSchoolId'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Roles',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      for (final (index, role) in account.roles.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            role,
                            key: ValueKey('accountRole-$index'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      if (logoutFailure) ...[
                        const SizedBox(height: 16),
                        const AuthFeedback(
                          message: 'We couldn’t log you out. You are still signed in. Please try again.',
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        key: const Key('logoutButton'),
                        onPressed: _isLoggingOut
                            ? null
                            : () => unawaited(_logout()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF197747),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(51),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: _isLoggingOut
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Log out'),
                      ),
                      if (logoutFailure) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('retryLogout'),
                          onPressed: _isLoggingOut
                              ? null
                              : () => unawaited(_logout()),
                          child: const Text(
                            'Retry logout',
                            style: TextStyle(color: Color(0xFF9BE2AA)),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
