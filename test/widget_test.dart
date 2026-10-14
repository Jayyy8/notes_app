import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/date_format.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/state/notes_state.dart';

Note _note(
    String id, {
      String title = '',
      String content = '',
      bool pinned = false,
      DateTime? updated,
    }) {
  return Note(
    id: id,
    title: title,
    content: content,
    isPinned: pinned,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: updated ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('Note', () {
    test('fromMap parses a Supabase row', () {
      final note = Note.fromMap(<String, dynamic>{
        'id': 'abc',
        'title': 'Groceries',
        'content': 'Milk',
        'is_pinned': true,
        'created_at': '2026-10-01T08:00:00+00:00',
        'updated_at': '2026-10-02T08:00:00+00:00',
      });
      expect(note.id, 'abc');
      expect(note.title, 'Groceries');
      expect(note.isPinned, isTrue);
      expect(note.updatedAt.isAfter(note.createdAt), isTrue);
    });

    test('displayTitle falls back to the first line of the body', () {
      final note = _note('1', content: 'First line\nSecond line');
      expect(note.displayTitle, 'First line');
      expect(note.preview, 'Second line');
    });

    test('empty note is called Untitled note', () {
      expect(_note('1').displayTitle, 'Untitled note');
    });
  });

  group('NotesState.notesFor', () {
    final notes = <Note>[
      _note('a', title: 'Alpha', updated: DateTime(2026, 1, 3)),
      _note('b', title: 'Bravo', pinned: true, updated: DateTime(2026, 1, 1)),
      _note('c', title: 'Charlie', content: 'alpha beta', updated: DateTime(2026, 1, 2)),
    ];

    test('pinned notes come first, then newest edit', () {
      final ids = NotesState(notes: notes).notesFor(pinnedOnly: false);
      expect(ids.map((n) => n.id), <String>['b', 'a', 'c']);
    });

    test('pinnedOnly filters', () {
      final result = NotesState(notes: notes).notesFor(pinnedOnly: true);
      expect(result.map((n) => n.id), <String>['b']);
    });

    test('search matches title and content, ignoring case', () {
      final result = NotesState(notes: notes, query: 'ALPHA')
          .notesFor(pinnedOnly: false);
      expect(result.map((n) => n.id).toSet(), <String>{'a', 'c'});
    });
  });

  group('formatNoteDate', () {
    final now = DateTime(2026, 10, 14, 12);

    test('today shows the time', () {
      expect(formatNoteDate(DateTime(2026, 10, 14, 9, 5), now: now), '9:05 AM');
      expect(formatNoteDate(DateTime(2026, 10, 14, 0, 30), now: now), '12:30 AM');
      expect(formatNoteDate(DateTime(2026, 10, 14, 15, 45), now: now), '3:45 PM');
    });

    test('yesterday, weekday, month and year', () {
      expect(formatNoteDate(DateTime(2026, 10, 13, 20), now: now), 'Yesterday');
      expect(formatNoteDate(DateTime(2026, 10, 11, 20), now: now), 'Sunday');
      expect(formatNoteDate(DateTime(2026, 9, 3), now: now), 'Sep 3');
      expect(formatNoteDate(DateTime(2025, 9, 3), now: now), 'Sep 3, 2025');
    });
  });
}