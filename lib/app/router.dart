import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_state.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/presentation/authenticated_landing_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/server_settings_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/registration_verification_screen.dart';
import 'providers.dart';
import 'startup_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(
    readAuthState: () => ref.read(authControllerProvider),
    serverSettingsEnabled: ref.watch(serverSettingsEnabledProvider),
  );
  ref.listen(authControllerProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildRouter({
  String initialLocation = '/',
  required AuthState Function() readAuthState,
  bool serverSettingsEnabled = false,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = readAuthState();
      final isPublicRoute =
          path == '/sign-in' ||
          path == '/sign-up' ||
          path == '/sign-up/verify' ||
          path == '/forgot-password' ||
          (serverSettingsEnabled && path == '/server-settings');

      switch (authState.status) {
        case AuthStatus.restoring:
          return path == '/' ||
                  path == '/forgot-password' ||
                  (serverSettingsEnabled && path == '/server-settings')
              ? null
              : '/';
        case AuthStatus.authenticated:
          return path == '/home' ? null : '/home';
        case AuthStatus.unauthenticated:
          if (isPublicRoute) {
            return null;
          }
          return '/sign-in';
        case AuthStatus.error:
          if (authState.account != null) {
            return path == '/home' ? null : '/home';
          }
          if (path == '/' || isPublicRoute) {
            return null;
          }
          return '/';
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/sign-up/verify',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] == 'Instructor'
              ? 'Instructor'
              : 'Student';
          return RegistrationVerificationScreen(
            role: role,
            resumed: state.uri.queryParameters['resumed'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      if (serverSettingsEnabled)
        GoRoute(
          path: '/server-settings',
          builder: (context, state) => const ServerSettingsScreen(),
        ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AuthenticatedLandingScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
