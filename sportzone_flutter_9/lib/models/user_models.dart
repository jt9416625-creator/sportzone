import 'package:flutter/material.dart';

import 'album_models.dart';
import 'models.dart';

// ═════════════════════════ USUARIOS Y ROLES ═════════════════════════

enum UserRole { user, admin }

extension UserRoleX on UserRole {
  String get label => this == UserRole.admin ? 'Administrador' : 'Usuario';
}

/// Usuario de SportZone. Por ahora vive en memoria (LocalBackend).
/// TODO(firebase): este objeto será un documento en `users/{uid}`.
class AppUser {
  final String uid;
  String username;
  String? email;
  String password; // solo en el backend falso; Firebase nunca la guarda así
  UserRole role;
  final DateTime createdAt;

  // ── Moderación ──
  bool suspended;
  bool muted; // no puede escribir en los chats de partidos
  String? moderationNote;

  // ── Gamificación ──
  int xp;
  int streak;
  int bestStreak;
  int lostStreak; // racha que tenía antes de perderla (para que el admin la restaure)
  DateTime? lastCheckIn;
  final Set<String> unlocked;
  final Set<String> favorites;
  final Map<String, String> votes;
  bool onboardingDone;

  // ── Avatar ──
  final Map<AvatarSlot, String> equipped;
  final Set<String> inventory; // prendas exclusivas que el usuario tiene
  final Set<String> blockedItems; // prendas que el admin le bloqueó a este usuario

  // ── Álbum SportZone ──
  final AlbumState album = AlbumState();

  AppUser({
    required this.uid,
    required this.username,
    this.email,
    required this.password,
    this.role = UserRole.user,
    DateTime? createdAt,
    this.suspended = false,
    this.muted = false,
    this.moderationNote,
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lostStreak = 0,
    this.lastCheckIn,
    Set<String>? unlocked,
    Set<String>? favorites,
    Map<String, String>? votes,
    this.onboardingDone = false,
    Map<AvatarSlot, String>? equipped,
    Set<String>? inventory,
    Set<String>? blockedItems,
  })  : createdAt = createdAt ?? DateTime.now(),
        unlocked = unlocked ?? {'fan'},
        favorites = favorites ?? {},
        votes = votes ?? {},
        equipped = equipped ?? {AvatarSlot.body: 'body_medium', AvatarSlot.hair: 'hair_short_brown', AvatarSlot.top: 'top_basic_white'},
        inventory = inventory ?? {},
        blockedItems = blockedItems ?? {};

  bool get isAdmin => role == UserRole.admin;
  String get handle => '@$username';
}

// ═════════════════════════ SOPORTE TÉCNICO ═════════════════════════

enum TicketStatus { open, resolved }

class TicketMessage {
  final String id;
  final String text;
  final bool fromSupport; // true = lo escribió soporte (admin o bot)
  final String author;
  final DateTime time;

  TicketMessage({
    required this.id,
    required this.text,
    required this.fromSupport,
    required this.author,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

/// Una conversación de soporte (ticket).
class SupportTicket {
  final String id;
  final String userId;
  final String username;
  final DateTime createdAt;
  final List<TicketMessage> messages;
  TicketStatus status;
  DateTime updatedAt;
  bool unreadByAdmin;
  bool unreadByUser;
  DateTime? seenByAdminAt; // para el "Visto" estilo Messenger
  DateTime? seenByUserAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.username,
    DateTime? createdAt,
    List<TicketMessage>? messages,
    this.status = TicketStatus.open,
    this.unreadByAdmin = false,
    this.unreadByUser = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  String get subject {
    final first = messages.where((m) => !m.fromSupport).firstOrNull;
    if (first == null) return 'Sin mensajes';
    return first.text.length > 60 ? '${first.text.substring(0, 60)}…' : first.text;
  }

  TicketMessage? get last => messages.isEmpty ? null : messages.last;
}

// ═════════════════════════ AVATARES ═════════════════════════

/// Capas del avatar, en el orden en que se apilan (de atrás hacia adelante).
enum AvatarSlot { body, tattoo, hair, bottom, top, waist, neck, face, head, hand }

extension AvatarSlotX on AvatarSlot {
  String get label => switch (this) {
        AvatarSlot.body => 'Cuerpo',
        AvatarSlot.tattoo => 'Tatuaje',
        AvatarSlot.hair => 'Cabello',
        AvatarSlot.bottom => 'Prenda inferior',
        AvatarSlot.top => 'Prenda superior',
        AvatarSlot.waist => 'Cintura',
        AvatarSlot.neck => 'Cuello',
        AvatarSlot.face => 'Cara',
        AvatarSlot.head => 'Cabeza',
        AvatarSlot.hand => 'Manos',
      };

  /// El cuerpo siempre tiene que estar; lo demás se puede quitar.
  bool get removable => this != AvatarSlot.body;
}

/// Categorías del catálogo (pestañas de abajo).
enum AvatarCategory { base, football, nba, tennis, ufc }

extension AvatarCategoryX on AvatarCategory {
  String get label => switch (this) {
        AvatarCategory.base => 'Base',
        AvatarCategory.football => 'Fútbol',
        AvatarCategory.nba => 'NBA',
        AvatarCategory.tennis => 'Tenis',
        AvatarCategory.ufc => 'UFC',
      };

  IconData get icon => switch (this) {
        AvatarCategory.base => Icons.accessibility_new,
        AvatarCategory.football => Icons.sports_soccer,
        AvatarCategory.nba => Icons.sports_basketball,
        AvatarCategory.tennis => Icons.sports_tennis,
        AvatarCategory.ufc => Icons.sports_mma,
      };
}

class AvatarItem {
  final String id;
  final String name;
  final AvatarSlot slot;
  final AvatarCategory category;
  final bool exclusive; // solo si está en el inventario del usuario

  const AvatarItem(this.id, this.name, this.slot, this.category, {this.exclusive = false});

  /// PNG transparente de la capa completa (400 x 560).
  String get asset => 'assets/avatar/$id.png';

  /// Recorte para la cuadrícula del catálogo.
  String get thumb => 'assets/avatar/thumbs/$id.png';
}

// ═════════════════════════ CONTENIDO DE EMERGENCIA ═════════════════════════

/// Fila de tabla escrita a mano por un administrador.
class ManualStanding {
  final String leagueKey;
  final List<StandingRow> rows;
  final DateTime updatedAt;
  final String author;

  ManualStanding(this.leagueKey, this.rows, this.author) : updatedAt = DateTime.now();
}

/// Noticia publicada a mano.
class ManualNews {
  final NewsItem item;
  final DateTime publishedAt;
  final String author;
  bool pinned;

  ManualNews(this.item, this.author, {this.pinned = true}) : publishedAt = DateTime.now();
}
