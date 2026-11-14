
import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../services/auth_service.dart';
import '../services/local_backend.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _usernameTouched = false;

  IdentifierKind _kind = IdentifierKind.empty;

  void _onIdChanged(String value) {
    final kind = Validators.kindOf(value);

    setState(() {
      _kind = kind;
    });

    if (kind == IdentifierKind.email && !_usernameTouched) {
      _username.text = backend.suggestUsername(value.trim());
    }
  }

  String? _usernameAvailable(String? value) {
    return Validators.usernameField(value);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await AuthService().register(
        identifier: _id.text,
        username: _username.text,
        password: _password.text,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on BackendException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('No se pudo crear la cuenta. Inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _id.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFFB7F34A);

    final isEmail = _kind == IdentifierKind.email;

    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFF10131A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Únete a SportZone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Regístrate con tu correo electrónico y elige un nombre de usuario.',
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _id,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final error = Validators.identifier(value);

                  if (error != null) return error;

                  if (Validators.kindOf(value!) != IdentifierKind.email) {
                    return 'Para crear una cuenta debes ingresar un correo electrónico.';
                  }

                  return null;
                },
                onChanged: _onIdChanged,
                style: const TextStyle(color: Colors.white),
                decoration: authDecoration(
                  'Correo electrónico',
                  Icons.email_outlined,
                  helper: 'Utilizarás este correo para iniciar sesión y recuperar tu contraseña.',
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: isEmail
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: _username,
                          autocorrect: false,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                          validator: _usernameAvailable,
                          onChanged: (_) {
                            _usernameTouched = true;
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: authDecoration(
                            'Nombre de usuario',
                            Icons.alternate_email,
                            helper: 'Así te verán en la racha y en los chats.',
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _password,
                obscureText: true,
                validator: Validators.password,
                style: const TextStyle(color: Colors.white),
                decoration: authDecoration(
                  'Contraseña',
                  Icons.lock_outline,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPassword,
                obscureText: true,
                validator: (value) {
                  if (value != _password.text) {
                    return 'Las contraseñas no coinciden.';
                  }

                  return null;
                },
                style: const TextStyle(color: Colors.white),
                decoration: authDecoration(
                  'Confirmar contraseña',
                  Icons.lock_outline,
                ),
              ),

              const SizedBox(height: 28),

              FilledButton(
                onPressed: _loading ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: const Color(0xFF10131A),
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
                        'CREAR CUENTA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estilo de los campos del formulario de registro.
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
