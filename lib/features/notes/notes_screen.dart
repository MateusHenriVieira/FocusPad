import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/utils/note_exporter.dart';
import 'providers/notes_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final doc = quill.Document.fromJson(jsonDecode(content));
      return doc.toPlainText().trim();
    } catch (e) {
      return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(filteredNotesProvider);

    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      // NENHUM DRAWER AQUI. Interface 100% limpa.
      
      appBar: AppBar(
        title: const Text(
          'Minhas Notas',
          style: TextStyle(color: AppTheme.zinc50, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: AppTheme.zinc950,
        elevation: 0,
        scrolledUnderElevation: 0, // Evita sombra ao rolar
        actions: [
          // Menu Global Premium (Substituto da Barra Lateral)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppTheme.zinc50, size: 28),
            color: AppTheme.zinc900,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.zinc800, width: 1),
            ),
            elevation: 10,
            onSelected: (value) {
              if (value == 'archived') {
                context.push('/archived');
              } else if (value == 'trashed') {
                context.push('/trashed');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, color: AppTheme.zinc50, size: 20),
                    SizedBox(width: 12),
                    Text('Notas Arquivadas', style: TextStyle(color: AppTheme.zinc50, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'trashed',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppTheme.zinc400, size: 20),
                    SizedBox(width: 12),
                    Text('Lixeira', style: TextStyle(color: AppTheme.zinc400, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      
      body: Column(
        children: [
          // Barra de Pesquisa & Gatilho Secreto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.zinc800),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.zinc50),
                decoration: const InputDecoration(
                  hintText: 'Pesquisar anotações...',
                  hintStyle: TextStyle(color: AppTheme.zinc400),
                  prefixIcon: Icon(Icons.search, color: AppTheme.zinc400),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) async {
                  final query = value.trim().toLowerCase();
                  
                  // O GATILHO DO COFRE
                  if (query == 'chazan') {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).updateQuery('');
                    
                    final authService = ref.read(authServiceProvider);
                    final currentUser = authService.currentUser;
                    
                    if (currentUser != null) {
                      // Importante: certifique-se de que o DatabaseService tem esse método implementado
                      // e que importamos corretamente. O Riverpod vai lidar com a validação silenciosa.
                      // Como configuramos no Firebase, se você for ADMIN, ele abre o Chat.
                      context.go('/chat'); 
                    }
                    return;
                  }
                  
                  // Pesquisa normal
                  ref.read(searchQueryProvider.notifier).updateQuery(value);
                },
              ),
            ),
          ),
          
          // Lista de Notas
          Expanded(
            child: notes.isEmpty
                ? const Center(
                    child: Text('Nenhuma nota encontrada.', style: TextStyle(color: AppTheme.zinc400, fontSize: 16)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 colunas para parecer um mural
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85, // Proporção do Card
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return GestureDetector(
                        onTap: () => context.push('/editor', extra: note),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.zinc900,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.zinc800),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Espaço para o ícone de fixado não sobrepor o texto
                                  if (note.isPinned) const SizedBox(height: 20),
                                  
                                  Text(
                                    note.title,
                                    style: const TextStyle(color: AppTheme.zinc50, fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Expanded(
                                    child: Text(
                                      _getPlainText(note.content),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.zinc400, height: 1.4, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Ícone de Fixado
                              if (note.isPinned)
                                const Positioned(
                                  top: -2,
                                  left: -2,
                                  child: Icon(Icons.push_pin_rounded, color: AppTheme.zinc50, size: 16),
                                ),
                                
                              // Menu Individual da Nota
                              Positioned(
                                top: -14,
                                right: -14,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppTheme.zinc400, size: 20),
                                  color: AppTheme.zinc900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppTheme.zinc800),
                                  ),
                                  onSelected: (value) async {
                                    final actions = ref.read(notesActionsProvider);
                                    if (value == 'pin') actions.togglePin(note);
                                    if (value == 'archive') actions.toggleArchive(note);
                                    if (value == 'trash') actions.toggleTrash(note);
                                    if (value == 'export') {
                                      await NoteExporter.shareNoteAsImage(note);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'pin',
                                      child: Row(
                                        children: [
                                          Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: AppTheme.zinc50, size: 18),
                                          const SizedBox(width: 10),
                                          Text(note.isPinned ? 'Desfixar' : 'Fixar', style: const TextStyle(color: AppTheme.zinc50)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(Icons.archive_outlined, color: AppTheme.zinc50, size: 18),
                                          const SizedBox(width: 10),
                                          Text('Arquivar', style: TextStyle(color: AppTheme.zinc50)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'export',
                                      child: Row(
                                        children: [
                                          Icon(Icons.image_outlined, color: AppTheme.zinc50, size: 18),
                                          const SizedBox(width: 10),
                                          Text('Exportar', style: TextStyle(color: AppTheme.zinc50)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'trash',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 18),
                                          const SizedBox(width: 10),
                                          Text('Lixeira', style: TextStyle(color: Color(0xFFF87171))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.zinc50,
        foregroundColor: AppTheme.zinc950,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          context.push('/editor');
        },
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}