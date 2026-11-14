import 'package:flutter/material.dart';

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('authFeedback'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, height: 1.4),
        ),
      ),
    );
  }
}
