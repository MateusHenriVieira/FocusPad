import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'providers/notes_provider.dart';

class TrashedNotesScreen extends ConsumerWidget {
  const TrashedNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedNotes = ref.watch(trashedNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lixeira')),
      body: trashedNotes.isEmpty
          ? const Center(child: Text('A lixeira está vazia.', style: TextStyle(color: AppTheme.zinc400)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trashedNotes.length,
              itemBuilder: (context, index) {
                final note = trashedNotes[index];
                return Card(
                  color: AppTheme.zinc900,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(note.title, style: const TextStyle(color: AppTheme.zinc50, fontWeight: FontWeight.bold)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.zinc400),
                      color: AppTheme.zinc800,
                      onSelected: (value) {
                        final actions = ref.read(notesActionsProvider);
                        if (value == 'restore') actions.toggleTrash(note); // Tira da lixeira
                        if (value == 'delete') actions.deletePermanently(note.id); // Destrói do banco
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'restore', child: Text('Restaurar', style: TextStyle(color: AppTheme.zinc50))),
                        const PopupMenuItem(value: 'delete', child: Text('Excluir Permanentemente', style: TextStyle(color: Color(0xFFF87171)))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}