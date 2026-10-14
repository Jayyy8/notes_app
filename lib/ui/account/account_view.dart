import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../state/core_providers.dart';
import '../../state/notes_controller.dart';
import 'sign_out.dart';

/// "Account" tab: who is signed in, a few stats, and Sign Out.
class AccountView extends ConsumerWidget {
  const AccountView({super.key, required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    final notes = ref.watch(notesControllerProvider.select((s) => s.notes));
    final pinned = notes.where((n) => n.isPinned).length;
    final initial = email.isEmpty ? '?' : email.substring(0, 1).toUpperCase();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPadding),
      children: <Widget>[
        Center(
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: kAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryLabel(context),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cardBackground(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: _Stat(value: '${notes.length}', label: 'Notes')),
              Expanded(child: _Stat(value: '$pinned', label: 'Pinned')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: AdaptiveButton(
            onPressed: () => confirmSignOut(context, ref),
            label: 'Sign Out',
            style: AdaptiveButtonStyle.tinted,
            size: AdaptiveButtonSize.large,
            color: CupertinoColors.systemRed,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: primaryLabel(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: secondaryLabel(context)),
        ),
      ],
    );
  }
}