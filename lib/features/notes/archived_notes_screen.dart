import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'providers/notes_provider.dart';

class ArchivedNotesScreen extends ConsumerWidget {
  const ArchivedNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedNotes = ref.watch(archivedNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Arquivados')),
      body: archivedNotes.isEmpty
          ? const Center(child: Text('Nenhuma nota arquivada.', style: TextStyle(color: AppTheme.zinc400)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: archivedNotes.length,
              itemBuilder: (context, index) {
                final note = archivedNotes[index];
                return Card(
                  color: AppTheme.zinc900,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(note.title, style: const TextStyle(color: AppTheme.zinc50, fontWeight: FontWeight.bold)),
                    subtitle: Text('Arquivado em ${note.updatedAt.day}/${note.updatedAt.month}', style: const TextStyle(color: AppTheme.zinc400)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.zinc400),
                      color: AppTheme.zinc800,
                      onSelected: (value) {
                        final actions = ref.read(notesActionsProvider);
                        if (value == 'unarchive') actions.toggleArchive(note);
                        if (value == 'trash') actions.toggleTrash(note);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'unarchive', child: Text('Desarquivar', style: TextStyle(color: AppTheme.zinc50))),
                        const PopupMenuItem(value: 'trash', child: Text('Mover para Lixeira', style: TextStyle(color: Color(0xFFF87171)))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}