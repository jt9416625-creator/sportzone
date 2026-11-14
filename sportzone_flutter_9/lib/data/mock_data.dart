// DATOS DE EJEMPLO (mock). Nombres reales, pero marcadores, alineaciones
// y resultados son inventados para probar el diseño.
// TODO(api): cuando conectemos la base de datos / API, este archivo se
// reemplaza por llamadas reales (TheSportsDB, API-Football, balldontlie).
import 'package:flutter/material.dart';

import '../models/models.dart';
import 'more_teams.dart';

// ───────────────────────── EQUIPOS ─────────────────────────
const _fb = 'https://crests.football-data.org';
const _nba = 'https://a.espncdn.com/i/teamlogos/nba/500';

const rma = Team(id: 'rma', name: 'Real Madrid', short: 'RMA', sport: Sport.football, crestUrl: '$_fb/86.png', color: Color(0xFF2B4A9B), country: 'España');
const fcb = Team(id: 'fcb', name: 'FC Barcelona', short: 'BAR', sport: Sport.football, crestUrl: '$_fb/81.png', color: Color(0xFFA50044), country: 'España');
const atm = Team(id: 'atm', name: 'Atlético de Madrid', short: 'ATM', sport: Sport.football, crestUrl: '$_fb/78.png', color: Color(0xFFCB3524), country: 'España');
const mci = Team(id: 'mci', name: 'Manchester City', short: 'MCI', sport: Sport.football, crestUrl: '$_fb/65.png', color: Color(0xFF6CABDD), country: 'Inglaterra');
const ars = Team(id: 'ars', name: 'Arsenal', short: 'ARS', sport: Sport.football, crestUrl: '$_fb/57.png', color: Color(0xFFEF0107), country: 'Inglaterra');
const liv = Team(id: 'liv', name: 'Liverpool', short: 'LIV', sport: Sport.football, crestUrl: '$_fb/64.png', color: Color(0xFFC8102E), country: 'Inglaterra');
const bay = Team(id: 'bay', name: 'Bayern Múnich', short: 'BAY', sport: Sport.football, crestUrl: '$_fb/5.png', color: Color(0xFFDC052D), country: 'Alemania');
const psg = Team(id: 'psg', name: 'Paris Saint-Germain', short: 'PSG', sport: Sport.football, crestUrl: '$_fb/524.png', color: Color(0xFF004170), country: 'Francia');
const juv = Team(id: 'juv', name: 'Juventus', short: 'JUV', sport: Sport.football, crestUrl: '$_fb/109.png', color: Color(0xFF444444), country: 'Italia');
const acm = Team(id: 'acm', name: 'AC Milan', short: 'MIL', sport: Sport.football, crestUrl: '$_fb/98.png', color: Color(0xFFFB090B), country: 'Italia');

const lal = Team(id: 'lal', name: 'Los Angeles Lakers', short: 'LAL', sport: Sport.basketball, crestUrl: '$_nba/lal.png', color: Color(0xFF552583), country: 'EE. UU.');
const bos = Team(id: 'bos', name: 'Boston Celtics', short: 'BOS', sport: Sport.basketball, crestUrl: '$_nba/bos.png', color: Color(0xFF007A33), country: 'EE. UU.');
const gsw = Team(id: 'gsw', name: 'Golden State Warriors', short: 'GSW', sport: Sport.basketball, crestUrl: '$_nba/gs.png', color: Color(0xFFFFC72C), country: 'EE. UU.');
const den = Team(id: 'den', name: 'Denver Nuggets', short: 'DEN', sport: Sport.basketball, crestUrl: '$_nba/den.png', color: Color(0xFF0E2240), country: 'EE. UU.');
const mia = Team(id: 'mia', name: 'Miami Heat', short: 'MIA', sport: Sport.basketball, crestUrl: '$_nba/mia.png', color: Color(0xFF98002E), country: 'EE. UU.');
const mil = Team(id: 'mil', name: 'Milwaukee Bucks', short: 'MIL', sport: Sport.basketball, crestUrl: '$_nba/mil.png', color: Color(0xFF00471B), country: 'EE. UU.');
const nyk = Team(id: 'nyk', name: 'New York Knicks', short: 'NYK', sport: Sport.basketball, crestUrl: '$_nba/ny.png', color: Color(0xFF006BB6), country: 'EE. UU.');

const alc = Team(id: 'alc', name: 'Carlos Alcaraz', short: 'ALC', sport: Sport.tennis, color: Color(0xFFE67E22), country: '🇪🇸');
const sin = Team(id: 'sin', name: 'Jannik Sinner', short: 'SIN', sport: Sport.tennis, color: Color(0xFFD35400), country: '🇮🇹');
const djo = Team(id: 'djo', name: 'Novak Djokovic', short: 'DJO', sport: Sport.tennis, color: Color(0xFF2980B9), country: '🇷🇸');
const med = Team(id: 'med', name: 'Daniil Medvedev', short: 'MED', sport: Sport.tennis, color: Color(0xFF8E44AD), country: '🇷🇺');

// ───────────────────────── PELEADORES ─────────────────────────
const makhachev = Fighter(id: 'f_mak', name: 'Islam Makhachev', nickname: 'Makhachev', record: '27-1-0', flag: '🇷🇺', color: Color(0xFF1ABC9C));
const oliveira = Fighter(id: 'f_oli', name: 'Charles Oliveira', nickname: 'Do Bronx', record: '34-10-0', flag: '🇧🇷', color: Color(0xFF27AE60));
const pereira = Fighter(id: 'f_per', name: 'Alex Pereira', nickname: 'Poatan', record: '12-3-0', flag: '🇧🇷', color: Color(0xFF16A085));
const prochazka = Fighter(id: 'f_pro', name: 'Jiří Procházka', nickname: 'BJP', record: '31-5-1', flag: '🇨🇿', color: Color(0xFF2980B9));
const duplessis = Fighter(id: 'f_ddp', name: 'Dricus du Plessis', nickname: 'Stillknocks', record: '22-2-0', flag: '🇿🇦', color: Color(0xFFF39C12));
const strickland = Fighter(id: 'f_str', name: 'Sean Strickland', nickname: 'Tarzan', record: '29-6-0', flag: '🇺🇸', color: Color(0xFFC0392B));
const topuria = Fighter(id: 'f_top', name: 'Ilia Topuria', nickname: 'El Matador', record: '16-0-0', flag: '🇪🇸', color: Color(0xFFE74C3C));
const holloway = Fighter(id: 'f_hol', name: 'Max Holloway', nickname: 'Blessed', record: '26-8-0', flag: '🇺🇸', color: Color(0xFF3498DB));

const allFighters = [makhachev, oliveira, pereira, prochazka, duplessis, strickland, topuria, holloway];

const allTeams = [
  rma, fcb, atm, mci, ars, liv, bay, psg, juv, acm,
  lal, bos, gsw, den, mia, mil, nyk,
  alc, sin, djo, med,
];

/// Todo lo que se puede seguir: equipos + jugadores + peleadores.
final List<Team> allFollowables = [
  ...allTeams,
  ...extraTeams.map((e) => e.$1), // más clubes, franquicias NBA, tenistas y peleadores
  ...allFighters.map((f) => Team(
        id: f.id,
        name: f.name,
        short: f.initials,
        sport: Sport.ufc,
        color: f.color,
        country: f.flag,
      )),
];

// ───────────────────────── ALINEACIONES ─────────────────────────
const _rmaLineup = Lineup('4-3-3', [
  LineupPlayer(1, 'Courtois', 'POR', rating: 7.1),
  LineupPlayer(2, 'Carvajal', 'DEF', rating: 6.8),
  LineupPlayer(3, 'Militão', 'DEF', rating: 7.0),
  LineupPlayer(22, 'Rüdiger', 'DEF', rating: 7.3),
  LineupPlayer(23, 'Mendy', 'DEF', rating: 6.6),
  LineupPlayer(8, 'Valverde', 'MED', rating: 7.4),
  LineupPlayer(18, 'Tchouaméni', 'MED', rating: 6.9),
  LineupPlayer(5, 'Bellingham', 'MED', rating: 7.8),
  LineupPlayer(11, 'Rodrygo', 'DEL', rating: 7.0),
  LineupPlayer(9, 'Mbappé', 'DEL', rating: 8.4),
  LineupPlayer(7, 'Vinícius Jr.', 'DEL', rating: 8.1),
], [
  LineupPlayer(13, 'Lunin', 'POR'),
  LineupPlayer(12, 'Camavinga', 'MED', rating: 6.7),
  LineupPlayer(15, 'Güler', 'MED'),
  LineupPlayer(21, 'Brahim', 'DEL'),
]);

const _fcbLineup = Lineup('4-3-3', [
  LineupPlayer(1, 'ter Stegen', 'POR', rating: 6.5),
  LineupPlayer(23, 'Koundé', 'DEF', rating: 6.9),
  LineupPlayer(2, 'Cubarsí', 'DEF', rating: 6.6),
  LineupPlayer(4, 'Araújo', 'DEF', rating: 6.0),
  LineupPlayer(3, 'Balde', 'DEF', rating: 6.7),
  LineupPlayer(8, 'Pedri', 'MED', rating: 7.3),
  LineupPlayer(21, 'de Jong', 'MED', rating: 7.0),
  LineupPlayer(6, 'Gavi', 'MED', rating: 6.4),
  LineupPlayer(11, 'Raphinha', 'DEL', rating: 7.1),
  LineupPlayer(9, 'Lewandowski', 'DEL', rating: 6.8),
  LineupPlayer(19, 'Yamal', 'DEL', rating: 8.0),
], [
  LineupPlayer(13, 'Iñaki Peña', 'POR'),
  LineupPlayer(20, 'Olmo', 'MED'),
  LineupPlayer(16, 'Fermín', 'MED'),
  LineupPlayer(7, 'Ferran', 'DEL'),
]);

const _lalLineup = Lineup('5', [
  LineupPlayer(77, 'Luka Dončić', 'G', pts: 21, reb: 8, ast: 9, rating: 8.9),
  LineupPlayer(15, 'Austin Reaves', 'G', pts: 14, reb: 3, ast: 5, rating: 7.4),
  LineupPlayer(23, 'LeBron James', 'F', pts: 17, reb: 6, ast: 7, rating: 8.2),
  LineupPlayer(28, 'Rui Hachimura', 'F', pts: 9, reb: 4, ast: 1, rating: 6.9),
  LineupPlayer(11, 'Jaxson Hayes', 'C', pts: 4, reb: 5, ast: 0, rating: 6.2),
], [
  LineupPlayer(7, 'Gabe Vincent', 'G', pts: 5, reb: 1, ast: 3, rating: 6.5),
  LineupPlayer(2, 'Jarred Vanderbilt', 'F', pts: 3, reb: 4, ast: 0, rating: 6.4),
  LineupPlayer(4, 'Dalton Knecht', 'F', pts: 5, reb: 1, ast: 1, rating: 6.6),
]);

const _bosLineup = Lineup('5', [
  LineupPlayer(4, 'Jrue Holiday', 'G', pts: 8, reb: 4, ast: 6, rating: 6.8),
  LineupPlayer(9, 'Derrick White', 'G', pts: 16, reb: 3, ast: 5, rating: 7.6),
  LineupPlayer(7, 'Jaylen Brown', 'F', pts: 18, reb: 5, ast: 3, rating: 8.0),
  LineupPlayer(0, 'Jayson Tatum', 'F', pts: 24, reb: 9, ast: 4, rating: 8.7),
  LineupPlayer(8, 'Kristaps Porziņģis', 'C', pts: 10, reb: 6, ast: 1, rating: 7.2),
], [
  LineupPlayer(30, 'Sam Hauser', 'F', pts: 5, reb: 2, ast: 0, rating: 6.6),
  LineupPlayer(11, 'Payton Pritchard', 'G', pts: 0, reb: 1, ast: 2, rating: 6.0),
]);

// ───────────────────────── PARTIDOS ─────────────────────────
final List<MatchItem> matches = [
  MatchItem(
    id: 'm1',
    sport: Sport.football,
    competition: 'LaLiga · Jornada 10 · DEMO',
    home: rma,
    away: fcb,
    homeScore: 2,
    awayScore: 1,
    status: MatchStatus.live,
    clock: "67'",
    homeLineup: _rmaLineup,
    awayLineup: _fcbLineup,
    homeForm: 'WWDWL',
    awayForm: 'LWWDW',
    h2h: const [
      H2HGame(date: '2026-04-26', homeId: 'fcb', awayId: 'rma', homeName: 'FC Barcelona', awayName: 'Real Madrid', homeScore: 1, awayScore: 1, competition: 'LaLiga'),
      H2HGame(date: '2025-10-26', homeId: 'rma', awayId: 'fcb', homeName: 'Real Madrid', awayName: 'FC Barcelona', homeScore: 2, awayScore: 1, competition: 'LaLiga'),
      H2HGame(date: '2025-05-11', homeId: 'fcb', awayId: 'rma', homeName: 'FC Barcelona', awayName: 'Real Madrid', homeScore: 4, awayScore: 3, competition: 'LaLiga'),
      H2HGame(date: '2025-04-26', homeId: 'fcb', awayId: 'rma', homeName: 'FC Barcelona', awayName: 'Real Madrid', homeScore: 3, awayScore: 2, competition: 'Copa del Rey'),
    ],
    events: [
      const MatchEvent("12'", EventType.goal, EventSide.home, 'Gol de Mbappé (asist. Bellingham)'),
      const MatchEvent("28'", EventType.yellow, EventSide.away, 'Amarilla para Araújo'),
      const MatchEvent("35'", EventType.goal, EventSide.away, 'Gol de Yamal (asist. Pedri)'),
      const MatchEvent("45'", EventType.period, EventSide.none, 'Fin del primer tiempo'),
      const MatchEvent("52'", EventType.sub, EventSide.home, 'Entra Camavinga, sale Tchouaméni'),
      const MatchEvent("61'", EventType.goal, EventSide.home, 'Gol de Vinícius Jr. (asist. Rodrygo)'),
    ],
    stats: const [
      StatRow('Posesión', 54, 46, percent: true),
      StatRow('Tiros', 11, 8),
      StatRow('Tiros al arco', 5, 4),
      StatRow('Córners', 6, 3),
      StatRow('Faltas', 9, 12),
    ],
  ),
  MatchItem(
    id: 'm2',
    sport: Sport.football,
    competition: 'Premier League · Jornada 9 · DEMO',
    home: mci,
    away: ars,
    homeScore: 1,
    awayScore: 1,
    status: MatchStatus.finished,
    clock: 'FINAL',
    events: [
      const MatchEvent("23'", EventType.goal, EventSide.home, 'Gol de Haaland'),
      const MatchEvent("58'", EventType.yellow, EventSide.away, 'Amarilla para Rice'),
      const MatchEvent("71'", EventType.goal, EventSide.away, 'Gol de Saka'),
      const MatchEvent("90'", EventType.period, EventSide.none, 'Final del partido'),
    ],
    stats: const [
      StatRow('Posesión', 58, 42, percent: true),
      StatRow('Tiros', 14, 9),
      StatRow('Tiros al arco', 5, 3),
      StatRow('Córners', 7, 4),
    ],
  ),
  MatchItem(
    id: 'm3',
    sport: Sport.football,
    competition: 'Champions League · DEMO',
    home: liv,
    away: bay,
    status: MatchStatus.upcoming,
    clock: 'Hoy',
    kickoff: DateTime.now().add(const Duration(hours: 3, minutes: 12)),
  ),
  MatchItem(
    id: 'm4',
    sport: Sport.football,
    competition: 'Champions League · DEMO',
    home: psg,
    away: juv,
    homeScore: 3,
    awayScore: 0,
    status: MatchStatus.finished,
    clock: 'FINAL',
    events: [
      const MatchEvent("9'", EventType.goal, EventSide.home, 'Gol de Dembélé'),
      const MatchEvent("44'", EventType.goal, EventSide.home, 'Gol de Barcola'),
      const MatchEvent("77'", EventType.goal, EventSide.home, 'Gol de Hakimi'),
    ],
  ),
  MatchItem(
    id: 'b1',
    sport: Sport.basketball,
    competition: 'NBA · Temporada regular · DEMO',
    home: lal,
    away: bos,
    homeScore: 78,
    awayScore: 81,
    status: MatchStatus.live,
    clock: 'Q3 5:42',
    homeLineup: _lalLineup,
    awayLineup: _bosLineup,
    homeForm: 'WLWWL',
    awayForm: 'WWWLW',
    h2h: const [
      H2HGame(date: '2026-02-12', homeId: 'bos', awayId: 'lal', homeName: 'Boston Celtics', awayName: 'Los Angeles Lakers', homeScore: 118, awayScore: 109, competition: 'NBA'),
      H2HGame(date: '2025-12-05', homeId: 'lal', awayId: 'bos', homeName: 'Los Angeles Lakers', awayName: 'Boston Celtics', homeScore: 112, awayScore: 115, competition: 'NBA'),
    ],
    events: [
      const MatchEvent('Q1', EventType.period, EventSide.none, 'Comienza el partido'),
      const MatchEvent('Q1 8:20', EventType.basket, EventSide.home, 'Triple de Dončić (+3)'),
      const MatchEvent('Q2 4:05', EventType.basket, EventSide.away, 'Volcada de Tatum (+2)'),
      const MatchEvent('Q2 0:00', EventType.period, EventSide.none, 'Descanso: LAL 52 - BOS 55'),
      const MatchEvent('Q3 6:10', EventType.basket, EventSide.home, 'Triple de LeBron James (+3)'),
      const MatchEvent('Q3 5:42', EventType.basket, EventSide.away, 'Triple de Brown (+3)'),
    ],
    stats: const [
      StatRow('Tiros de campo', 47, 49, percent: true),
      StatRow('Rebotes', 28, 30),
      StatRow('Asistencias', 19, 22),
      StatRow('Pérdidas', 8, 6),
    ],
  ),
  MatchItem(
    id: 'b2',
    sport: Sport.basketball,
    competition: 'NBA · Temporada regular · DEMO',
    home: gsw,
    away: den,
    homeScore: 112,
    awayScore: 104,
    status: MatchStatus.finished,
    clock: 'FINAL',
    events: [
      const MatchEvent('Q4 0:00', EventType.period, EventSide.none, 'Final: GSW 112 - DEN 104'),
    ],
    stats: const [
      StatRow('Tiros de campo', 48, 44, percent: true),
      StatRow('Rebotes', 41, 39),
      StatRow('Asistencias', 29, 24),
    ],
  ),
  MatchItem(
    id: 'b3',
    sport: Sport.basketball,
    competition: 'NBA · Temporada regular · DEMO',
    home: mia,
    away: mil,
    status: MatchStatus.upcoming,
    clock: 'Mañana',
    kickoff: DateTime.now().add(const Duration(hours: 20)),
  ),
  MatchItem(
    id: 't1',
    sport: Sport.tennis,
    competition: 'ATP · Final · DEMO',
    home: alc,
    away: sin,
    homeScore: 2,
    awayScore: 1,
    status: MatchStatus.finished,
    clock: 'FINAL',
    detail: '6-4  3-6  7-5',
    events: [
      const MatchEvent('Set 1', EventType.info, EventSide.home, 'Alcaraz gana 6-4'),
      const MatchEvent('Set 2', EventType.info, EventSide.away, 'Sinner gana 6-3'),
      const MatchEvent('Set 3', EventType.info, EventSide.home, 'Alcaraz gana 7-5'),
    ],
  ),
  MatchItem(
    id: 't2',
    sport: Sport.tennis,
    competition: 'ATP · Semifinal · DEMO',
    home: djo,
    away: med,
    homeScore: 1,
    awayScore: 0,
    status: MatchStatus.live,
    clock: 'Set 2',
    detail: '6-3  2-1',
    events: [
      const MatchEvent('Set 1', EventType.info, EventSide.home, 'Djokovic gana 6-3'),
      const MatchEvent('Set 2', EventType.info, EventSide.home, 'Djokovic gana el juego (2-1)'),
    ],
  ),
];

// ───────────────────────── PELEAS UFC ─────────────────────────
final List<Fight> fights = [
  Fight(
    id: 'u4',
    eventName: 'UFC · Evento principal',
    weightClass: 'Peso ligero',
    red: topuria,
    blue: holloway,
    status: MatchStatus.live,
    clock: 'Round 3 · 2:10',
    redStrikes: const [21, 26, 11],
    blueStrikes: const [15, 19, 9],
    stats: const [
      StatRow('Golpes conectados', 58, 43),
      StatRow('Derribos', 1, 0),
      StatRow('Intentos de sumisión', 0, 0),
    ],
    events: const [
      MatchEvent('R1 0:00', EventType.period, EventSide.none, 'Comienza el Round 1'),
      MatchEvent('R1 2:40', EventType.strike, EventSide.home, 'Gancho de izquierda de Topuria'),
      MatchEvent('R2 1:05', EventType.takedown, EventSide.home, 'Derribo de Topuria'),
      MatchEvent('R2 4:30', EventType.strike, EventSide.away, 'Patada baja de Holloway'),
      MatchEvent('R3 0:00', EventType.period, EventSide.none, 'Comienza el Round 3'),
      MatchEvent('R3 2:10', EventType.strike, EventSide.home, 'Recto de derecha de Topuria'),
    ],
  ),
  Fight(
    id: 'u1',
    eventName: 'UFC · Evento principal',
    weightClass: 'Peso ligero',
    red: makhachev,
    blue: oliveira,
    status: MatchStatus.finished,
    clock: 'FINAL',
    winner: makhachev,
    method: FightMethod.submission,
    methodDetail: 'Estrangulación guillotina',
    round: 4,
    time: '2:15',
    redStrikes: const [22, 30, 27, 15],
    blueStrikes: const [14, 18, 12, 6],
    stats: const [
      StatRow('Golpes conectados', 94, 50),
      StatRow('Derribos', 3, 1),
      StatRow('Intentos de sumisión', 2, 0),
    ],
    events: const [
      MatchEvent('R1 1:10', EventType.takedown, EventSide.home, 'Derribo de Makhachev'),
      MatchEvent('R2 3:20', EventType.strike, EventSide.away, 'Rodillazo de Oliveira'),
      MatchEvent('R3 2:45', EventType.submissionTry, EventSide.home, 'Intento de triángulo'),
      MatchEvent('R4 2:15', EventType.submissionTry, EventSide.home, 'Sumisión: guillotina. Oliveira golpea y se rinde'),
    ],
  ),
  Fight(
    id: 'u2',
    eventName: 'UFC · Co-estelar',
    weightClass: 'Peso semipesado',
    red: pereira,
    blue: prochazka,
    status: MatchStatus.finished,
    clock: 'FINAL',
    winner: pereira,
    method: FightMethod.ko,
    methodDetail: 'Gancho de izquierda',
    round: 2,
    time: '3:41',
    redStrikes: const [18, 24],
    blueStrikes: const [12, 9],
    stats: const [
      StatRow('Golpes conectados', 42, 21),
      StatRow('Derribos', 0, 0),
      StatRow('Intentos de sumisión', 0, 0),
    ],
    events: const [
      MatchEvent('R1 2:00', EventType.strike, EventSide.home, 'Patada baja de Pereira'),
      MatchEvent('R2 3:41', EventType.strike, EventSide.home, 'KO: gancho de izquierda al mentón'),
    ],
  ),
  Fight(
    id: 'u3',
    eventName: 'UFC · Tarjeta preliminar',
    weightClass: 'Peso mediano',
    red: duplessis,
    blue: strickland,
    status: MatchStatus.finished,
    clock: 'FINAL',
    winner: duplessis,
    method: FightMethod.decision,
    methodDetail: 'Tarjetas 49-46, 48-47, 49-46',
    round: 5,
    time: '5:00',
    redStrikes: const [31, 28, 35, 30, 33],
    blueStrikes: const [25, 27, 22, 29, 20],
    stats: const [
      StatRow('Golpes conectados', 157, 123),
      StatRow('Derribos', 2, 0),
      StatRow('Intentos de sumisión', 1, 0),
    ],
    events: const [
      MatchEvent('R1 3:00', EventType.strike, EventSide.away, 'Jab de Strickland'),
      MatchEvent('R3 1:30', EventType.takedown, EventSide.home, 'Derribo de Du Plessis'),
      MatchEvent('R5 5:00', EventType.period, EventSide.none, 'Final: gana Du Plessis por decisión unánime'),
    ],
  ),
];

// ───────────────────────── NOTICIAS ─────────────────────────
const _lorem =
    'Esta es una noticia de ejemplo para probar el diseño. Cuando conectemos '
    'la base de datos o una API de noticias, aquí aparecerá el texto real '
    'completo del artículo, con fotos y datos del partido.';

const List<NewsItem> news = [
  NewsItem(id: 'n1', sport: Sport.football, tag: 'CLÁSICO', ago: 'Hace 12 min', title: 'Mbappé y Vinícius encienden el clásico en el Bernabéu', summary: 'El Madrid manda en el marcador y el Barça responde con Yamal.', body: _lorem),
  NewsItem(id: 'n2', sport: Sport.basketball, tag: 'NBA', ago: 'Hace 35 min', title: 'Dončić y Tatum protagonizan un duelo de estrellas en Los Ángeles', summary: 'Partido cerrado con triples en cada posesión.', body: _lorem),
  NewsItem(id: 'n3', sport: Sport.ufc, tag: 'UFC', ago: 'Hace 1 h', title: 'Makhachev sigue invicto: sumisión en el cuarto round', summary: 'Una guillotina cerró la pelea estelar de la noche.', body: _lorem),
  NewsItem(id: 'n4', sport: Sport.football, tag: 'CHAMPIONS', ago: 'Hace 2 h', title: 'Liverpool y Bayern abren la noche europea', summary: 'Todo listo para uno de los partidos más esperados.', body: _lorem),
  NewsItem(id: 'n5', sport: Sport.tennis, tag: 'ATP', ago: 'Hace 3 h', title: 'Alcaraz se queda con la final en un tercer set de infarto', summary: 'Remontada y título en tres sets.', body: _lorem),
  NewsItem(id: 'n6', sport: Sport.basketball, tag: 'MERCADO', ago: 'Hace 5 h', title: 'Los Warriors suben su nivel y ganan en casa', summary: 'Golden State vence a Denver con gran segundo tiempo.', body: _lorem),
  NewsItem(id: 'n7', sport: Sport.ufc, tag: 'KO', ago: 'Hace 6 h', title: 'Pereira noquea con un gancho de izquierda en el round 2', summary: 'Uno de los nocauts de la noche.', body: _lorem),
  NewsItem(id: 'n8', sport: Sport.football, tag: 'PREMIER', ago: 'Ayer', title: 'City y Arsenal se reparten los puntos en un partido cerrado', summary: 'Haaland y Saka marcaron para cada lado.', body: _lorem),
];

// ───────────────────────── INSIGNIAS ─────────────────────────
const List<BadgeItem> allBadges = [
  BadgeItem('fan', 'Primer día', 'Te uniste a SportZone', Icons.emoji_events, Color(0xFFFFC83D)),
  BadgeItem('streak3', 'Copa Conference', 'Racha de 3 días', Icons.local_fire_department, Color(0xFF2E9E60), trophy: TrophyKind.conference),
  BadgeItem('streak7', 'Copa Europa League', 'Racha de 7 días', Icons.whatshot, Color(0xFFFFB400), trophy: TrophyKind.europa),
  BadgeItem('streak14', 'Copa Champions', 'Racha de 14 días', Icons.military_tech, Color(0xFF9FB4FF), trophy: TrophyKind.champions),
  BadgeItem('fav3', 'Fanático x3', 'Sigue 3 equipos o jugadores', Icons.favorite, Color(0xFFFF5C8A)),
  BadgeItem('predictor', 'Pronosticador', 'Haz tu primera predicción', Icons.insights, Color(0xFF4DA3FF)),
  BadgeItem('multi', 'Multideporte', 'Sigue 3 deportes distintos', Icons.public, Color(0xFF2ECC71)),
  BadgeItem('legend', 'Leyenda', 'Llega a 1000 XP', Icons.stars, Color(0xFFB7F34A)),
  BadgeItem('album', 'Álbum completo', 'Completa el álbum SportZone', Icons.collections_bookmark, Color(0xFFE0A100)),
];
