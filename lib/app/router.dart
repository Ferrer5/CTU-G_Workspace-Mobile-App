import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'startup_screen.dart';

GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
