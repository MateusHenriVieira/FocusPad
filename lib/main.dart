import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ✨ Mudança no import para compatibilidade com v11.5.0
import 'package:flutter_quill/flutter_quill.dart'; 

// Importações do Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Nossas telas e tema
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart'; 
import 'features/notes/notes_screen.dart';
import 'features/notes/note_editor_screen.dart';
import 'features/notes/archived_notes_screen.dart';
import 'features/notes/trashed_notes_screen.dart';
import 'features/notes/models/note_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: FocusPadApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/', 
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NotesScreen(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) {
        final note = state.extra as Note?;
        return NoteEditorScreen(note: note);
      },
    ),
    GoRoute(
      path: '/archived',
      builder: (context, state) => const ArchivedNotesScreen(),
    ),
    GoRoute(
      path: '/trashed',
      builder: (context, state) => const TrashedNotesScreen(),
    ),
  ],
);

class FocusPadApp extends ConsumerWidget {
  const FocusPadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FocusPad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      
      // ✨ Localização Corrigida para a versão 11.5.0
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Removemos a constante daqui para evitar o erro de compilação
        ...FlutterQuillLocalizations.delegates, 
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
    );
  }
}