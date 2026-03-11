import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import 'models/note_model.dart';
import 'providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late quill.QuillController _quillController;
  
  Note? _currentNote;
  Timer? _autoSaveTimer;
  DateTime? _reminderDate;
  
  late NotesActions _actions;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote?.title ?? '');
    _tagsController = TextEditingController(text: _currentNote?.tags.join(', ') ?? '');
    _reminderDate = _currentNote?.reminderAt;

    quill.Document doc;
    try {
      doc = quill.Document.fromJson(jsonDecode(_currentNote!.content));
    } catch (e) {
      doc = quill.Document()..insert(0, _currentNote?.content ?? '');
    }

    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _quillController.addListener(_onDataChanged);
    _titleController.addListener(_onDataChanged);
    _tagsController.addListener(_onDataChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actions = ref.read(notesActionsProvider);
    _uid = ref.read(authStateProvider).value?.uid;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _saveNoteSilentFinal(); 
    _titleController.dispose();
    _tagsController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1000), _saveNoteSilent);
  }

  void _saveNoteSilent() {
    if (!mounted) return;
    _performSave(ref.read(notesActionsProvider), ref.read(authStateProvider).value?.uid);
  }

  void _saveNoteSilentFinal() {
    _performSave(_actions, _uid);
  }

  void _performSave(NotesActions actions, String? uid) {
    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (title.isEmpty && _quillController.document.isEmpty()) return;
    if (uid == null) return;

    if (_currentNote == null) {
      _currentNote = Note(
        id: const Uuid().v4(),
        title: title,
        content: content,
        tags: tags,
        updatedAt: DateTime.now(),
        reminderAt: _reminderDate,
      );
    } else {
      _currentNote = _currentNote!.copyWith(
        title: title, 
        content: content, 
        tags: tags, 
        updatedAt: DateTime.now(), 
        reminderAt: _reminderDate
      );
    }
    actions.save(_currentNote, title, content, tags);
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
        builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
      );
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
        _saveNoteSilent();
      }
    }
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configurações da Nota', style: TextStyle(color: AppTheme.zinc50, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Tags', style: TextStyle(color: AppTheme.zinc400, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              style: const TextStyle(color: AppTheme.zinc50),
              decoration: InputDecoration(
                hintText: 'Ex: senhas, ideias...',
                hintStyle: const TextStyle(color: Color(0xFF52525B)),
                filled: true,
                fillColor: AppTheme.zinc950,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Notificação', style: TextStyle(color: AppTheme.zinc400, fontSize: 14)),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setModalState) => InkWell(
                onTap: () async {
                  await _pickReminder();
                  setModalState(() {}); 
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _reminderDate != null ? const Color(0xFF18181B) : AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _reminderDate != null ? AppTheme.zinc50 : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: _reminderDate != null ? AppTheme.zinc50 : const Color(0xFF52525B)),
                      const SizedBox(width: 12),
                      Text(
                        _reminderDate != null 
                          ? '${_reminderDate!.day}/${_reminderDate!.month} às ${_reminderDate!.hour.toString().padLeft(2, '0')}:${_reminderDate!.minute.toString().padLeft(2, '0')}'
                          : 'Definir Lembrete...',
                        style: TextStyle(color: _reminderDate != null ? AppTheme.zinc50 : const Color(0xFF52525B), fontSize: 16),
                      ),
                      const Spacer(),
                      if (_reminderDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.zinc400, size: 20),
                          onPressed: () {
                            setState(() => _reminderDate = null);
                            setModalState(() {});
                            _saveNoteSilent();
                          },
                        )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLinkDialog() async {
    final urlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.zinc900,
        title: const Text('Inserir Link', style: TextStyle(color: AppTheme.zinc50)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: AppTheme.zinc50),
          decoration: const InputDecoration(hintText: 'https://...', hintStyle: TextStyle(color: Color(0xFF52525B))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.zinc400))),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                _quillController.formatSelection(quill.LinkAttribute(urlController.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar', style: TextStyle(color: AppTheme.zinc50)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      appBar: AppBar(
        backgroundColor: AppTheme.zinc950,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.zinc50),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _titleController,
          cursorColor: AppTheme.zinc50,
          style: const TextStyle(color: AppTheme.zinc50, fontSize: 22, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Título da nota...',
            hintStyle: TextStyle(color: Color(0xFF52525B)),
            border: InputBorder.none,
            filled: false, 
          ),
        ),
        actions: [
          if (_reminderDate != null)
            const Center(child: Icon(Icons.alarm, color: AppTheme.zinc400, size: 18)),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.zinc50),
            onPressed: _showOptionsModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: Container(
        color: AppTheme.zinc950, // Garante que a raiz do corpo seja Zinc 950
        child: Column(
          children: [
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppTheme.zinc950, // ✨ Remove o branco do fundo do canvas
                  scaffoldBackgroundColor: AppTheme.zinc950,
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionColor: Color(0xFF3F3F46),
                    cursorColor: AppTheme.zinc50,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: quill.QuillEditor.basic(
                    controller: _quillController,
                    config: quill.QuillEditorConfig(
                      placeholder: 'Escreva sua anotação...',
                      padding: const EdgeInsets.only(top: 16, bottom: 40),
                      scrollable: true,
                      expands: true,
                      autoFocus: false,
                      customStyles: quill.DefaultStyles(
                        paragraph: quill.DefaultTextBlockStyle(
                          const TextStyle(
                            color: Color(0xFFD4D4D8),
                            fontSize: 16, 
                            height: 1.6,
                            backgroundColor: Colors.transparent, // ✨ Remove branco residual em cada linha
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(4, 4),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        lists: quill.DefaultListBlockStyle(
                          const TextStyle(
                            color: Color(0xFFD4D4D8),
                            fontSize: 16,
                            backgroundColor: Colors.transparent,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(4, 4),
                          const quill.VerticalSpacing(0, 0),
                          null,
                          null,
                        ),
                      ),
                      contextMenuBuilder: (context, rawEditorState) {
                        final buttonItems = rawEditorState.contextMenuButtonItems;
                        buttonItems.insert(0, ContextMenuButtonItem(
                          label: 'Negrito',
                          onPressed: () {
                            final attrs = _quillController.getSelectionStyle().attributes;
                            bool isBold = attrs.containsKey('bold');
                            _quillController.formatSelection(isBold ? quill.Attribute.clone(quill.Attribute.bold, null) : quill.Attribute.bold);
                            rawEditorState.hideToolbar();
                          },
                        ));
                        buttonItems.insert(1, ContextMenuButtonItem(
                          label: 'Lista',
                          onPressed: () {
                            final attrs = _quillController.getSelectionStyle().attributes;
                            bool isList = attrs.containsKey('list');
                            _quillController.formatSelection(isList ? quill.Attribute.clone(quill.Attribute.ul, null) : quill.Attribute.ul);
                            rawEditorState.hideToolbar();
                          },
                        ));
                        buttonItems.insert(2, ContextMenuButtonItem(
                          label: 'Link',
                          onPressed: () {
                            rawEditorState.hideToolbar();
                            _showLinkDialog();
                          },
                        ));
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: rawEditorState.contextMenuAnchors,
                          buttonItems: buttonItems,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}