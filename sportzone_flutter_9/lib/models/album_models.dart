import 'package:flutter/material.dart';

import 'models.dart';

// ═════════════════════════ LÁMINAS ═════════════════════════

enum StickerRarity { common, rare, epic, legendary }

extension StickerRarityX on StickerRarity {
  String get label => switch (this) {
        StickerRarity.common => 'Común',
        StickerRarity.rare => 'Rara',
        StickerRarity.epic => 'Épica',
        StickerRarity.legendary => 'Leyenda',
      };

  /// Probabilidad de salir en cada lámina de un sobre (suman 100).
  int get weight => switch (this) {
        StickerRarity.common => 68,
        StickerRarity.rare => 23,
        StickerRarity.epic => 7,
        StickerRarity.legendary => 2,
      };

  List<Color> get frame => switch (this) {
        StickerRarity.common => const [Color(0xFFE8ECF2), Color(0xFFBFC7D3)],
        StickerRarity.rare => const [Color(0xFF7FC8FF), Color(0xFF2D6CDF)],
        StickerRarity.epic => const [Color(0xFFD59CFF), Color(0xFF7B2FF7)],
        StickerRarity.legendary => const [Color(0xFFFFE680), Color(0xFFE0A100)],
      };

  Color get color => frame.last;
}

/// Lámina del álbum. `kind` = jugador/peleador o escudo de club.
enum StickerKind { player, club }

class Sticker {
  final String id; // 's01'
  final int number;
  final String name;
  final String country; // '🇫🇷 Francia'
  final String role; // 'Delantero', 'Peso ligero', 'ATP'...
  final Sport sport;
  final int page;
  final StickerRarity rarity;
  final StickerKind kind;
  final String? teamId; // para las láminas de club (escudo en vivo)
  final Color color;
  final String? wiki; // título en Wikipedia si el nombre es ambiguo

  const Sticker({
    required this.id,
    required this.number,
    required this.name,
    required this.country,
    required this.role,
    required this.sport,
    required this.page,
    required this.rarity,
    required this.color,
    this.kind = StickerKind.player,
    this.teamId,
    this.wiki,
  });
}

class AlbumPage {
  final int index;
  final String title;
  final String subtitle;
  final Sport? sport;
  final Color color;
  const AlbumPage(this.index, this.title, this.subtitle, this.sport, this.color);
}

// ═════════════════════════ MISIONES ═════════════════════════

enum MissionPeriod { daily, weekly }

/// Qué acción de la app hace avanzar la misión.
enum MissionEvent { readNews, checkIn, vote, openMatch, avatar, follow, newSticker, openPack }

class Mission {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final MissionEvent event;
  final int target;
  final MissionPeriod period;
  final int packs; // sobres de premio
  final int xp;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.event,
    required this.target,
    required this.period,
    this.packs = 1,
    this.xp = 0,
  });
}

/// Colección y misiones de un usuario (vive dentro de AppUser).
/// TODO(firebase): documento `users/{uid}/album/state`.
class AlbumState {
  final Map<String, int> owned = {}; // id lámina -> cantidad (1 = sin repetidas)
  final Set<String> fresh = {}; // recién conseguidas (brillan hasta verlas)
  int packs = 3; // sobres sin abrir (3 de bienvenida)
  int packsFromMissionsToday = 0;
  int packsSinceRare = 0; // para la garantía de rareza
  final Map<String, int> progress = {}; // id misión -> avance
  final Set<String> claimed = {}; // misiones reclamadas en el periodo
  final Set<String> seenToday = {}; // noticias/partidos ya contados hoy
  String dayKey = '';
  String weekKey = '';
  final Set<int> pagesRewarded = {};
  bool albumRewarded = false;

  /// Deja el álbum como nuevo (también lo puede usar soporte).
  void reset() {
    owned.clear();
    fresh.clear();
    progress.clear();
    claimed.clear();
    seenToday.clear();
    pagesRewarded.clear();
    packs = 3;
    packsFromMissionsToday = 0;
    packsSinceRare = 0;
    albumRewarded = false;
    dayKey = '';
    weekKey = '';
  }

  int countOf(String id) => owned[id] ?? 0;
  bool has(String id) => countOf(id) > 0;
  int get duplicates => owned.values.fold(0, (a, b) => a + (b > 1 ? b - 1 : 0));
}
