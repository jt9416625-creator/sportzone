import 'package:flutter/foundation.dart';

import '../data/avatar_catalog.dart';
import '../models/user_models.dart';

/// Error que el backend devuelve con un mensaje listo para mostrar.
class BackendException implements Exception {
  final String message;
  const BackendException(this.message);
  @override
  String toString() => message;
}

/// Una acción hecha por un administrador (queda registrada).
class AdminLogEntry {
  final DateTime time;
  final String admin;
  final String targetUid;
  final String action;
  AdminLogEntry(this.admin, this.targetUid, this.action) : time = DateTime.now();
}

/// "Servidor" falso que vive en memoria mientras no hay base de datos.
///
/// Cada método público representa un endpoint. Cuando conectemos Firebase,
/// solo se cambia el cuerpo de estos métodos; las pantallas no se tocan.
///   loginWithEmail     -> FirebaseAuth.signInWithEmailAndPassword
///   loginWithUsername  -> leer `usernames/{username}` para obtener el correo
///                         (o el uid) y luego iniciar sesión
///   register           -> createUserWithEmailAndPassword + doc en `users/{uid}`
///   el resto           -> lecturas/escrituras en Firestore
///
/// OJO: al cerrar la app todo vuelve a los datos de ejemplo.
class LocalBackend extends ChangeNotifier {
  LocalBackend._() {
    _seed();
  }
  static final LocalBackend instance = LocalBackend._();

  final Map<String, AppUser> _users = {};
  final List<AdminLogEntry> log = [];

  /// Prendas apagadas por el admin para TODOS (id -> false).
  final Map<String, bool> _itemEnabled = {};

  int _nextId = 100;

  Future<void> _latency([int ms = 450]) => Future.delayed(Duration(milliseconds: ms));

  // ═════════════════════════ AUTENTICACIÓN ═════════════════════════

  /// Endpoint: POST /auth/login/email
  Future<AppUser> loginWithEmail(String email, String password) async {
    await _latency();
    final e = email.trim().toLowerCase();
    final u = _users.values.where((x) => x.email?.toLowerCase() == e).firstOrNull;
    return _checkLogin(u, password);
  }

  /// Endpoint: POST /auth/login/username
  Future<AppUser> loginWithUsername(String username, String password) async {
    await _latency();
    final u = _byUsername(username);
    return _checkLogin(u, password);
  }

  AppUser _checkLogin(AppUser? u, String password) {
    if (u == null || u.password != password) {
      throw const BackendException('Usuario o contraseña incorrectos.');
    }
    if (u.suspended) {
      throw BackendException('Tu cuenta está suspendida.'
          '${u.moderationNote != null ? ' Motivo: ${u.moderationNote}.' : ''} Escríbenos a soporte@sportzone.app.');
    }
    return u;
  }

  /// Endpoint: POST /auth/register
  Future<AppUser> register({required String username, String? email, required String password}) async {
    await _latency(600);
    final name = username.trim();
    if (_byUsername(name) != null || name.toLowerCase() == 'soporte') {
      throw const BackendException('Ese nombre de usuario ya está en uso.');
    }
    final mail = email?.trim().toLowerCase();
    if (mail != null && _users.values.any((x) => x.email?.toLowerCase() == mail)) {
      throw const BackendException('Ya existe una cuenta con ese correo.');
    }
    final u = AppUser(uid: 'u${_nextId++}', username: name, email: mail, password: password, xp: 0, streak: 0);
    _users[u.uid] = u;
    notifyListeners();
    return u;
  }

  /// Endpoint: POST /auth/reset-password (solo funciona con correo).
  Future<void> resetPassword(String email) async {
    await _latency(300);
  }

  /// Si escriben un usuario, devuelve su correo (para recuperar contraseña).
  String? emailForUsername(String username) => _byUsername(username)?.email;

  bool usernameTaken(String username) => _byUsername(username) != null;

  AppUser? _byUsername(String username) {
    final n = username.trim().toLowerCase();
    return _users.values.where((x) => x.username.toLowerCase() == n).firstOrNull;
  }

  /// Sugiere un usuario a partir del correo (juan.perez@x.com -> juan.perez).
  String suggestUsername(String email) {
    var base = email.split('@').first.replaceAll(RegExp(r'[^A-Za-z0-9_.]'), '');
    if (base.isEmpty || !RegExp(r'^[A-Za-z]').hasMatch(base)) base = 'fan$base';
    if (base.length < 3) base = '${base}_fan';
    if (base.length > 16) base = base.substring(0, 16);
    var candidate = base;
    var i = 2;
    while (usernameTaken(candidate)) {
      candidate = '$base$i';
      i++;
    }
    return candidate;
  }

  // ═════════════════════════ PERFIL / PROGRESO ═════════════════════════

  AppUser? userById(String uid) => _users[uid];

  List<AppUser> get allUsers => _users.values.toList()..sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

  /// El AppState llama esto cada vez que cambia el progreso del usuario.
  /// TODO(firebase): users/{uid}.update({...})
  void saveProgress(AppUser u) => notifyListeners();

  // ═════════════════════════ ADMIN: MODERACIÓN ═════════════════════════

  /// Endpoint: GET /admin/users?q=
  List<AppUser> searchUsers(String query) {
    final q = query.trim().toLowerCase().replaceFirst('@', '');
    if (q.isEmpty) return allUsers;
    return allUsers
        .where((u) => u.username.toLowerCase().contains(q) || (u.email ?? '').toLowerCase().contains(q) || u.uid == q)
        .toList();
  }

  void _audit(AppUser admin, AppUser target, String action) {
    log.insert(0, AdminLogEntry(admin.username, target.uid, action));
  }

  void _requireAdmin(AppUser admin) {
    if (!admin.isAdmin) throw const BackendException('Solo un administrador puede hacer esto.');
  }

  /// Endpoint: PATCH /admin/users/{uid}/streak
  void setStreak(AppUser admin, AppUser target, int value, {String reason = ''}) {
    _requireAdmin(admin);
    final old = target.streak;
    target.streak = value.clamp(0, 9999);
    if (target.streak > target.bestStreak) target.bestStreak = target.streak;
    if (target.streak >= target.lostStreak) target.lostStreak = 0;
    _audit(admin, target, 'Racha $old → ${target.streak}${reason.isEmpty ? '' : ' ($reason)'}');
    notifyListeners();
  }

  /// Devuelve la racha que el usuario perdió (si la perdió por un fallo).
  void restoreLostStreak(AppUser admin, AppUser target) {
    if (target.lostStreak <= 0) return;
    // +1 porque el día que volvió a entrar también cuenta.
    setStreak(admin, target, target.lostStreak + target.streak, reason: 'restaurada por fallo técnico');
  }

  /// Endpoint: PATCH /admin/users/{uid}/status
  void setSuspended(AppUser admin, AppUser target, bool value, {String? note}) {
    _requireAdmin(admin);
    if (target.uid == admin.uid) throw const BackendException('No puedes suspender tu propia cuenta.');
    target.suspended = value;
    target.moderationNote = value ? (note?.trim().isEmpty ?? true ? null : note!.trim()) : null;
    _audit(admin, target, value ? 'Cuenta suspendida${note == null || note.isEmpty ? '' : ': $note'}' : 'Cuenta reactivada');
    notifyListeners();
  }

  void setMuted(AppUser admin, AppUser target, bool value) {
    _requireAdmin(admin);
    target.muted = value;
    _audit(admin, target, value ? 'Silenciado en los chats' : 'Se le quitó el silencio');
    notifyListeners();
  }

  void setRole(AppUser admin, AppUser target, UserRole role) {
    _requireAdmin(admin);
    if (target.uid == admin.uid) throw const BackendException('No puedes cambiar tu propio rol.');
    target.role = role;
    _audit(admin, target, 'Rol cambiado a ${role.label}');
    notifyListeners();
  }

  // ═════════════════════════ AVATARES / INVENTARIO ═════════════════════════

  bool itemEnabled(String itemId) => _itemEnabled[itemId] ?? true;

  /// Endpoint: PATCH /admin/catalog/{item}
  void setItemEnabled(AppUser admin, String itemId, bool enabled) {
    _requireAdmin(admin);
    _itemEnabled[itemId] = enabled;
    if (!enabled) {
      // Se la quita a quien la tenga puesta.
      for (final u in _users.values) {
        u.equipped.removeWhere((_, v) => v == itemId);
        u.equipped.putIfAbsent(AvatarSlot.body, () => 'body_medium');
      }
    }
    notifyListeners();
  }

  /// Endpoint: POST /admin/users/{uid}/inventory
  void giftItem(AppUser admin, AppUser target, String itemId) {
    _requireAdmin(admin);
    target.inventory.add(itemId);
    target.blockedItems.remove(itemId);
    _audit(admin, target, 'Regalo: ${avatarItemById(itemId)?.name ?? itemId}');
    notifyListeners();
  }

  /// Quita una prenda del inventario y se la bloquea a ese usuario.
  void blockItemForUser(AppUser admin, AppUser target, String itemId) {
    _requireAdmin(admin);
    target.inventory.remove(itemId);
    target.blockedItems.add(itemId);
    target.equipped.removeWhere((slot, v) => v == itemId && slot != AvatarSlot.body);
    _audit(admin, target, 'Bloqueada: ${avatarItemById(itemId)?.name ?? itemId}');
    notifyListeners();
  }

  void unblockItemForUser(AppUser admin, AppUser target, String itemId) {
    _requireAdmin(admin);
    target.blockedItems.remove(itemId);
    _audit(admin, target, 'Desbloqueada: ${avatarItemById(itemId)?.name ?? itemId}');
    notifyListeners();
  }

  /// ¿Este usuario puede ponerse esta prenda? Devuelve el motivo si no.
  String? whyLocked(AppUser u, AvatarItem item) {
    if (!itemEnabled(item.id)) return 'Desactivada por el administrador';
    if (u.blockedItems.contains(item.id)) return 'Bloqueada para tu cuenta';
    if (item.exclusive && !u.inventory.contains(item.id)) return 'Exclusiva: solo por regalo o evento';
    return null;
  }

  /// Endpoint: PATCH /users/{uid}/avatar
  void equip(AppUser u, AvatarItem item) {
    final why = whyLocked(u, item);
    if (why != null) throw BackendException(why);
    u.equipped[item.slot] = item.id;
    notifyListeners();
  }

  /// Endpoint: PATCH /users/{uid}/avatar (merch oficial de un club).
  void equipMerch(AppUser u, AvatarSlot slot, String merchId) {
    u.equipped[slot] = merchId;
    notifyListeners();
  }

  void unequip(AppUser u, AvatarSlot slot) {
    if (!slot.removable) return;
    u.equipped.remove(slot);
    notifyListeners();
  }

  // ═════════════════════════ DATOS DE EJEMPLO ═════════════════════════

  void _seed() {
    final today = DateTime.now();
    DateTime daysAgo(int d) => DateTime(today.year, today.month, today.day - d, 20);
    const exclusives = ['head_crown', 'top_fb_gold', 'top_nba_allstar', 'hand_tn_gold_racket', 'waist_ufc_belt', 'neck_medal_gold'];

    for (final u in [
      AppUser(
        uid: 'u_admin',
        username: 'admin',
        email: 'admin@sportzone.app',
        password: 'admin123',
        role: UserRole.admin,
        xp: 2400,
        streak: 30,
        bestStreak: 45,
        lastCheckIn: daysAgo(1),
        onboardingDone: true,
        unlocked: {'fan', 'streak3', 'streak7', 'streak14', 'legend'},
        equipped: {AvatarSlot.body: 'body_medium', AvatarSlot.hair: 'hair_short_black', AvatarSlot.face: 'face_stubble', AvatarSlot.top: 'top_fb_gold', AvatarSlot.bottom: 'bottom_fb_black', AvatarSlot.head: 'head_crown'},
        inventory: exclusives.toSet(),
      ),
      AppUser(
        uid: 'u_hincha',
        username: 'hincha',
        email: 'hincha@sportzone.app',
        password: '123456',
        xp: 120,
        streak: 2,
        bestStreak: 2,
        lastCheckIn: daysAgo(1),
        equipped: {AvatarSlot.body: 'body_light', AvatarSlot.hair: 'hair_short_brown', AvatarSlot.top: 'top_fb_red', AvatarSlot.bottom: 'bottom_fb_white'},
      ),
      AppUser(
        uid: 'u_camilo',
        username: 'Camilo_10',
        email: 'camilo10@correo.com',
        password: '123456',
        xp: 860,
        streak: 1,
        bestStreak: 23,
        lostStreak: 23, // la perdió por un cierre de la app
        lastCheckIn: daysAgo(0),
        onboardingDone: true,
        equipped: {AvatarSlot.body: 'body_dark', AvatarSlot.hair: 'hair_afro', AvatarSlot.top: 'top_nba_purple', AvatarSlot.bottom: 'bottom_nba_purple'},
      ),
      AppUser(
        uid: 'u_sofi',
        username: 'Sofi.Futbol',
        email: 'sofi@correo.com',
        password: '123456',
        xp: 1320,
        streak: 12,
        bestStreak: 12,
        lastCheckIn: daysAgo(1),
        onboardingDone: true,
        inventory: {'top_fb_gold'},
        equipped: {AvatarSlot.body: 'body_pale', AvatarSlot.hair: 'hair_long_blond', AvatarSlot.face: 'face_paint', AvatarSlot.top: 'top_fb_gold', AvatarSlot.bottom: 'bottom_tn_skirt'},
      ),
      AppUser(
        uid: 'u_dani',
        username: 'Dani77',
        password: '123456', // se registró solo con usuario, sin correo
        xp: 300,
        streak: 0,
        bestStreak: 5,
        lostStreak: 5,
        lastCheckIn: daysAgo(4),
        onboardingDone: true,
        equipped: {AvatarSlot.body: 'body_tan', AvatarSlot.tattoo: 'tattoo_full', AvatarSlot.hair: 'hair_mohawk', AvatarSlot.face: 'face_beard_black', AvatarSlot.bottom: 'bottom_ufc_black', AvatarSlot.hand: 'hand_ufc_gloves'},
      ),
      AppUser(
        uid: 'u_gol',
        username: 'GolDeLeyenda',
        email: 'gol@correo.com',
        password: '123456',
        xp: 90,
        streak: 3,
        suspended: true,
        moderationNote: 'Spam en los chats de partidos',
        onboardingDone: true,
      ),
    ]) {
      _users[u.uid] = u;
    }
  }
}

final backend = LocalBackend.instance;
