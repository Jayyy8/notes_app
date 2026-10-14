class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Fake note used to give the skeleton loader something to shape itself around.
  factory Note.placeholder(int index) {
    return Note(
      id: 'placeholder-$index',
      title: 'Loading note title',
      content:
      'Loading the preview of this note so the skeleton has some text to '
          'shape itself around while the real data arrives.',
      isPinned: false,
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    );
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      isPinned: (map['is_pinned'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  Note copyWith({
    String? title,
    String? content,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// The title, or the first line of the body when the title is empty.
  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final firstLine = content.trim().split('\n').first.trim();
    return firstLine.isEmpty ? 'Untitled note' : firstLine;
  }

  /// Body text shown under the title in lists.
  String get preview {
    final body = content.trim();
    if (title.trim().isNotEmpty) return body;
    final newline = body.indexOf('\n');
    return newline == -1 ? '' : body.substring(newline + 1).trim();
  }
}