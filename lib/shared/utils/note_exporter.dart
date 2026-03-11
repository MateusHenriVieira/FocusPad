import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
// ✨ O novo caminho do import para a versão 11.5+
import 'package:flutter_quill/src/editor/widgets/text/text_line.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notes/models/note_model.dart';

class NoteExporter {
  static final ScreenshotController _screenshotController = ScreenshotController();

  static Future<void> shareNoteAsImage(Note note) async {
    try {
      quill.Document doc;
      try { 
        doc = quill.Document.fromJson(jsonDecode(note.content)); 
      } catch (e) { 
        doc = quill.Document()..insert(0, note.content); 
      }

      final exportWidget = MediaQuery(
        data: const MediaQueryData(size: Size(450, 800), devicePixelRatio: 2.0),
        child: Localizations(
          locale: const Locale('pt', 'BR'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: AppTheme.zinc950,
              child: Container(
                width: 450,
                decoration: BoxDecoration(
                  color: AppTheme.zinc950,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.zinc800, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra superior estilo Mac
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppTheme.zinc900,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                        border: Border(bottom: BorderSide(color: AppTheme.zinc800)),
                      ),
                      child: Row(
                        children: [
                          _dot(const Color(0xFFFF5F56)), const SizedBox(width: 8),
                          _dot(const Color(0xFFFFBD2E)), const SizedBox(width: 8),
                          _dot(const Color(0xFF27C93F)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.title, style: const TextStyle(color: AppTheme.zinc50, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          quill.QuillEditor.basic(
                            controller: quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0)),
                            config: quill.QuillEditorConfig(
                              showCursor: false,
                              autoFocus: false,
                              scrollable: false,
                              customStyles: quill.DefaultStyles(
                                paragraph: quill.DefaultTextBlockStyle(
                                  const TextStyle(color: Color(0xFFD4D4D8), fontSize: 16, height: 1.5),
                                  const quill.HorizontalSpacing(0, 0), const quill.VerticalSpacing(4, 4), const quill.VerticalSpacing(0, 0), null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final imageBytes = await _screenshotController.captureFromWidget(exportWidget, delay: const Duration(milliseconds: 500));
      final directory = await getTemporaryDirectory();
      final file = await File('${directory.path}/focus_${note.id}.png').create();
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Erro Export: $e');
    }
  }

  static Widget _dot(Color c) => Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}