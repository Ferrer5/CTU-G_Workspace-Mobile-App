import 'package:flutter/material.dart';

class RegistrationSchoolInformation extends StatelessWidget {
  const RegistrationSchoolInformation({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    if (role == 'Instructor') return const SizedBox.shrink();

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 25),
          const Padding(
            padding: EdgeInsets.only(bottom: 13),
            child: Text(
              '03 — School Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(129, 213, 155, 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your academic details will be configured later as part of '
                  'your academic profile. These details are not collected '
                  'during registration.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final label in ['Course', 'Year Level', 'Section']) ...[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'Configured later',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (label != 'Section') const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
