import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/body_inset.dart';
import '../../models/note.dart';
import '../../state/notes_controller.dart';
import '../widgets/skeleton_scope.dart';
import '../widgets/state_views.dart';
import 'note_actions.dart';
import 'note_tile.dart';

/// The list shown on the "Notes" and "Pinned" tabs.
class NotesListView extends ConsumerWidget {
  const NotesListView({
    super.key,
    required this.pinnedOnly,
    required this.bottomPadding,
  });

  final bool pinnedOnly;

  /// Extra space at the bottom so the last note clears the tab bar
  /// (on iOS 26 the body slides underneath the floating glass tab bar).
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesControllerProvider);
    final controller = ref.read(notesControllerProvider.notifier);

    final notes = state.notesFor(pinnedOnly: pinnedOnly);
    final isSearching = state.query.trim().isNotEmpty;
    final showSkeleton = state.isLoading && state.notes.isEmpty;
    final showError =
        !showSkeleton && state.error != null && state.notes.isEmpty;

    // Section headings only make sense on the main tab, when not searching.
    final items = _buildItems(notes, showHeadings: !pinnedOnly && !isSearching);
    final glass = PlatformInfo.isIOS26OrHigher();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // Bouncing physics on every platform so pull-to-refresh also works on Android.
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: <Widget>[
        CupertinoSliverRefreshControl(
          onRefresh: () => controller.load(silent: true),
        ),
        if (glass)
        // iOS 26 only: a pinned glass pill; notes scroll underneath it.
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              topInset: bodyTopInset(context),
              backgroundColor: groupedBackground(context),
              initialText: state.query,
              onChanged: controller.setQuery,
            ),
          )
        else ...<Widget>[
          // Android and iOS 18: exactly the same layout as before.
          SliverToBoxAdapter(child: SizedBox(height: bodyTopInset(context))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SearchField(
                initialText: state.query,
                onChanged: controller.setQuery,
                glass: false,
              ),
            ),
          ),
        ],
        if (showSkeleton)
          const SliverToBoxAdapter(child: _NotesSkeleton())
        else if (showError)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: ErrorState(
                message: state.error!,
                onRetry: controller.load,
              ),
            ),
          )
        else if (notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: _buildEmpty(context, ref, isSearching),
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is Note) return NoteRow(note: item);
                return _SectionHeader(title: item as String);
              },
            ),
        if (!showError && (showSkeleton || notes.isNotEmpty))
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }

  /// Notes (already pinned-first) with "Pinned" / "Notes" headings mixed in.
  List<Object> _buildItems(List<Note> notes, {required bool showHeadings}) {
    if (!showHeadings) return List<Object>.of(notes);

    final pinned = notes.where((n) => n.isPinned).toList();
    final others = notes.where((n) => !n.isPinned).toList();
    final items = <Object>[];
    if (pinned.isNotEmpty) {
      items
        ..add('Pinned')
        ..addAll(pinned);
    }
    if (others.isNotEmpty) {
      // A "Notes" heading is only useful when there is a "Pinned" one above it.
      if (pinned.isNotEmpty) items.add('Notes');
      items.addAll(others);
    }
    return items;
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref, bool isSearching) {
    if (isSearching) {
      return const EmptyState(
        icon: CupertinoIcons.search,
        title: 'No results',
        message: 'Try a different word.',
      );
    }
    if (pinnedOnly) {
      return const EmptyState(
        icon: CupertinoIcons.pin,
        title: 'No pinned notes',
        message: 'Press and hold a note, then choose Pin to keep it here.',
      );
    }
    return EmptyState(
      icon: CupertinoIcons.doc_text,
      title: 'No notes yet',
      message: 'Create your first note and it will sync to your account.',
      action: SizedBox(
        width: 180,
        height: 44,
        child: AdaptiveButton(
          onPressed: () => openNoteEditor(context, ref),
          label: 'New Note',
          style: AdaptiveButtonStyle.tinted,
          color: kAccent,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: secondaryLabel(context),
        ),
      ),
    );
  }
}

/// One tappable, swipe-to-delete, long-pressable note.
class NoteRow extends ConsumerWidget {
  const NoteRow({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: ValueKey<String>(note.id),
        direction: DismissDirection.endToStart,
        background: const _DeleteBackground(),
        secondaryBackground: const _DeleteBackground(),
        onDismissed: (_) => deleteWithUndo(context, ref, note),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openNoteEditor(context, ref, note: note),
          onLongPress: () => showNoteActions(context, ref, note),
          child: NoteTile(note: note),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(CupertinoIcons.trash, color: CupertinoColors.white),
    );
  }
}

/// Keeps the search bar pinned under the toolbar while the list scrolls.
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({
    required this.topInset,
    required this.backgroundColor,
    required this.initialText,
    required this.onChanged,
  });

  /// Space reserved for the floating iOS 26 toolbar (0 elsewhere).
  final double topInset;
  final Color backgroundColor;
  final String initialText;
  final ValueChanged<String> onChanged;

  static const double _barHeight = 60;

  @override
  double get minExtent => topInset + _barHeight;

  @override
  double get maxExtent => topInset + _barHeight;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final glass = PlatformInfo.isIOS26OrHigher();
    return Container(
      // Transparent on iOS 26 so notes show through the glass as they scroll.
      color: glass ? null : backgroundColor,
      padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 8),
      child: _SearchField(
        initialText: initialText,
        onChanged: onChanged,
        glass: glass,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.topInset != topInset ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.initialText,
    required this.onChanged,
    required this.glass,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final bool glass;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.glass) {
      return _GlassSearchBox(
        controller: _controller,
        onChanged: widget.onChanged,
      );
    }
    return AdaptiveTextField(
      controller: _controller,
      placeholder: 'Search notes',
      textInputAction: TextInputAction.search,
      autocorrect: false,
      prefixIcon: const Icon(CupertinoIcons.search),
      onChanged: widget.onChanged,
    );
  }
}

/// iOS 26 search pill: a native blur material (AdaptiveBlurView) with a thin
/// light edge, so it reads as glass over the notes scrolling beneath it.
class _GlassSearchBox extends StatelessWidget {
  const _GlassSearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final radius = BorderRadius.circular(22);

    return SizedBox(
      height: 44,
      child: AdaptiveBlurView(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: CupertinoColors.white.withValues(
                alpha: isDark ? 0.16 : 0.7,
              ),
              width: 0.8,
            ),
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Search notes',
            placeholderStyle: TextStyle(
              fontSize: 17,
              color: secondaryLabel(context),
            ),
            style: TextStyle(fontSize: 17, color: primaryLabel(context)),
            decoration: null,
            cursorColor: kAccent,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            clearButtonMode: OverlayVisibilityMode.editing,
            padding: const EdgeInsets.symmetric(vertical: 12),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(
                CupertinoIcons.search,
                size: 18,
                color: secondaryLabel(context),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Skeletonizer placeholder shown during the first load.
class _NotesSkeleton extends StatelessWidget {
  const _NotesSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: NoteTile(note: Note.placeholder(i)),
            ),
        ],
      ),
    );
  }
}