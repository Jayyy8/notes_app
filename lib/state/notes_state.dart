import '../models/note.dart';

enum NoteSort { updated, created, title }

class NotesState {
  const NotesState({
    this.notes = const <Note>[],
    this.isLoading = true,
    this.error,
    this.query = '',
    this.sort = NoteSort.updated,
    this.message,
  });

  /// Every note the user owns, in no particular order.
  final List<Note> notes;

  /// True during the first load (drives the skeleton).
  final bool isLoading;

  /// Set when the first load failed and there is nothing to show.
  final String? error;

  final String query;
  final NoteSort sort;

  /// One-shot message shown as a snackbar, then cleared.
  final String? message;

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? query,
    NoteSort? sort,
    String? message,
    bool clearMessage = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      sort: sort ?? this.sort,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  /// Notes after search + sort. Pinned notes always come first.
  List<Note> notesFor({required bool pinnedOnly}) {
    final needle = query.trim().toLowerCase();
    Iterable<Note> list = notes;
    if (pinnedOnly) list = list.where((n) => n.isPinned);
    if (needle.isNotEmpty) {
      list = list.where(
            (n) =>
        n.title.toLowerCase().contains(needle) ||
            n.content.toLowerCase().contains(needle),
      );
    }
    return list.toList()..sort(_compare);
  }

  int _compare(Note a, Note b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    switch (sort) {
      case NoteSort.updated:
        return b.updatedAt.compareTo(a.updatedAt);
      case NoteSort.created:
        return b.createdAt.compareTo(a.createdAt);
      case NoteSort.title:
        return a.displayTitle.toLowerCase().compareTo(
          b.displayTitle.toLowerCase(),
        );
    }
  }
}