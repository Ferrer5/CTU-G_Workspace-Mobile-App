import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class CtugApp extends StatelessWidget {
  const CtugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appLabel,
      theme: AppTheme.light,
      routerConfig: buildRouter(),
    );
  }
}
