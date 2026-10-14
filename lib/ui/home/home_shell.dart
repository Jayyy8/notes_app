import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/adaptive_icons.dart';
import '../../core/app_colors.dart';
import '../../state/notes_controller.dart';
import '../../state/notes_state.dart';
import '../account/account_view.dart';
import '../account/sign_out.dart';
import '../notes/note_actions.dart';
import '../notes/notes_list_view.dart';

enum _MenuId { sortEdited, sortCreated, sortTitle, refresh, signOut }

class _MenuEntry {
  const _MenuEntry(
      this.id,
      this.label, {
        this.icon,
        this.selected = false,
        this.destructive = false,
      });

  final _MenuId id;
  final String label;
  final dynamic icon;
  final bool selected;
  final bool destructive;
}

/// Signed-in shell: adaptive app bar (with action menu) + adaptive bottom bar.
///
/// * iOS 26+      -> native Liquid Glass toolbar and tab bar
/// * iOS 18       -> CupertinoNavigationBar and CupertinoTabBar
/// * Android      -> Material AppBar and NavigationBar
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  /// On iOS 26 the body slides under the floating tab bar, so lists need extra
  /// bottom space to keep the last note reachable.
  double get _bottomPadding => PlatformInfo.isIOS26OrHigher() ? 110 : 24;

  @override
  Widget build(BuildContext context) {
    // Every failed request (save, pin, delete, refresh...) reports through here.
    ref.listen<String?>(notesControllerProvider.select((s) => s.message), (
        previous,
        next,
        ) {
      if (next == null) return;
      AdaptiveSnackBar.show(
        context,
        message: next,
        type: AdaptiveSnackBarType.error,
      );
      ref.read(notesControllerProvider.notifier).clearMessage();
    });

    final sort = ref.watch(notesControllerProvider.select((s) => s.sort));
    final pinnedCount = ref.watch(
      notesControllerProvider.select(
            (s) => s.notes.where((n) => n.isPinned).length,
      ),
    );

    return AdaptiveScaffold(
      backgroundColor: groupedBackground(context),
      appBar: _buildAppBar(sort),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _index,
        onTap: (index) => setState(() => _index = index),
        selectedItemColor: kAccent,
        items: <AdaptiveNavigationDestination>[
          AdaptiveNavigationDestination(
            icon: adaptiveIcon('note.text', CupertinoIcons.doc_text),
            selectedIcon:
            adaptiveIcon('note.text', CupertinoIcons.doc_text_fill),
            label: 'Notes',
          ),
          AdaptiveNavigationDestination(
            icon: adaptiveIcon('pin', CupertinoIcons.pin),
            selectedIcon: adaptiveIcon('pin.fill', CupertinoIcons.pin_fill),
            label: 'Pinned',
            badgeCount: pinnedCount > 0 ? pinnedCount : null,
          ),
          AdaptiveNavigationDestination(
            icon: adaptiveIcon(
              'person.crop.circle',
              CupertinoIcons.person_crop_circle,
            ),
            selectedIcon: adaptiveIcon(
              'person.crop.circle.fill',
              CupertinoIcons.person_crop_circle_fill,
            ),
            label: 'Account',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_index) {
      case 0:
        return NotesListView(
          key: const ValueKey<String>('notes'),
          pinnedOnly: false,
          bottomPadding: _bottomPadding,
        );
      case 1:
        return NotesListView(
          key: const ValueKey<String>('pinned'),
          pinnedOnly: true,
          bottomPadding: _bottomPadding,
        );
      default:
        return AccountView(bottomPadding: _bottomPadding);
    }
  }

  AdaptiveAppBar _buildAppBar(NoteSort sort) {
    switch (_index) {
      case 0:
        return AdaptiveAppBar(
          title: 'Notes',
          tintColor: kAccent,
          actions: <AdaptiveAppBarAction>[
            _buildNewNoteAction(),
            _buildMoreAction(sort),
          ],
        );
      case 1:
        return AdaptiveAppBar(
          title: 'Pinned',
          tintColor: kAccent,
          actions: <AdaptiveAppBarAction>[_buildNewNoteAction()],
        );
      default:
        return const AdaptiveAppBar(title: 'Account', tintColor: kAccent);
    }
  }

  AdaptiveAppBarAction _buildNewNoteAction() {
    return AdaptiveAppBarAction(
      iosSymbol: 'plus',
      icon: CupertinoIcons.plus,
      label: 'New Note',
      onPressed: () => openNoteEditor(context, ref),
    );
  }

  /// The "..." action menu in the app bar.
  AdaptiveAppBarAction _buildMoreAction(NoteSort sort) {
    // null = divider. The list index is what onMenuItemSelected reports.
    final entries = <_MenuEntry?>[
      _MenuEntry(
        _MenuId.sortEdited,
        'Sort by Date Edited',
        selected: sort == NoteSort.updated,
      ),
      _MenuEntry(
        _MenuId.sortCreated,
        'Sort by Date Created',
        selected: sort == NoteSort.created,
      ),
      _MenuEntry(
        _MenuId.sortTitle,
        'Sort by Title',
        selected: sort == NoteSort.title,
      ),
      null,
      _MenuEntry(
        _MenuId.refresh,
        'Refresh',
        icon: adaptiveIcon('arrow.clockwise', CupertinoIcons.arrow_clockwise),
      ),
      _MenuEntry(
        _MenuId.signOut,
        'Sign Out',
        icon: adaptiveIcon(
          'rectangle.portrait.and.arrow.right',
          CupertinoIcons.arrow_right_square,
        ),
        destructive: true,
      ),
    ];

    return AdaptiveAppBarAction(
      iosSymbol: 'ellipsis.circle',
      icon: CupertinoIcons.ellipsis_circle,
      label: 'More',
      menuItems: <AdaptivePopupMenuEntry>[
        for (final entry in entries)
          if (entry == null)
            const AdaptivePopupMenuDivider()
          else
            AdaptivePopupMenuItem(
              label: entry.label,
              icon: entry.icon,
              selected: entry.selected,
              isDestructive: entry.destructive,
            ),
      ],
      onMenuItemSelected: (index, item) {
        final entry = entries[index];
        if (entry != null) _handleMenu(entry.id);
      },
    );
  }

  void _handleMenu(_MenuId id) {
    final controller = ref.read(notesControllerProvider.notifier);
    switch (id) {
      case _MenuId.sortEdited:
        controller.setSort(NoteSort.updated);
      case _MenuId.sortCreated:
        controller.setSort(NoteSort.created);
      case _MenuId.sortTitle:
        controller.setSort(NoteSort.title);
      case _MenuId.refresh:
        controller.load(silent: true);
      case _MenuId.signOut:
        confirmSignOut(context, ref);
    }
  }
}