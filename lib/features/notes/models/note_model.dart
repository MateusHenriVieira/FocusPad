import 'package:flutter/foundation.dart';

@immutable
class Note {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isArchived;
  final bool isTrashed;
  final bool isPinned;
  final DateTime updatedAt;
  final DateTime? reminderAt; 

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isArchived = false,
    this.isTrashed = false,
    this.isPinned = false,
    required this.updatedAt,
    this.reminderAt, // ✨ NOVO
  });

  Note copyWith({
    String? title,
    String? content,
    List<String>? tags,
    bool? isArchived,
    bool? isTrashed,
    bool? isPinned,
    DateTime? updatedAt,
    DateTime? reminderAt, 
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt: reminderAt ?? this.reminderAt, 
    );
  }
}