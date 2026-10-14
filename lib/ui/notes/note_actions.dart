import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/note.dart';
import '../../state/notes_controller.dart';
import 'note_editor_page.dart';

/// Opens the editor for [note] (or a blank note).
///
/// The editor autosaves when it closes. If the user chose "Delete" inside the
/// editor it pops with `true`, and we perform the delete here so the Undo
/// snackbar can be shown on the list screen.
Future<void> openNoteEditor(
    BuildContext context,
    WidgetRef ref, {
      Note? note,
    }) async {
  final deleteRequested = await Navigator.of(context).push<bool>(
    CupertinoPageRoute<bool>(builder: (_) => NoteEditorPage(note: note)),
  );
  if (deleteRequested == true && note != null && context.mounted) {
    deleteWithUndo(context, ref, note);
  }
}

/// Deletes [note] right away and offers an Undo in a snackbar.
void deleteWithUndo(BuildContext context, WidgetRef ref, Note note) {
  final controller = ref.read(notesControllerProvider.notifier);
  unawaited(controller.deleteNote(note));
  AdaptiveSnackBar.show(
    context,
    message: 'Note deleted',
    type: AdaptiveSnackBarType.info,
    action: 'Undo',
    onActionPressed: () => unawaited(controller.restoreNote(note)),
  );
}

/// Long-press menu for a note. Uses AdaptiveAlertDialog, which is a native
/// UIAlertController on iOS 26, a CupertinoAlertDialog on iOS 18 and a Material
/// dialog on Android.
Future<void> showNoteActions(BuildContext context, WidgetRef ref, Note note) {
  final controller = ref.read(notesControllerProvider.notifier);
  return AdaptiveAlertDialog.show(
    context: context,
    title: note.displayTitle,
    actions: <AlertAction>[
      AlertAction(
        title: note.isPinned ? 'Unpin' : 'Pin',
        style: AlertActionStyle.defaultAction,
        onPressed: () => unawaited(controller.togglePin(note)),
      ),
      AlertAction(
        title: 'Delete',
        style: AlertActionStyle.destructive,
        onPressed: () => deleteWithUndo(context, ref, note),
      ),
      AlertAction(
        title: 'Cancel',
        style: AlertActionStyle.cancel,
        onPressed: () {},
      ),
    ],
  );
}