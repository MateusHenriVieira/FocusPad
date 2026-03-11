import 'package:firebase_database/firebase_database.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Escuta as notas do usuário em tempo real
  Stream<List<Note>> getUserNotesStream(String uid) {
    return _db.ref().child('users').child(uid).child('notes').onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value == null) return [];

      final Map<dynamic, dynamic> notesMap = snapshot.value as Map<dynamic, dynamic>;
      
      return notesMap.entries.map((e) {
        final data = Map<String, dynamic>.from(e.value);
        return Note(
          id: e.key,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          isArchived: data['isArchived'] ?? false,
          isTrashed: data['isTrashed'] ?? false,
          isPinned: data['isPinned'] ?? false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
        );
      }).toList();
    });
  }

  // Cria ou Atualiza uma nota (Faz o Merge)
  Future<void> saveNote(String uid, Note note) async {
    final noteRef = _db.ref().child('users').child(uid).child('notes').child(note.id);
    await noteRef.set({
      'title': note.title,
      'content': note.content,
      'tags': note.tags,
      'isArchived': note.isArchived,
      'isTrashed': note.isTrashed,
      'isPinned': note.isPinned,
      'updatedAt': note.updatedAt.millisecondsSinceEpoch,
    });
  }

  // Deleta permanentemente do banco
  Future<void> deleteNote(String uid, String noteId) async {
    await _db.ref().child('users').child(uid).child('notes').child(noteId).remove();
  }
}