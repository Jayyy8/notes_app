import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        SliverToBoxAdapter(
          child: _SearchField(
            initialText: state.query,
            onChanged: controller.setQuery,
          ),
        ),
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
              itemCount: notes.length,
              itemBuilder: (context, index) => NoteRow(note: notes[index]),
            ),
        if (!showError && (showSkeleton || notes.isNotEmpty))
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
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

class _SearchField extends StatefulWidget {
  const _SearchField({required this.initialText, required this.onChanged});

  final String initialText;
  final ValueChanged<String> onChanged;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AdaptiveTextField(
        controller: _controller,
        placeholder: 'Search notes',
        textInputAction: TextInputAction.search,
        autocorrect: false,
        prefixIcon: const Icon(CupertinoIcons.search),
        onChanged: widget.onChanged,
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