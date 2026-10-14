import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../models/note.dart';

/// All CRUD calls for the `notes` table.
///
/// Row Level Security (see supabase/schema.sql) guarantees each signed-in user
/// can only read and write their own rows.
class NotesRepository {
  NotesRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'notes';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('You are signed out. Please sign in again.');
    }
    return id;
  }

  // READ
  Future<List<Note>> fetchNotes() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false);
    return rows.map<Note>((row) => Note.fromMap(row)).toList();
  }

  // CREATE
  Future<Note> create({
    required String title,
    required String content,
    required bool isPinned,
  }) async {
    final row = await _client
        .from(_table)
        .insert(<String, dynamic>{
      'user_id': _userId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
    })
        .select()
        .single();
    return Note.fromMap(row);
  }

  // UPDATE
  Future<Note> update(
      String id, {
        required String title,
        required String content,
        required bool isPinned,
      }) async {
    final row = await _client
        .from(_table)
        .update(<String, dynamic>{
      'title': title,
      'content': content,
      'is_pinned': isPinned,
    })
        .eq('id', id)
        .select()
        .single();
    return Note.fromMap(row);
  }

  Future<Note> setPinned(String id, bool isPinned) async {
    final row = await _client
        .from(_table)
        .update(<String, dynamic>{'is_pinned': isPinned})
        .eq('id', id)
        .select()
        .single();
    return Note.fromMap(row);
  }

  // DELETE
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Re-inserts a deleted note with its original id and created date (undo).
  Future<Note> restore(Note note) async {
    final row = await _client
        .from(_table)
        .insert(<String, dynamic>{
      'id': note.id,
      'user_id': _userId,
      'title': note.title,
      'content': note.content,
      'is_pinned': note.isPinned,
      'created_at': note.createdAt.toUtc().toIso8601String(),
    })
        .select()
        .single();
    return Note.fromMap(row);
  }
}