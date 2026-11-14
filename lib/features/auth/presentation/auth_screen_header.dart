import 'package:flutter/material.dart';

class AuthScreenHeader extends StatelessWidget {
  const AuthScreenHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              key: const Key('authBrandLogo'),
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/ctug-logo.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'CTU-G WORKSPACE',
              style: TextStyle(
                color: Color(0xFF9BE2AA),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '* Fields marked are required.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
