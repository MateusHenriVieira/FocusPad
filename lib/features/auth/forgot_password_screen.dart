import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Verificar se o usuário existe e quem o criou
      // Nota: Para segurança real, o ideal é fazer isso via Cloud Function, 
      // mas faremos via busca por e-mail no DB para seguir seu fluxo.
      final snapshot = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('email')
          .equalTo(email)
          .get();

      if (snapshot.exists) {
        final userData = (snapshot.value as Map).values.first;
        final createdBy = userData['createdBy'] ?? 'self';

        if (createdBy == 'admin') {
          if (mounted) {
            _showError('Esta conta foi gerada pelo gestor. Solicite a alteração de senha diretamente no painel administrativo.');
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Se for "self" ou não encontrado (padrão Firebase), envia o e-mail
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail de redefinição enviado com sucesso!')),
        );
        context.pop();
      }
    } catch (e) {
      _showError('Erro ao processar solicitação. Verifique o e-mail digitado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.zinc900,
        title: const Text('Atenção', style: TextStyle(color: AppTheme.zinc50)),
        content: Text(message, style: const TextStyle(color: AppTheme.zinc400)),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK', style: TextStyle(color: AppTheme.zinc50))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      appBar: AppBar(backgroundColor: AppTheme.zinc950, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recuperar Senha', style: TextStyle(color: AppTheme.zinc50, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Insira seu e-mail abaixo. Se sua conta for pessoal, enviaremos um link de redefinição.',
              style: TextStyle(color: AppTheme.zinc400, fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: AppTheme.zinc50),
              decoration: InputDecoration(
                labelText: 'E-mail',
                labelStyle: const TextStyle(color: AppTheme.zinc400),
                filled: true,
                fillColor: AppTheme.zinc900,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.zinc50,
                  foregroundColor: AppTheme.zinc950,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: AppTheme.zinc950) 
                  : const Text('Enviar Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}