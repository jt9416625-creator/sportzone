/// Qué escribió el usuario en el campo principal de login/registro.
enum IdentifierKind { email, username, invalid, empty }

/// Validaciones con expresiones regulares (correo, usuario, contraseña).
class Validators {
  Validators._();

  /// Correo: algo@dominio.ext (ext de 2 letras o más).
  static final email = RegExp(r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  /// Usuario: 3 a 20 caracteres, empieza con letra; letras, números, _ y .
  static final username = RegExp(r'^[A-Za-z][A-Za-z0-9_.]{2,19}$');

  /// Decide si el texto es un correo o un nombre de usuario.
  /// La "@" es la que manda: si la tiene, se valida como correo.
  static IdentifierKind kindOf(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return IdentifierKind.empty;
    if (v.contains('@')) return email.hasMatch(v) ? IdentifierKind.email : IdentifierKind.invalid;
    return username.hasMatch(v) ? IdentifierKind.username : IdentifierKind.invalid;
  }

  /// Mensaje de error para el campo principal (null = válido).
  static String? identifier(String? raw) {
    final v = (raw ?? '').trim();
    switch (kindOf(v)) {
      case IdentifierKind.empty:
        return 'Escribe tu correo o tu nombre de usuario.';
      case IdentifierKind.invalid:
        return v.contains('@')
            ? 'Ese correo no es válido (ej: nombre@correo.com).'
            : 'Usuario: 3 a 20 caracteres, empieza con letra; solo letras, números, "_" y ".".';
      case IdentifierKind.email:
      case IdentifierKind.username:
        return null;
    }
  }

  static String? usernameField(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'Elige un nombre de usuario.';
    if (!username.hasMatch(v)) return '3 a 20 caracteres, empieza con letra; letras, números, "_" y ".".';
    return null;
  }

  static String? password(String? raw) {
    final v = raw ?? '';
    if (v.isEmpty) return 'Escribe tu contraseña.';
    if (v.length < 6) return 'Mínimo 6 caracteres.';
    return null;
  }
}
