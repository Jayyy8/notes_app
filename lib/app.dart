import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

import 'core/app_colors.dart';
import 'ui/auth/auth_gate.dart';

/// Root widget.
///
/// [AdaptiveApp] builds a CupertinoApp on iOS and a MaterialApp on Android,
/// so we never touch material.dart ourselves.
class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveApp(
      title: 'Notes',
      cupertinoLightTheme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: kAccent,
      ),
      cupertinoDarkTheme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: kAccent,
      ),
      home: AuthGate(),
    );
  }
}