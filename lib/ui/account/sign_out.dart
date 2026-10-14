import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/core_providers.dart';

/// Asks for confirmation, then signs out. AuthGate reacts to the session
/// change and shows the sign-in page.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authRepositoryProvider);
  return AdaptiveAlertDialog.show(
    context: context,
    title: 'Sign out?',
    message: 'Your notes stay safe in the cloud and will be here when you '
        'sign back in.',
    actions: <AlertAction>[
      AlertAction(
        title: 'Cancel',
        style: AlertActionStyle.cancel,
        onPressed: () {},
      ),
      AlertAction(
        title: 'Sign Out',
        style: AlertActionStyle.destructive,
        onPressed: () => unawaited(auth.signOut()),
      ),
    ],
  );
}