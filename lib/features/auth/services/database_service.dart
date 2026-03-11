import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Cria o perfil do usuário na primeira vez que ele se cadastra
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final userRef = _db.ref().child('users').child(uid);
    
    await userRef.set({
      'name': name,
      'email': email,
      'role': 'USER', // Padrão: Apenas acesso ao bloco de notas
      'createdAt': ServerValue.timestamp,
    });
  }

  // Busca o nível de acesso do usuário (Usaremos isso no gatilho do Chat)
  Future<String> getUserRole(String uid) async {
    final snapshot = await _db.ref().child('users').child(uid).child('role').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return 'USER'; // Fallback de segurança
  }
}