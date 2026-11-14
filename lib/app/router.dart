import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_state.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/presentation/authenticated_landing_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import 'startup_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(
    readAuthState: () => ref.read(authControllerProvider),
  );
  ref.listen(authControllerProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildRouter({
  String initialLocation = '/',
  required AuthState Function() readAuthState,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = readAuthState();
      final isPublicRoute = path == '/sign-in' || path == '/sign-up';

      switch (authState.status) {
        case AuthStatus.restoring:
          return path == '/' ? null : '/';
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
        path: '/home',
        builder: (context, state) => const AuthenticatedLandingScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
