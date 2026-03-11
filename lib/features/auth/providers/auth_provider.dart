import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

// 1. Provedor estático do serviço
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 1. Provedor estático do serviço de banco de dados
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// 2. Controlador de Ações (Login e Registro)
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signIn(email, password);
      state = const AsyncValue.data(null);
      return true; // Sucesso
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_translateAuthError(e.code), StackTrace.current);
      return false; // Falha
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // 1. Cria a conta no Firebase Auth
      final credential = await ref.read(authServiceProvider).signUp(email, password);
      final user = credential.user;

      if (user != null) {
        // 2. Salva o nome no Auth
        await user.updateDisplayName(name);
        
        // 3. Cria o perfil no Realtime Database com a role 'USER'
        await ref.read(databaseServiceProvider).createUserProfile(
          uid: user.uid,
          name: name,
          email: email,
        );
      }
      
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_translateAuthError(e.code), StackTrace.current);
      return false;
    } catch (e) {
      // Captura erros do Realtime Database (ex: falta de permissão)
      state = AsyncValue.error('Erro ao salvar perfil: $e', StackTrace.current);
      return false;
    }
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'O formato do email é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada pelo administrador.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Credenciais incorretas.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está cadastrado no sistema.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      default:
        return 'Erro na autenticação. Tente novamente.';
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(() {
  return AuthController();
});