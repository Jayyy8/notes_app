import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../data/notes_repository.dart';
import '../models/note.dart';
import 'core_providers.dart';
import 'notes_state.dart';

final notesRepositoryProvider = Provider<NotesRepository>(
      (ref) => NotesRepository(ref.watch(supabaseClientProvider)),
);

final notesControllerProvider = NotifierProvider<NotesController, NotesState>(
  NotesController.new,
);

class NotesController extends Notifier<NotesState> {
  late NotesRepository _repo;
  bool _mounted = false;

  /// Bumped on every rebuild/dispose so a slow request that started for a
  /// previous user can never write its result into the new state.
  int _generation = 0;

  @override
  NotesState build() {
    _repo = ref.watch(notesRepositoryProvider);
    _mounted = true;
    _generation++;
    ref.onDispose(() {
      _mounted = false;
      _generation++;
    });
    Future<void>.microtask(load);
    return const NotesState();
  }

  void _update(int generation, NotesState Function(NotesState current) change) {
    if (!_mounted || generation != _generation) return;
    state = change(state);
  }

  // ---------------------------------------------------------------- READ

  Future<void> load({bool silent = false}) async {
    final generation = _generation;
    if (!silent) {
      _update(generation, (s) => s.copyWith(isLoading: true, clearError: true));
    }
    try {
      final notes = await _repo.fetchNotes();
      _update(
        generation,
            (s) => s.copyWith(notes: notes, isLoading: false, clearError: true),
      );
    } catch (e) {
      final message = friendlyError(e);
      _update(
        generation,
            (s) => s.notes.isNotEmpty
            ? s.copyWith(isLoading: false, message: message)
            : s.copyWith(isLoading: false, error: message),
      );
    }
  }

  // -------------------------------------------------------- SEARCH / SORT

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(NoteSort sort) => state = state.copyWith(sort: sort);

  void clearMessage() {
    if (state.message != null) state = state.copyWith(clearMessage: true);
  }

  // -------------------------------------------------------- CREATE/UPDATE

  /// Creates a note, or updates [existing]. Returns true on success.
  Future<bool> saveNote({
    Note? existing,
    required String title,
    required String content,
    required bool isPinned,
  }) async {
    final generation = _generation;
    try {
      if (existing == null) {
        final created = await _repo.create(
          title: title,
          content: content,
          isPinned: isPinned,
        );
        _update(generation, (s) => s.copyWith(notes: [created, ...s.notes]));
      } else {
        final updated = await _repo.update(
          existing.id,
          title: title,
          content: content,
          isPinned: isPinned,
        );
        _update(
          generation,
              (s) => s.copyWith(notes: _replace(s.notes, updated)),
        );
      }
      return true;
    } catch (e) {
      final message = friendlyError(e);
      _update(generation, (s) => s.copyWith(message: message));
      return false;
    }
  }

  Future<void> togglePin(Note note) async {
    final generation = _generation;
    final pinned = !note.isPinned;

    // Optimistic update, then reconcile with the server row.
    _update(
      generation,
          (s) => s.copyWith(notes: _replace(s.notes, note.copyWith(isPinned: pinned))),
    );
    try {
      final updated = await _repo.setPinned(note.id, pinned);
      _update(generation, (s) => s.copyWith(notes: _replace(s.notes, updated)));
    } catch (e) {
      final message = friendlyError(e);
      _update(
        generation,
            (s) => s.copyWith(notes: _replace(s.notes, note), message: message),
      );
    }
  }

  // --------------------------------------------------------------- DELETE

  Future<void> deleteNote(Note note) async {
    final generation = _generation;

    // The removal below runs synchronously, so a swiped-away row leaves the
    // list in the same frame.
    _update(
      generation,
          (s) => s.copyWith(notes: s.notes.where((n) => n.id != note.id).toList()),
    );
    try {
      await _repo.delete(note.id);
    } catch (e) {
      final message = friendlyError(e);
      _update(
        generation,
            (s) => s.copyWith(notes: [note, ...s.notes], message: message),
      );
    }
  }

  /// Undo for [deleteNote].
  Future<void> restoreNote(Note note) async {
    final generation = _generation;
    if (state.notes.any((n) => n.id == note.id)) return;
    try {
      final restored = await _repo.restore(note);
      _update(generation, (s) => s.copyWith(notes: [restored, ...s.notes]));
    } catch (e) {
      final message = friendlyError(e);
      _update(generation, (s) => s.copyWith(message: message));
    }
  }

  List<Note> _replace(List<Note> notes, Note replacement) {
    return <Note>[
      for (final n in notes) n.id == replacement.id ? replacement : n,
    ];
  }
}