import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/body_inset.dart';
import '../../core/date_format.dart';
import '../../state/core_providers.dart';
import '../../state/notes_controller.dart';
import 'sign_out.dart';

/// "Account" tab: who is signed in, a few stats, and Sign Out.
class AccountView extends ConsumerWidget {
  const AccountView({super.key, required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authRepositoryProvider).currentUser;
    final email = user?.email ?? '';
    final memberSince = DateTime.tryParse(user?.createdAt ?? '')?.toLocal();

    final notes = ref.watch(notesControllerProvider.select((s) => s.notes));
    final pinned = notes.where((n) => n.isPinned).length;
    final initial = email.isEmpty ? '?' : email.substring(0, 1).toUpperCase();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        24 + bodyTopInset(context),
        16,
        bottomPadding,
      ),
      children: <Widget>[
        Center(
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 38,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryLabel(context),
          ),
        ),
        const SizedBox(height: 28),
        _Group(
          children: <Widget>[
            _InfoRow(
              icon: CupertinoIcons.doc_text,
              label: 'Notes',
              value: '${notes.length}',
            ),
            _InfoRow(
              icon: CupertinoIcons.pin,
              label: 'Pinned',
              value: '$pinned',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Group(
          children: <Widget>[
            _InfoRow(icon: CupertinoIcons.mail, label: 'Email', value: email),
            if (memberSince != null)
              _InfoRow(
                icon: CupertinoIcons.calendar,
                label: 'Member since',
                value: formatFullDate(memberSince),
              ),
          ],
        ),
        const SizedBox(height: 28),
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

/// Rounded card that stacks rows with hairline separators.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 48),
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: kAccent),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 16, color: primaryLabel(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: secondaryLabel(context)),
            ),
          ),
        ],
      ),
    );
  }
}