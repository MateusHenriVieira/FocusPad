import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../../auth/providers/auth_provider.dart';

// --- Serviços ---
final noteServiceProvider = Provider<NoteService>((ref) => NoteService());

// Escuta as mudanças de login para saber de quem buscar as notas
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// --- O Cérebro em Nuvem ---
// Este provedor escuta o Firebase o tempo todo. Se houver mudança no DB, a UI atualiza sozinha.
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]); // Se não houver login, retorna vazio
  
  return ref.read(noteServiceProvider).getUserNotesStream(user.uid);
});

// --- Pesquisa e Filtro ---
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Junta a Stream do Firebase com a Barra de Pesquisa
final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notesAsync = ref.watch(notesStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return notesAsync.when(
    data: (notes) {
      // Ignora lixeira e arquivos na tela principal
      final activeNotes = notes.where((n) => !n.isTrashed && !n.isArchived).toList();

      // Ordenação Premium: Fixados primeiro, depois mais recentes
      activeNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      if (query.isEmpty) return activeNotes;

      return activeNotes.where((note) {
        return note.title.toLowerCase().contains(query) || 
               note.content.toLowerCase().contains(query) ||
               note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    },
    loading: () => [], // Retorna vazio enquanto carrega
    error: (_, __) => [],
  );
});

// --- Controlador de Ações (Mutações no Banco) ---
class NotesActions {
  final Ref ref;
  NotesActions(this.ref);

  String? get _uid => ref.read(authStateProvider).value?.uid;

  void save(Note? existingNote, String title, String content, List<String> tags) {
    if (_uid == null) return;
    
    final note = existingNote?.copyWith(
      title: title, content: content, tags: tags, updatedAt: DateTime.now(),
    ) ?? Note(
      id: const Uuid().v4(), title: title, content: content, tags: tags, updatedAt: DateTime.now(),
    );

    ref.read(noteServiceProvider).saveNote(_uid!, note);
  }

  void togglePin(Note note) {
    if (_uid == null) return;
    ref.read(noteServiceProvider).saveNote(_uid!, note.copyWith(isPinned: !note.isPinned));
  }

  void toggleArchive(Note note) {
    if (_uid == null) return;
    ref.read(noteServiceProvider).saveNote(_uid!, note.copyWith(isArchived: !note.isArchived));
  }

  void toggleTrash(Note note) {
    if (_uid == null) return;
    ref.read(noteServiceProvider).saveNote(_uid!, note.copyWith(isTrashed: !note.isTrashed));
  }

  void deletePermanently(String noteId) {
    if (_uid == null) return;
    ref.read(noteServiceProvider).deleteNote(_uid!, noteId);
  }
}

final notesActionsProvider = Provider<NotesActions>((ref) => NotesActions(ref));

// Provedor de Notas Arquivadas
final archivedNotesProvider = Provider<List<Note>>((ref) {
  final notesAsync = ref.watch(notesStreamProvider);
  return notesAsync.maybeWhen(
    data: (notes) => notes.where((n) => n.isArchived && !n.isTrashed).toList(),
    orElse: () => [],
  );
});

// Provedor de Notas na Lixeira
final trashedNotesProvider = Provider<List<Note>>((ref) {
  final notesAsync = ref.watch(notesStreamProvider);
  return notesAsync.maybeWhen(
    data: (notes) => notes.where((n) => n.isTrashed).toList(),
    orElse: () => [],
  );
});