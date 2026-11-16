import 'package:flutter/material.dart';

class StartupErrorState extends ValueNotifier<bool> {
  StartupErrorState() : super(false);

  void report() {
    if (value) {
      return;
    }
    debugPrint('An app error occurred; showing the recovery screen.');
    value = true;
  }
}

class StartupErrorBoundary extends StatelessWidget {
  const StartupErrorBoundary({
    required this.errorState,
    required this.child,
    super.key,
  });

  final StartupErrorState errorState;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: errorState,
    builder: (context, failed, _) =>
        failed ? const StartupFallbackApp() : child,
  );
}

class StartupFallbackApp extends StatelessWidget {
  const StartupFallbackApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to start the app',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please close and reopen the app. If the problem continues, contact support.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
