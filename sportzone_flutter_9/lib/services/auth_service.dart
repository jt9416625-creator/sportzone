
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/validators.dart';
import '../models/user_models.dart';
import 'local_backend.dart';

class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();

  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _cachedUser;

  AppUser? get currentUser => _cachedUser;

  /// Escucha los cambios de sesión y obtiene el perfil desde Firestore.
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }

      final doc = await _db
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        final user = AppUser(
          uid: firebaseUser.uid,
          username: firebaseUser.email?.split('@').first ?? 'usuario',
          email: firebaseUser.email,
          password: '',
        );

        _cachedUser = user;
        return user;
      }

      final user = _userFromData(firebaseUser.uid, doc.data()!);
      _cachedUser = user;
      return user;
    });
  }

  /// Inicia sesión con correo electrónico o nombre de usuario.
  Future<AppUser> login(String identifier, String password) async {
    final id = identifier.trim();
    final kind = Validators.kindOf(id);

    String email;

    if (kind == IdentifierKind.email) {
      email = id;
    } else if (kind == IdentifierKind.username) {
      final usernameDoc = await _db
          .collection('usernames')
          .doc(id.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        throw const BackendException(
          'Usuario o contraseña incorrectos.',
        );
      }

      email = usernameDoc.data()?['email'] as String? ?? '';

      if (email.isEmpty) {
        throw const BackendException(
          'No se encontró el correo de esta cuenta.',
        );
      }
    } else {
      throw const BackendException(
        'Escribe un correo o nombre de usuario válido.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const BackendException(
          'No se pudo iniciar sesión.',
        );
      }

      final doc = await _db
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        throw const BackendException(
          'No se encontró el perfil de usuario.',
        );
      }

      final appUser = _userFromData(
        firebaseUser.uid,
        doc.data()!,
      );

      if (appUser.suspended) {
        await _auth.signOut();

        throw BackendException(
          'Tu cuenta está suspendida.'
          '${appUser.moderationNote != null ? ' Motivo: ${appUser.moderationNote}.' : ''}'
          ' Escríbenos a soporte@sportzone.app.',
        );
      }

      _cachedUser = appUser;
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw BackendException(_authError(e));
    }
  }

  /// Registra una cuenta con correo, nombre de usuario y contraseña.
  Future<AppUser> register({
    required String identifier,
    String? username,
    required String password,
  }) async {
    final email = identifier.trim().toLowerCase();
    final name = (username ?? '').trim();

    if (Validators.kindOf(email) != IdentifierKind.email) {
      throw const BackendException(
        'Debes registrarte con un correo electrónico.',
      );
    }

    final nameError = Validators.usernameField(name);

    if (nameError != null) {
      throw BackendException(nameError);
    }

    final passwordError = Validators.password(password);

    if (passwordError != null) {
      throw BackendException(passwordError);
    }

    final usernameKey = name.toLowerCase();

    if (usernameKey == 'soporte') {
      throw const BackendException(
        'Ese nombre de usuario ya está en uso.',
      );
    }

    final usernameRef = _db
        .collection('usernames')
        .doc(usernameKey);

    final existingUsername = await usernameRef.get();

    if (existingUsername.exists) {
      throw const BackendException(
        'Ese nombre de usuario ya está en uso.',
      );
    }

    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw BackendException(_authError(e));
    }

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw const BackendException(
        'No se pudo crear la cuenta.',
      );
    }

    final appUser = AppUser(
      uid: firebaseUser.uid,
      username: name,
      email: email,
      password: '',
    );

    try {
      final batch = _db.batch();

      batch.set(
        _db.collection('users').doc(firebaseUser.uid),
        _userToData(appUser),
      );

      batch.set(usernameRef, {
        'uid': firebaseUser.uid,
        'email': email,
        'username': name,
      });

      await batch.commit();

      _cachedUser = appUser;
      return appUser;
    } catch (_) {
      await firebaseUser.delete();

      throw const BackendException(
        'La cuenta se creó, pero no se pudo guardar el perfil. '
        'Inténtalo de nuevo.',
      );
    }
  }

  /// Cierra la sesión actual.
  Future<void> logout() async {
    await _auth.signOut();
    _cachedUser = null;
  }

  /// Envía un correo para recuperar la contraseña.
  Future<bool> resetPassword(String identifier) async {
    final id = identifier.trim();
    final kind = Validators.kindOf(id);

    String? email;

    if (kind == IdentifierKind.email) {
      email = id;
    } else if (kind == IdentifierKind.username) {
      final doc = await _db
          .collection('usernames')
          .doc(id.toLowerCase())
          .get();

      email = doc.data()?['email'] as String?;
    }

    if (email == null || email.isEmpty) {
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      throw BackendException(_authError(e));
    }
  }

  /// Convierte el perfil del usuario en datos para Firestore.
  Map<String, dynamic> _userToData(AppUser user) {
    return {
      'uid': user.uid,
      'username': user.username,
      'email': user.email,
      'role': user.role.name,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'suspended': user.suspended,
      'muted': user.muted,
      'moderationNote': user.moderationNote,
      'xp': user.xp,
      'streak': user.streak,
      'bestStreak': user.bestStreak,
      'lostStreak': user.lostStreak,
      'lastCheckIn': user.lastCheckIn == null
          ? null
          : Timestamp.fromDate(user.lastCheckIn!),
      'unlocked': user.unlocked.toList(),
      'favorites': user.favorites.toList(),
      'votes': user.votes,
      'onboardingDone': user.onboardingDone,
      'equipped': {
        for (final entry in user.equipped.entries)
          entry.key.name: entry.value,
      },
      'inventory': user.inventory.toList(),
      'blockedItems': user.blockedItems.toList(),
    };
  }

  /// Reconstruye el usuario a partir de los datos de Firestore.
  AppUser _userFromData(String uid, Map<String, dynamic> data) {
    final equippedData = Map<String, dynamic>.from(
      data['equipped'] ?? {},
    );

    final votesData = Map<String, dynamic>.from(
      data['votes'] ?? {},
    );

    final lastCheckIn = data['lastCheckIn'];

    return AppUser(
      uid: uid,
      username: data['username'] as String? ?? 'usuario',
      email: data['email'] as String?,
      password: '',
      role: data['role'] == 'admin'
          ? UserRole.admin
          : UserRole.user,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      suspended: data['suspended'] as bool? ?? false,
      muted: data['muted'] as bool? ?? false,
      moderationNote: data['moderationNote'] as String?,
      xp: data['xp'] as int? ?? 0,
      streak: data['streak'] as int? ?? 0,
      bestStreak: data['bestStreak'] as int? ?? 0,
      lostStreak: data['lostStreak'] as int? ?? 0,
      lastCheckIn: lastCheckIn is Timestamp
          ? lastCheckIn.toDate()
          : null,
      unlocked: Set<String>.from(data['unlocked'] ?? ['fan']),
      favorites: Set<String>.from(data['favorites'] ?? []),
      votes: votesData.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      onboardingDone: data['onboardingDone'] as bool? ?? false,
      equipped: {
        for (final entry in equippedData.entries)
          if (AvatarSlot.values.any(
            (slot) => slot.name == entry.key,
          ))
            AvatarSlot.values.firstWhere(
              (slot) => slot.name == entry.key,
            ): entry.value.toString(),
      },
      inventory: Set<String>.from(data['inventory'] ?? []),
      blockedItems: Set<String>.from(data['blockedItems'] ?? []),
    );
  }

  /// Traduce los errores de Firebase a mensajes comprensibles.
  String _authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Usuario o contraseña incorrectos.';

      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';

      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'weak-password':
        return 'La contraseña es demasiado débil.';

      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';

      case 'network-request-failed':
        return 'No hay conexión a internet. Revisa tu conexión.';

      default:
        return 'No se pudo completar la operación. Inténtalo de nuevo.';
    }
  }
}
