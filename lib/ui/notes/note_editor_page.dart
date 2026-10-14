import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/adaptive_icons.dart';
import '../../core/app_colors.dart';
import '../../core/body_inset.dart';
import '../../core/date_format.dart';
import '../../models/note.dart';
import '../../state/notes_controller.dart';

/// Create / edit a note.
///
/// There is no Save button to forget: the note is saved automatically when the
/// page closes (Done, back button or swipe back). Empty new notes are discarded.
/// Pops with `true` when the user chose Delete.
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  // Indexes into the toolbar menu below (dividers count as entries).
  static const int _pinMenuIndex = 0;
  static const int _deleteMenuIndex = 2;

  late final TextEditingController _title =
  TextEditingController(text: widget.note?.title ?? '');
  late final TextEditingController _content =
  TextEditingController(text: widget.note?.content ?? '');
  final FocusNode _contentFocus = FocusNode();
  late bool _pinned = widget.note?.isPinned ?? false;

  /// Captured now so the save can still run while the page is animating away.
  late final NotesController _controller;
  bool _skipSave = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(notesControllerProvider.notifier);
    _content.addListener(_refresh);
  }

  @override
  void dispose() {
    _content.removeListener(_refresh);
    _title.dispose();
    _content.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _stats {
    final text = _content.text;
    final words = RegExp(r'\S+').allMatches(text).length;
    return '$words ${words == 1 ? 'word' : 'words'} · ${text.length} characters';
  }

  void _saveIfNeeded() {
    if (_skipSave) return;

    final title = _title.text.trim();
    final content = _content.text.trim();
    final existing = widget.note;

    if (existing == null) {
      if (title.isEmpty && content.isEmpty) return;
      _controller.saveNote(title: title, content: content, isPinned: _pinned);
      return;
    }

    final changed = title != existing.title ||
        content != existing.content ||
        _pinned != existing.isPinned;
    if (!changed) return;
    _controller.saveNote(
      existing: existing,
      title: title,
      content: content,
      isPinned: _pinned,
    );
  }

  void _done() => Navigator.of(context).pop();

  void _togglePin() => setState(() => _pinned = !_pinned);

  void _requestDelete() {
    _skipSave = true;
    void close() {
      if (mounted) Navigator.of(context).pop(true);
    }

    // If a menu route is still animating out, wait one frame so we pop this
    // page and not the menu.
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      close();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => close());
    }
  }

  AdaptiveAppBarAction _buildMenuAction() {
    final isExisting = widget.note != null;
    return AdaptiveAppBarAction(
      iosSymbol: 'ellipsis.circle',
      icon: CupertinoIcons.ellipsis_circle,
      label: 'More',
      menuItems: <AdaptivePopupMenuEntry>[
        AdaptivePopupMenuItem(
          label: _pinned ? 'Unpin Note' : 'Pin Note',
          icon: adaptiveIcon(
            _pinned ? 'pin.slash' : 'pin',
            _pinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          ),
        ),
        if (isExisting) const AdaptivePopupMenuDivider(),
        if (isExisting)
          AdaptivePopupMenuItem(
            label: 'Delete Note',
            icon: adaptiveIcon('trash', CupertinoIcons.trash),
            isDestructive: true,
          ),
      ],
      onMenuItemSelected: (index, item) {
        if (index == _pinMenuIndex) {
          _togglePin();
        } else if (index == _deleteMenuIndex) {
          _requestDelete();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.note;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveIfNeeded();
      },
      child: AdaptiveScaffold(
        backgroundColor: groupedBackground(context),
        appBar: AdaptiveAppBar(
          title: existing == null ? 'New Note' : 'Edit Note',
          tintColor: kAccent,
          actions: <AdaptiveAppBarAction>[
            _buildMenuAction(),
            AdaptiveAppBarAction(
              iosSymbol: 'checkmark',
              icon: CupertinoIcons.checkmark,
              label: 'Done',
              onPressed: _done,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 12 + bodyTopInset(context), 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Tapping empty space inside the card starts typing.
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _contentFocus.requestFocus,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackground(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CupertinoTextField(
                          controller: _title,
                          placeholder: 'Title',
                          placeholderStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: tertiaryLabel(context),
                          ),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: primaryLabel(context),
                          ),
                          decoration: null,
                          padding: EdgeInsets.zero,
                          cursorColor: kAccent,
                          autofocus: existing == null,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLines: null,
                          onSubmitted: (_) => _contentFocus.requestFocus(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            height: 0.5,
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        CupertinoTextField(
                          controller: _content,
                          focusNode: _contentFocus,
                          placeholder: 'Start writing...',
                          placeholderStyle: TextStyle(
                            fontSize: 17,
                            color: tertiaryLabel(context),
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.4,
                            color: primaryLabel(context),
                          ),
                          decoration: null,
                          padding: EdgeInsets.zero,
                          cursorColor: kAccent,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 14,
                          maxLines: null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _stats,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: tertiaryLabel(context)),
                ),
                if (existing != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Edited ${formatNoteDate(existing.updatedAt)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: tertiaryLabel(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}