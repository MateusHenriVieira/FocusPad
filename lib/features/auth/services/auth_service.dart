import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Permite saber se o usuário está logado ou não a qualquer momento
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Retorna o usuário logado no momento
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(), 
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), 
      password: password,
    );

    // ✨ IMPORTANTE: Ao registrar-se sozinho, marcamos como 'self'
    // para permitir a recuperação de senha futura.
    if (credential.user != null) {
      await _db.ref('users/${credential.user!.uid}').update({
        'email': email.trim(),
        'createdBy': 'self',
        'createdAt': ServerValue.timestamp,
      });
    }

    return credential;
  }

  // ✨ NOVO: Método para enviar e-mail de recuperação
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}