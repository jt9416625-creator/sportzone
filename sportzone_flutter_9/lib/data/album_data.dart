import 'package:flutter/material.dart';

import '../models/album_models.dart';
import '../models/models.dart';

// Álbum SportZone: portada + 9 páginas, 62 láminas.
// Las láminas muestran país y posición (no el club) para que no queden
// desactualizadas con los fichajes. Las fotos se buscan en vivo (TheSportsDB).

const albumPages = <AlbumPage>[
  AlbumPage(0, 'Portada', 'Álbum SportZone', null, Color(0xFFB7F34A)),
  AlbumPage(1, 'Cracks del fútbol', 'Página 1 · Fútbol', Sport.football, Color(0xFF2ECC71)),
  AlbumPage(2, 'Estrellas mundiales', 'Página 2 · Fútbol', Sport.football, Color(0xFF27AE60)),
  AlbumPage(3, 'Clubes gigantes', 'Página 3 · Escudos', Sport.football, Color(0xFF1E8449)),
  AlbumPage(4, 'Reyes de la NBA', 'Página 4 · NBA', Sport.basketball, Color(0xFFFF8A1F)),
  AlbumPage(5, 'Nueva era NBA', 'Página 5 · NBA', Sport.basketball, Color(0xFFE67E22)),
  AlbumPage(6, 'Raquetas ATP', 'Página 6 · Tenis', Sport.tennis, Color(0xFFF1C40F)),
  AlbumPage(7, 'Reinas WTA', 'Página 7 · Tenis', Sport.tennis, Color(0xFFD4AC0D)),
  AlbumPage(8, 'Guerreros del octágono', 'Página 8 · UFC', Sport.ufc, Color(0xFFE74C3C)),
  AlbumPage(9, 'Leyendas doradas', 'Página 9 · Especial', null, Color(0xFFE0A100)),
];

const _c = StickerRarity.common, _r = StickerRarity.rare, _e = StickerRarity.epic, _l = StickerRarity.legendary;

Sticker _p(int n, String name, String country, String role, Sport sport, int page, StickerRarity rarity, int color, {String? wiki}) => Sticker(
      id: 's${n.toString().padLeft(2, '0')}',
      number: n,
      name: name,
      country: country,
      role: role,
      sport: sport,
      page: page,
      rarity: rarity,
      color: Color(color),
      wiki: wiki,
    );

Sticker _club(int n, String name, String teamId, String country, StickerRarity rarity, int color) => Sticker(
      id: 's${n.toString().padLeft(2, '0')}',
      number: n,
      name: name,
      country: country,
      role: 'Escudo',
      sport: Sport.football,
      page: 3,
      rarity: rarity,
      color: Color(color),
      kind: StickerKind.club,
      teamId: teamId,
    );

const _fb = Sport.football, _bk = Sport.basketball, _tn = Sport.tennis, _uf = Sport.ufc;

final List<Sticker> albumStickers = [
  // ── Página 1 · Fútbol ──
  _p(1, 'Kylian Mbappé', '🇫🇷 Francia', 'Delantero', _fb, 1, _e, 0xFF1F3A93),
  _p(2, 'Vinícius Júnior', '🇧🇷 Brasil', 'Extremo', _fb, 1, _r, 0xFF1E8449),
  _p(3, 'Jude Bellingham', '🏴 Inglaterra', 'Mediocampista', _fb, 1, _c, 0xFFC0392B),
  _p(4, 'Lamine Yamal', '🇪🇸 España', 'Extremo', _fb, 1, _e, 0xFFB03A2E),
  _p(5, 'Pedri', '🇪🇸 España', 'Mediocampista', _fb, 1, _c, 0xFF922B21),
  _p(6, 'Robert Lewandowski', '🇵🇱 Polonia', 'Delantero', _fb, 1, _c, 0xFFCB4335),
  _p(7, 'Erling Haaland', '🇳🇴 Noruega', 'Delantero', _fb, 1, _r, 0xFF2E86C1),
  _p(8, 'Rodri', '🇪🇸 España', 'Mediocampista', _fb, 1, _c, 0xFF2874A6, wiki: 'Rodri (footballer, born 1996)'),
  // ── Página 2 · Fútbol ──
  _p(9, 'Mohamed Salah', '🇪🇬 Egipto', 'Extremo', _fb, 2, _r, 0xFFC0392B),
  _p(10, 'Virgil van Dijk', '🇳🇱 Países Bajos', 'Defensa', _fb, 2, _c, 0xFFE67E22),
  _p(11, 'Bukayo Saka', '🏴 Inglaterra', 'Extremo', _fb, 2, _c, 0xFFE74C3C),
  _p(12, 'Harry Kane', '🏴 Inglaterra', 'Delantero', _fb, 2, _r, 0xFF1B4F72),
  _p(13, 'Jamal Musiala', '🇩🇪 Alemania', 'Mediocampista', _fb, 2, _c, 0xFF17202A),
  _p(14, 'Lautaro Martínez', '🇦🇷 Argentina', 'Delantero', _fb, 2, _c, 0xFF5DADE2),
  _p(15, 'Luis Díaz', '🇨🇴 Colombia', 'Extremo', _fb, 2, _r, 0xFFF4D03F, wiki: 'Luis Díaz (footballer, born 1997)'),
  _p(16, 'James Rodríguez', '🇨🇴 Colombia', 'Mediocampista', _fb, 2, _c, 0xFFF1C40F),
  // ── Página 3 · Clubes ──
  _club(17, 'Real Madrid', 'rma', '🇪🇸 España', _r, 0xFF2B4A9B),
  _club(18, 'FC Barcelona', 'fcb', '🇪🇸 España', _r, 0xFFA50044),
  _club(19, 'Manchester City', 'mci', '🏴 Inglaterra', _c, 0xFF6CABDD),
  _club(20, 'Liverpool', 'liv', '🏴 Inglaterra', _c, 0xFFC8102E),
  _club(21, 'Bayern Múnich', 'bay', '🇩🇪 Alemania', _c, 0xFFDC052D),
  _club(22, 'Paris Saint-Germain', 'psg', '🇫🇷 Francia', _c, 0xFF004170),
  _club(23, 'Juventus', 'juv', '🇮🇹 Italia', _c, 0xFF444444),
  _club(24, 'Atlético Nacional', 'x_nac', '🇨🇴 Colombia', _e, 0xFF00843D),
  // ── Página 4 · NBA ──
  _p(25, 'LeBron James', '🇺🇸 EE. UU.', 'Alero', _bk, 4, _e, 0xFF552583),
  _p(26, 'Stephen Curry', '🇺🇸 EE. UU.', 'Base', _bk, 4, _r, 0xFF1D428A),
  _p(27, 'Nikola Jokić', '🇷🇸 Serbia', 'Pívot', _bk, 4, _e, 0xFF0E2240),
  _p(28, 'Luka Dončić', '🇸🇮 Eslovenia', 'Base', _bk, 4, _r, 0xFF00538C),
  _p(29, 'Giannis Antetokounmpo', '🇬🇷 Grecia', 'Ala-pívot', _bk, 4, _r, 0xFF00471B),
  _p(30, 'Jayson Tatum', '🇺🇸 EE. UU.', 'Alero', _bk, 4, _c, 0xFF007A33),
  // ── Página 5 · NBA ──
  _p(31, 'Shai Gilgeous-Alexander', '🇨🇦 Canadá', 'Escolta', _bk, 5, _e, 0xFF007AC1),
  _p(32, 'Victor Wembanyama', '🇫🇷 Francia', 'Pívot', _bk, 5, _e, 0xFF000000),
  _p(33, 'Anthony Edwards', '🇺🇸 EE. UU.', 'Escolta', _bk, 5, _c, 0xFF0C2340, wiki: 'Anthony Edwards (basketball)'),
  _p(34, 'Kevin Durant', '🇺🇸 EE. UU.', 'Alero', _bk, 5, _c, 0xFF1D1160),
  _p(35, 'Joel Embiid', '🇨🇲 Camerún', 'Pívot', _bk, 5, _c, 0xFF006BB6),
  _p(36, 'Ja Morant', '🇺🇸 EE. UU.', 'Base', _bk, 5, _c, 0xFF5D76A9),
  // ── Página 6 · ATP ──
  _p(37, 'Carlos Alcaraz', '🇪🇸 España', 'ATP', _tn, 6, _e, 0xFFE67E22),
  _p(38, 'Jannik Sinner', '🇮🇹 Italia', 'ATP', _tn, 6, _e, 0xFFD35400),
  _p(39, 'Novak Djokovic', '🇷🇸 Serbia', 'ATP', _tn, 6, _r, 0xFF2980B9),
  _p(40, 'Alexander Zverev', '🇩🇪 Alemania', 'ATP', _tn, 6, _c, 0xFF34495E),
  _p(41, 'Taylor Fritz', '🇺🇸 EE. UU.', 'ATP', _tn, 6, _c, 0xFF2471A3),
  _p(42, 'Ben Shelton', '🇺🇸 EE. UU.', 'ATP', _tn, 6, _c, 0xFF2E86C1),
  // ── Página 7 · WTA ──
  _p(43, 'Aryna Sabalenka', '🇧🇾 Bielorrusia', 'WTA', _tn, 7, _e, 0xFFCB4335),
  _p(44, 'Iga Świątek', '🇵🇱 Polonia', 'WTA', _tn, 7, _r, 0xFFC0392B),
  _p(45, 'Coco Gauff', '🇺🇸 EE. UU.', 'WTA', _tn, 7, _r, 0xFF2E86C1),
  _p(46, 'Elena Rybakina', '🇰🇿 Kazajistán', 'WTA', _tn, 7, _c, 0xFF2471A3),
  _p(47, 'Jessica Pegula', '🇺🇸 EE. UU.', 'WTA', _tn, 7, _c, 0xFF1A5276),
  _p(48, 'Camila Osorio', '🇨🇴 Colombia', 'WTA', _tn, 7, _c, 0xFFF4D03F),
  // ── Página 8 · UFC ──
  _p(49, 'Islam Makhachev', '🇷🇺 Rusia', 'Peso ligero', _uf, 8, _e, 0xFF1ABC9C),
  _p(50, 'Ilia Topuria', '🇪🇸 España', 'Peso ligero', _uf, 8, _e, 0xFFE74C3C),
  _p(51, 'Alex Pereira', '🇧🇷 Brasil', 'Peso semipesado', _uf, 8, _r, 0xFF16A085),
  _p(52, 'Jon Jones', '🇺🇸 EE. UU.', 'Peso pesado', _uf, 8, _r, 0xFF2C3E50),
  _p(53, 'Tom Aspinall', '🏴 Inglaterra', 'Peso pesado', _uf, 8, _c, 0xFF1F618D),
  _p(54, 'Merab Dvalishvili', '🇬🇪 Georgia', 'Peso gallo', _uf, 8, _c, 0xFFB03A2E),
  _p(55, 'Alexandre Pantoja', '🇧🇷 Brasil', 'Peso mosca', _uf, 8, _c, 0xFF239B56),
  _p(56, 'Valentina Shevchenko', '🇰🇬 Kirguistán', 'Peso mosca (F)', _uf, 8, _c, 0xFFC0392B),
  // ── Página 9 · Leyendas ──
  _p(57, 'Ronaldinho', '🇧🇷 Brasil', 'Leyenda del fútbol', _fb, 9, _l, 0xFFE0A100),
  _p(58, 'Diego Maradona', '🇦🇷 Argentina', 'Leyenda del fútbol', _fb, 9, _l, 0xFFE0A100),
  _p(59, 'Michael Jordan', '🇺🇸 EE. UU.', 'Leyenda NBA', _bk, 9, _l, 0xFFE0A100),
  _p(60, 'Kobe Bryant', '🇺🇸 EE. UU.', 'Leyenda NBA', _bk, 9, _l, 0xFFE0A100),
  _p(61, 'Roger Federer', '🇨🇭 Suiza', 'Leyenda del tenis', _tn, 9, _l, 0xFFE0A100),
  _p(62, 'Serena Williams', '🇺🇸 EE. UU.', 'Leyenda del tenis', _tn, 9, _l, 0xFFE0A100),
];

Sticker? stickerById(String id) => albumStickers.where((s) => s.id == id).firstOrNull;

List<Sticker> stickersOfPage(int page) => albumStickers.where((s) => s.page == page).toList();

// ═════════════════════════ MISIONES ═════════════════════════

const albumMissions = <Mission>[
  // Diarias
  Mission(id: 'd_news', title: 'Lee 5 noticias', description: 'Abre 5 noticias distintas y quédate unos segundos en cada una.', icon: Icons.newspaper, event: MissionEvent.readNews, target: 5, period: MissionPeriod.daily, xp: 30),
  Mission(id: 'd_streak', title: 'Reclama tu racha', description: 'Reclama la racha del día en el Hub.', icon: Icons.local_fire_department, event: MissionEvent.checkIn, target: 1, period: MissionPeriod.daily, xp: 10),
  Mission(id: 'd_vote', title: 'Haz un pronóstico', description: 'Vota quién gana un partido.', icon: Icons.how_to_vote, event: MissionEvent.vote, target: 1, period: MissionPeriod.daily, xp: 15),
  Mission(id: 'd_match', title: 'Mira 2 partidos', description: 'Abre el detalle de 2 partidos.', icon: Icons.scoreboard, event: MissionEvent.openMatch, target: 2, period: MissionPeriod.daily, xp: 15),
  Mission(id: 'd_avatar', title: 'Estrena pinta', description: 'Cambia una prenda de tu avatar.', icon: Icons.checkroom, event: MissionEvent.avatar, target: 1, period: MissionPeriod.daily, xp: 10),
  // Semanales
  Mission(id: 'w_streak', title: 'Constancia', description: 'Reclama la racha 5 días esta semana.', icon: Icons.whatshot, event: MissionEvent.checkIn, target: 5, period: MissionPeriod.weekly, packs: 2, xp: 100),
  Mission(id: 'w_follow', title: 'Hincha de verdad', description: 'Sigue 3 equipos o deportistas.', icon: Icons.star, event: MissionEvent.follow, target: 3, period: MissionPeriod.weekly, xp: 50),
  Mission(id: 'w_new', title: 'Coleccionista', description: 'Consigue 10 láminas nuevas.', icon: Icons.collections_bookmark, event: MissionEvent.newSticker, target: 10, period: MissionPeriod.weekly, packs: 2, xp: 80),
  Mission(id: 'w_packs', title: 'Abre-sobres', description: 'Abre 6 sobres.', icon: Icons.mail, event: MissionEvent.openPack, target: 6, period: MissionPeriod.weekly, xp: 60),
];
