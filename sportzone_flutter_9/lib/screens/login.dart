
import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../services/auth_service.dart';
import '../services/local_backend.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  IdentifierKind _kind = IdentifierKind.empty;

  static const green = Color(0xFFB7F34A);
  static const background = Color(0xFF10131A);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await AuthService().login(
        _idController.text,
        _passwordController.text,
      );
    } on BackendException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('No se pudo iniciar sesión. Inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final id = _idController.text.trim();

    if (Validators.identifier(id) != null) {
      _message(
        'Escribe tu correo o tu usuario para recuperar la contraseña.',
      );
      return;
    }

    try {
      final hasEmail = await AuthService().resetPassword(id);

      if (hasEmail || _kind == IdentifierKind.email) {
        _message(
          'Si la cuenta existe, enviamos las instrucciones al correo registrado.',
        );
      } else {
        _message(
          'Esa cuenta no tiene correo asociado. Escríbenos a soporte desde otra cuenta o crea un ticket.',
        );
      }
    } on BackendException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('No se pudo procesar la solicitud.');
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 76,
                    color: green,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'SPORTZONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: green,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Todo el deporte en un solo lugar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                    validator: Validators.identifier,
                    onChanged: (value) {
                      setState(() {
                        _kind = Validators.kindOf(value);
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: authDecoration(
                      'Correo o nombre de usuario',
                      _kind == IdentifierKind.username
                          ? Icons.alternate_email
                          : Icons.email_outlined,
                    ).copyWith(
                      suffixIcon: IdentifierChip(kind: _kind),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _login(),
                    style: const TextStyle(color: Colors.white),
                    decoration: authDecoration(
                      'Contraseña',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: green),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: background,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate',
                      style: TextStyle(color: Colors.white),
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

/// Muestra si se ha escrito un correo o un nombre de usuario.
class IdentifierChip extends StatelessWidget {
  final IdentifierKind kind;

  const IdentifierChip({
    super.key,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final (String? label, Color color) = switch (kind) {
      IdentifierKind.email => (
          'Correo',
          const Color(0xFF4DA3FF),
        ),
      IdentifierKind.username => (
          'Usuario',
          const Color(0xFFB7F34A),
        ),
      IdentifierKind.invalid => (
          'Revisa',
          const Color(0xFFFF5C5C),
        ),
      IdentifierKind.empty => (
          null,
          Colors.transparent,
        ),
    };

    if (label == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Center(
        widthFactor: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Estilo compartido de los campos de autenticación.
InputDecoration authDecoration(
  String label,
  IconData icon, {
  String? helper,
}) {
  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperStyle: const TextStyle(color: Colors.white54),
    labelStyle: const TextStyle(color: Colors.white60),
    prefixIcon: Icon(icon, color: Colors.white60),
    filled: true,
    fillColor: const Color(0xFF1B202A),
    errorMaxLines: 3,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}
