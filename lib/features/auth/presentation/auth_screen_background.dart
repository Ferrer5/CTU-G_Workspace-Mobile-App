import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AuthScreenBackground extends StatelessWidget {
  const AuthScreenBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Image.asset(
                'assets/images/campus-building-background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Positioned.fill(
            child: ColoredBox(color: Color.fromRGBO(3, 14, 11, 0.68)),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
