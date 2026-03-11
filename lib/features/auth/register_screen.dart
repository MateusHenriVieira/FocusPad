import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.', style: TextStyle(color: AppTheme.zinc50)), backgroundColor: AppTheme.zinc900),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.', style: TextStyle(color: AppTheme.zinc50)), backgroundColor: AppTheme.zinc900),
      );
      return;
    }

    // Chama o Riverpod para registrar de verdade
    final success = await ref.read(authControllerProvider.notifier).register(name, email, password);

    if (mounted) {
      if (success) {
        context.go('/notes');
      } else {
        final error = ref.read(authControllerProvider).error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error, style: const TextStyle(color: AppTheme.zinc50)), backgroundColor: AppTheme.zinc900),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Criar Conta',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.zinc50,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comece a organizar suas anotações com segurança.',
                    style: TextStyle(fontSize: 16, color: AppTheme.zinc400),
                  ),
                  const SizedBox(height: 40),

                  // Nome
                  const Text('Nome', style: TextStyle(color: AppTheme.zinc400, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.zinc50),
                    decoration: const InputDecoration(
                      hintText: 'Seu nome completo',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.zinc400),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  const Text('Email', style: TextStyle(color: AppTheme.zinc400, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.zinc50),
                    decoration: const InputDecoration(
                      hintText: 'exemplo@corporativo.com',
                      prefixIcon: Icon(Icons.mail_outline, color: AppTheme.zinc400),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Senha
                  const Text('Senha', style: TextStyle(color: AppTheme.zinc400, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.zinc50),
                    decoration: const InputDecoration(
                      hintText: 'Mínimo de 8 caracteres',
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.zinc400),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirmar Senha
                  const Text('Confirmar Senha', style: TextStyle(color: AppTheme.zinc400, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                    style: const TextStyle(color: AppTheme.zinc50),
                    decoration: const InputDecoration(
                      hintText: 'Repita sua senha',
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.zinc400),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botão de Cadastro
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.zinc50,
                        foregroundColor: AppTheme.zinc950,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: AppTheme.zinc950)
                          : const Text('Cadastrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}