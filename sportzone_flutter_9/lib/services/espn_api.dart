import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/more_teams.dart';
import '../models/models.dart';
import 'emergency_store.dart';
import 'live_sim.dart';
import 'net.dart';

// API pública y SIN clave de ESPN (no oficial, sin garantías: puede cambiar).
// Sirve para proyectos personales y de estudio.
const espnSite = 'https://site.api.espn.com/apis/site/v2/sports';
const espnV2 = 'https://site.api.espn.com/apis/v2/sports';

/// Ligas y categorías que el usuario puede elegir.
const List<League> leagues = [
  League('esp.1', 'LaLiga', 'soccer/esp.1', Sport.football, '🇪🇸'),
  League('eng.1', 'Premier League', 'soccer/eng.1', Sport.football, '🇬🇧'),
  League('ita.1', 'Serie A', 'soccer/ita.1', Sport.football, '🇮🇹'),
  League('fra.1', 'Ligue 1', 'soccer/fra.1', Sport.football, '🇫🇷'),
  League('ger.1', 'Bundesliga', 'soccer/ger.1', Sport.football, '🇩🇪'),
  League('uefa.champions', 'Champions League', 'soccer/uefa.champions', Sport.football, '🇪🇺'),
  League('col.1', 'Liga BetPlay', 'soccer/col.1', Sport.football, '🇨🇴'),
  League('uefa.europa', 'Europa League', 'soccer/uefa.europa', Sport.football, '🇪🇺'),
  League('conmebol.libertadores', 'Copa Libertadores', 'soccer/conmebol.libertadores', Sport.football, '🏆'),
  League('por.1', 'Liga Portugal', 'soccer/por.1', Sport.football, '🇵🇹'),
  League('ned.1', 'Eredivisie', 'soccer/ned.1', Sport.football, '🇳🇱'),
  League('arg.1', 'Liga Profesional', 'soccer/arg.1', Sport.football, '🇦🇷'),
  League('bra.1', 'Brasileirão', 'soccer/bra.1', Sport.football, '🇧🇷'),
  League('mex.1', 'Liga MX', 'soccer/mex.1', Sport.football, '🇲🇽'),
  League('usa.1', 'MLS', 'soccer/usa.1', Sport.football, '🇺🇸'),
  League('nba', 'NBA', 'basketball/nba', Sport.basketball, '🇺🇸', daysBack: 4, daysForward: 4),
  League('ufc', 'UFC', 'mma/ufc', Sport.ufc, '🥊', daysBack: 90, daysForward: 150),
  League('atp', 'Tenis ATP', 'tennis/atp', Sport.tennis, '🎾', daysBack: 5, daysForward: 3),
  League('wta', 'Tenis WTA', 'tennis/wta', Sport.tennis, '🎾', daysBack: 5, daysForward: 3),
];

/// A qué liga pertenece cada equipo (id del equipo -> nombre de la liga).
final Map<String, String> teamLeague = {
  ...baseTeamLeagues,
  for (final e in extraTeams) e.$1.id: e.$2,
  for (final f in allFighters) f.id: 'UFC',
};

/// Categorías de peso de la UFC, en español (de más liviano a más pesado).
const List<String> weightClasses = [
  'Peso mosca',
  'Peso gallo',
  'Peso pluma',
  'Peso ligero',
  'Peso wélter',
  'Peso mediano',
  'Peso semipesado',
  'Peso pesado',
  'Peso paja (F)',
  'Peso mosca (F)',
  'Peso gallo (F)',
];

/// Convierte "Lightweight", "Women's Strawweight"... al nombre en español.
String weightLabel(String raw) {
  final r = raw.toLowerCase();
  final women = r.contains('women');
  String base;
  if (r.contains('light heavy') || r.contains('semipesado')) {
    base = 'Peso semipesado';
  } else if (r.contains('heavy') || r.contains('pesado')) {
    base = 'Peso pesado';
  } else if (r.contains('welter') || r.contains('wélter')) {
    base = 'Peso wélter';
  } else if (r.contains('middle') || r.contains('mediano')) {
    base = 'Peso mediano';
  } else if (r.contains('light') || r.contains('ligero')) {
    base = 'Peso ligero';
  } else if (r.contains('feather') || r.contains('pluma')) {
    base = 'Peso pluma';
  } else if (r.contains('bantam') || r.contains('gallo')) {
    base = 'Peso gallo';
  } else if (r.contains('fly') || r.contains('mosca')) {
    base = 'Peso mosca';
  } else if (r.contains('straw') || r.contains('paja')) {
    base = 'Peso paja';
  } else {
    return raw.isEmpty ? 'Otras' : raw;
  }
  if (r.contains('(f)')) return '$base (F)';
  return women ? '$base (F)' : base;
}

Team teamFromStanding(StandingRow r, Sport sport, String leagueName) {
  final id = 'espn_${r.teamId}';
  teamLeague[id] = leagueName;
  String short(String name) {
    final w = name.split(' ').where((x) => x.isNotEmpty).toList();
    if (w.length >= 2) return w.take(3).map((x) => x[0]).join().toUpperCase();
    return (name.length >= 3 ? name.substring(0, 3) : name).toUpperCase();
  }

  return Team(
    id: id,
    name: r.name,
    short: short(r.name),
    sport: sport,
    crestUrl: r.logo,
    color: _hex(null, r.teamId),
    country: leagueName,
  );
}

League? leagueByKey(String key) {
  for (final l in leagues) {
    if (l.key == key) return l;
  }
  return null;
}

/// Liga para sacar la tabla de un partido (los DEMO usan LaLiga o NBA).
League? leagueFor(MatchItem m) {
  if (m.leagueKey != 'demo') return leagueByKey(m.leagueKey);
  if (m.sport == Sport.football) return leagueByKey('esp.1');
  if (m.sport == Sport.basketball) return leagueByKey('nba');
  return null;
}

// ───────── ayudas para leer JSON sin que explote ─────────
dynamic _at(dynamic o, List<Object> path) {
  var cur = o;
  for (final k in path) {
    if (k is int) {
      if (cur is List && k >= 0 && k < cur.length) {
        cur = cur[k];
      } else {
        return null;
      }
    } else {
      if (cur is Map) {
        cur = cur[k];
      } else {
        return null;
      }
    }
  }
  return cur;
}

String? _s(dynamic o, List<Object> path) {
  final v = _at(o, path);
  return v?.toString();
}

/// Todas las llamadas a ESPN pasan por aquí: timeout de 10 s y try-catch.
Future<Map<String, dynamic>?> _getJson(String url) async {
  try {
    final d = await Net.getJson(url);
    return d is Map<String, dynamic> ? d : null;
  } catch (e) {
    Net.lastError = 'ESPN: $e';
    return null;
  }
}

String _ymd(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

String _two(int n) => n.toString().padLeft(2, '0');

String _fmt(DateTime d) => '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';

Color _hex(String? hex, String seed) {
  if (hex != null && hex.length == 6) {
    final v = int.tryParse('FF$hex', radix: 16);
    if (v != null) return Color(v);
  }
  final h = seed.hashCode.abs() % 360;
  return HSLColor.fromAHSL(1, h.toDouble(), 0.5, 0.42).toColor();
}

String _short(String name) {
  final words = name.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.length >= 2) return words.take(3).map((w) => w[0]).join().toUpperCase();
  return (name.length >= 3 ? name.substring(0, 3) : name).toUpperCase();
}

String _cleanForm(String? f) => (f ?? '').toUpperCase().replaceAll(RegExp(r'[^WDL]'), '');

class EspnApi {
  static final Set<String> loaded = {};
  static final Map<String, List<StandingRow>> _standings = {};

  // ───────────────────────── MARCADORES ─────────────────────────

  /// Carga los partidos (o peleas) de una liga. Devuelve false si falló internet.
  static Future<bool> loadLeague(League l) async {
    try {
      return await _loadLeague(l);
    } catch (e) {
      // Si ESPN cambia el formato, la app no se cae: se queda con lo que tenía.
      Net.lastError = 'ESPN (${l.name}): $e';
      return false;
    }
  }

  static Future<bool> _loadLeague(League l) async {
    final now = DateTime.now();
    final a = _ymd(now.subtract(Duration(days: l.daysBack)));
    final b = _ymd(now.add(Duration(days: l.daysForward)));
    final data = await _getJson('$espnSite/${l.path}/scoreboard?dates=$a-$b&limit=300');
    if (data == null) return false;
    final events = data['events'];
    if (events is! List) return false;

    if (l.sport == Sport.ufc) {
      final list = _parseUfc(events, l);
      fights.removeWhere((f) => f.leagueKey == l.key);
      fights.addAll(list);
      for (final f in list) {
        for (final x in [f.red, f.blue]) {
          if (!allFollowables.any((t) => t.id == x.id)) {
            allFollowables.add(Team(
              id: x.id,
              name: x.name,
              short: x.initials,
              sport: Sport.ufc,
              crestUrl: x.imageUrl,
              color: x.color,
              country: weightLabel(f.weightClass),
            ));
          }
          teamLeague[x.id] = 'UFC';
        }
      }
    } else {
      final list = <MatchItem>[];
      for (final e in events) {
        final m = l.sport == Sport.tennis ? null : _parseMatch(e, l);
        if (m != null) list.add(m);
      }
      if (l.sport == Sport.tennis) list.addAll(_parseTennis(events, l));

      // Conserva lo ya cargado (cronología, alineaciones...) de los mismos partidos.
      final old = {for (final m in matches.where((m) => m.leagueKey == l.key)) m.id: m};
      // Los partidos publicados a mano por un admin (manual_*) no se borran.
      matches.removeWhere((m) => m.leagueKey == l.key && !m.id.startsWith('manual_'));
      for (final m in list) {
        final o = old[m.id];
        if (o != null && o.detailsLoaded) {
          m.events.addAll(o.events);
          m.homeLineup = o.homeLineup;
          m.awayLineup = o.awayLineup;
          m.stats = o.stats;
          m.h2h.addAll(o.h2h);
          m.probHome = o.probHome;
          m.probDraw = o.probDraw;
          m.probAway = o.probAway;
          m.probSource = o.probSource;
          m.detailsLoaded = true;
          if (m.homeForm.isEmpty) m.homeForm = o.homeForm;
          if (m.awayForm.isEmpty) m.awayForm = o.awayForm;
        }
      }
      matches.addAll(list);
      for (final m in list) {
        for (final t in [m.home, m.away]) {
          teamLeague[t.id] = l.name;
          if (!allFollowables.any((x) => x.id == t.id)) allFollowables.add(t);
        }
      }
    }
    loaded.add(l.key);
    liveSim.refresh();
    return true;
  }

  /// Carga TODOS los equipos de cada liga (fútbol y NBA) para buscarlos,
  /// seguirlos y vestir el avatar con su ropa. Usa `/teams` de ESPN
  /// (escudo, colores oficiales) y, si falla, la tabla de posiciones.
  static Future<void> loadAllTeams() async {
    await Future.wait(leagues.where((l) => l.sport == Sport.football || l.sport == Sport.basketball).map((l) async {
      try {
        var teams = await _teamsOf(l);
        if (teams.isEmpty) {
          teams = [for (final r in await standings(l)) teamFromStanding(r, l.sport, l.name)];
        }
        for (final t in teams) {
          _mergeTeam(t, l.name);
        }
      } catch (e) {
        Net.lastError = 'Equipos ${l.name}: $e';
      }
    }));
    liveSim.refresh();
  }

  static Future<List<Team>> _teamsOf(League l) async {
    final data = await _getJson('$espnSite/${l.path}/teams?limit=200');
    final list = _at(data, ['sports', 0, 'leagues', 0, 'teams']);
    if (list is! List) return [];
    final out = <Team>[];
    for (final e in list) {
      final t = _at(e, ['team']);
      final id = _s(t, ['id']);
      final name = _s(t, ['displayName']);
      if (id == null || name == null) continue;
      final alt = _s(t, ['alternateColor']);
      out.add(Team(
        id: 'espn_$id',
        name: name,
        short: _s(t, ['abbreviation']) ?? _short(name),
        sport: l.sport,
        crestUrl: _s(t, ['logos', 0, 'href']),
        color: _hex(_s(t, ['color']), id),
        altColor: alt == null || alt.length != 6 ? null : _hex(alt, id),
        country: l.name,
      ));
    }
    return out;
  }

  /// Agrega el equipo; si ya existía uno con el mismo nombre (de ejemplo),
  /// le pone el escudo y los colores oficiales de ESPN sin cambiarle el id
  /// (así no se pierden los favoritos).
  static void _mergeTeam(Team t, String leagueName) {
    final i = allFollowables.indexWhere((x) => x.id == t.id || (x.sport == t.sport && x.name.toLowerCase() == t.name.toLowerCase()));
    if (i < 0) {
      allFollowables.add(t);
      teamLeague[t.id] = leagueName;
      return;
    }
    final old = allFollowables[i];
    allFollowables[i] = old.copyWith(crestUrl: t.crestUrl ?? old.crestUrl, color: t.color, altColor: t.altColor ?? old.altColor);
    teamLeague[old.id] = teamLeague[old.id] ?? leagueName;
  }

  static Future<void> loadAll() async {
    await Future.wait(leagues.map((l) => loadLeague(l).catchError((_) => false)));
  }

  static MatchItem? _parseMatch(dynamic ev, League l) {
    final comp = _at(ev, ['competitions', 0]);
    final comps = _at(comp, ['competitors']);
    if (comp == null || comps is! List || comps.length < 2) return null;

    dynamic home, away;
    for (final c in comps) {
      if (c is Map && c['homeAway'] == 'home') home = c;
      if (c is Map && c['homeAway'] == 'away') away = c;
    }
    if (home == null || away == null) return null;

    Team team(dynamic c) {
      final t = c['team'];
      final id = _s(t, ['id']) ?? '0';
      final name = _s(t, ['displayName']) ?? 'Equipo';
      return Team(
        id: 'espn_$id',
        name: name,
        short: _s(t, ['abbreviation']) ?? _short(name),
        sport: l.sport,
        crestUrl: _s(t, ['logo']),
        color: _hex(_s(t, ['color']), id),
      );
    }

    final state = _s(ev, ['status', 'type', 'state']) ?? 'pre';
    final status = state == 'in'
        ? MatchStatus.live
        : state == 'post'
            ? MatchStatus.finished
            : MatchStatus.upcoming;
    final kickoff = DateTime.tryParse(_s(ev, ['date']) ?? '')?.toLocal();

    return MatchItem(
      id: 'espn_${l.key}_${_s(ev, ['id'])}',
      sport: l.sport,
      competition: l.name,
      home: team(home),
      away: team(away),
      homeScore: int.tryParse(_s(home, ['score']) ?? '') ?? 0,
      awayScore: int.tryParse(_s(away, ['score']) ?? '') ?? 0,
      status: status,
      clock: _clock(ev, l.sport, status, kickoff),
      kickoff: kickoff,
      leagueKey: l.key,
      espnPath: l.path,
      espnId: _s(ev, ['id']),
      venue: _s(comp, ['venue', 'fullName']),
      homeForm: _cleanForm(_s(home, ['form'])),
      awayForm: _cleanForm(_s(away, ['form'])),
    );
  }

  static String _clock(dynamic ev, Sport sport, MatchStatus status, DateTime? kickoff) {
    switch (status) {
      case MatchStatus.upcoming:
        return kickoff == null ? 'Por definir' : _fmt(kickoff);
      case MatchStatus.finished:
        return kickoff == null ? 'FINAL' : 'FINAL · ${_two(kickoff.day)}/${_two(kickoff.month)}';
      case MatchStatus.live:
        final name = _s(ev, ['status', 'type', 'name']) ?? '';
        if (name.contains('HALF') && !name.contains('IN')) return 'Descanso';
        if (sport == Sport.football) return _s(ev, ['status', 'displayClock']) ?? 'En vivo';
        return _s(ev, ['status', 'type', 'shortDetail']) ?? 'En vivo';
    }
  }

  // ───────────────────────── UFC ─────────────────────────
  static List<Fight> _parseUfc(List events, League l) {
    final out = <Fight>[];
    for (final ev in events) {
      final eventName = _s(ev, ['shortName']) ?? _s(ev, ['name']) ?? 'UFC';
      final comps = _at(ev, ['competitions']);
      if (comps is! List) continue;
      // Del final de la cartelera (estelar) al principio.
      final bouts = comps.reversed.toList();
      for (var i = 0; i < bouts.length; i++) {
        final c = bouts[i];
        final cs = _at(c, ['competitors']);
        if (cs is! List || cs.length < 2) continue;
        final sorted = [...cs]..sort((a, b) =>
            (int.tryParse(_s(a, ['order']) ?? '') ?? 0).compareTo(int.tryParse(_s(b, ['order']) ?? '') ?? 0));
        Fighter fighter(dynamic x, Color color) {
          final name = _s(x, ['athlete', 'displayName']) ?? _s(x, ['athlete', 'fullName']) ?? 'Peleador';
          return Fighter(
            id: 'espn_a_${_s(x, ['id'])}',
            name: name,
            nickname: '',
            record: _s(x, ['records', 0, 'summary']) ?? '',
            flag: '',
            color: color,
            imageUrl: _s(x, ['athlete', 'headshot', 'href']),
          );
        }

        final red = fighter(sorted[0], const Color(0xFFE74C3C));
        final blue = fighter(sorted[1], const Color(0xFF3498DB));
        final state = _s(c, ['status', 'type', 'state']) ?? _s(ev, ['status', 'type', 'state']) ?? 'pre';
        final status = state == 'in'
            ? MatchStatus.live
            : state == 'post'
                ? MatchStatus.finished
                : MatchStatus.upcoming;

        Fighter? winner;
        if (sorted[0]['winner'] == true) winner = red;
        if (sorted[1]['winner'] == true) winner = blue;

        final resultText = (_s(c, ['status', 'result', 'displayName']) ??
                _s(c, ['status', 'result', 'name']) ??
                _s(c, ['status', 'type', 'detail']) ??
                '')
            .toLowerCase();
        FightMethod? method;
        if (winner != null) {
          if (resultText.contains('sub')) {
            method = FightMethod.submission;
          } else if (resultText.contains('dec')) {
            method = FightMethod.decision;
          } else if (resultText.contains('ko') || resultText.contains('tko')) {
            method = FightMethod.ko;
          } else {
            method = FightMethod.decision;
          }
        }
        final round = int.tryParse(_s(c, ['status', 'period']) ?? '');
        final time = _s(c, ['status', 'displayClock']);
        final date = DateTime.tryParse(_s(ev, ['date']) ?? '')?.toLocal();

        out.add(Fight(
          id: 'espn_ufc_${_s(c, ['id'])}',
          eventName: eventName,
          weightClass: weightLabel(_s(c, ['type', 'text']) ?? _s(c, ['type', 'abbreviation']) ?? ''),
          red: red,
          blue: blue,
          status: status,
          clock: status == MatchStatus.live
              ? 'Round ${round ?? '-'} · ${time ?? ''}'
              : status == MatchStatus.finished
                  ? 'FINAL'
                  : (date == null ? 'Por definir' : _fmt(date)),
          winner: winner,
          method: method,
          methodDetail: method == null ? null : (_s(c, ['status', 'result', 'displayName']) ?? ''),
          round: round,
          time: time,
          leagueKey: l.key,
          date: date,
        ));
      }
    }
    return out;
  }

  // ───────────────────────── TENIS ─────────────────────────
  static List<MatchItem> _parseTennis(List events, League l) {
    final out = <MatchItem>[];
    for (final ev in events) {
      final tournament = _s(ev, ['name']) ?? 'ATP';
      final groupings = _at(ev, ['groupings']);
      final comps = <dynamic>[];
      if (groupings is List) {
        for (final g in groupings) {
          final cs = _at(g, ['competitions']);
          if (cs is List) comps.addAll(cs);
        }
      } else {
        final cs = _at(ev, ['competitions']);
        if (cs is List) comps.addAll(cs);
      }
      for (final c in comps) {
        final cs = _at(c, ['competitors']);
        if (cs is! List || cs.length < 2) continue;
        final p1 = cs[0], p2 = cs[1];
        Team player(dynamic x) {
          final name = _s(x, ['athlete', 'displayName']) ?? 'Jugador';
          return Team(
            id: 'espn_p_${_s(x, ['id'])}',
            name: name,
            short: _short(name),
            sport: Sport.tennis,
            crestUrl: _s(x, ['athlete', 'headshot', 'href']),
            color: _hex(null, name),
            country: '',
          );
        }

        final s1 = <int>[], s2 = <int>[];
        for (final ls in (_at(p1, ['linescores']) as List? ?? [])) {
          s1.add((double.tryParse(_s(ls, ['value']) ?? '') ?? 0).toInt());
        }
        for (final ls in (_at(p2, ['linescores']) as List? ?? [])) {
          s2.add((double.tryParse(_s(ls, ['value']) ?? '') ?? 0).toInt());
        }
        var w1 = 0, w2 = 0;
        for (var i = 0; i < math.min(s1.length, s2.length); i++) {
          if (s1[i] > s2[i]) w1++;
          if (s2[i] > s1[i]) w2++;
        }
        final detail = [for (var i = 0; i < math.min(s1.length, s2.length); i++) '${s1[i]}-${s2[i]}'].join('  ');

        final state = _s(c, ['status', 'type', 'state']) ?? 'pre';
        final status = state == 'in'
            ? MatchStatus.live
            : state == 'post'
                ? MatchStatus.finished
                : MatchStatus.upcoming;
        final date = DateTime.tryParse(_s(c, ['date']) ?? _s(c, ['startDate']) ?? '')?.toLocal();

        out.add(MatchItem(
          id: 'espn_atp_${_s(c, ['id'])}',
          sport: Sport.tennis,
          competition: tournament,
          home: player(p1),
          away: player(p2),
          homeScore: w1,
          awayScore: w2,
          status: status,
          clock: status == MatchStatus.live
              ? 'En vivo'
              : status == MatchStatus.finished
                  ? 'FINAL'
                  : (date == null ? 'Por definir' : _fmt(date)),
          detail: detail.isEmpty ? null : detail,
          kickoff: date,
          leagueKey: l.key,
        ));
      }
    }
    return out;
  }

  // ───────────────────────── DETALLE DEL PARTIDO ─────────────────────────

  /// Pide el resumen: cronología, alineaciones, estadísticas, rachas, cara a cara.
  static Future<bool> loadSummary(MatchItem m) async {
    if (m.espnPath == null || m.espnId == null) return false;
    try {
      return await _loadSummary(m);
    } catch (e) {
      Net.lastError = 'ESPN resumen: $e';
      return false;
    }
  }

  static Future<bool> _loadSummary(MatchItem m) async {
    final d = await _getJson('$espnSite/${m.espnPath}/summary?event=${m.espnId}');
    if (d == null) return false;
    _applyHeader(m, d);
    _applyEvents(m, d);
    _applyLineups(m, d);
    _applyStats(m, d);
    _applyForm(m, d);
    _applyH2H(m, d);
    _applyPredictor(m, d);
    m.detailsLoaded = true;
    liveSim.refresh();
    return true;
  }

  static String _raw(Team t) => t.id.replaceFirst('espn_', '');

  static void _applyHeader(MatchItem m, Map<String, dynamic> d) {
    final comp = _at(d, ['header', 'competitions', 0]);
    final cs = _at(comp, ['competitors']);
    if (cs is List) {
      for (final c in cs) {
        final sc = int.tryParse(_s(c, ['score']) ?? '');
        if (sc == null) continue;
        if (c['homeAway'] == 'home') m.homeScore = sc;
        if (c['homeAway'] == 'away') m.awayScore = sc;
      }
    }
    final state = _s(comp, ['status', 'type', 'state']);
    if (state == 'in') {
      m.status = MatchStatus.live;
      m.clock = m.sport == Sport.football
          ? (_s(comp, ['status', 'displayClock']) ?? m.clock)
          : (_s(comp, ['status', 'type', 'shortDetail']) ?? m.clock);
    } else if (state == 'post') {
      m.status = MatchStatus.finished;
      if (!m.clock.startsWith('FINAL')) m.clock = 'FINAL';
    }
    m.venue ??= _s(d, ['gameInfo', 'venue', 'fullName']);
  }

  static void _applyEvents(MatchItem m, Map<String, dynamic> d) {
    final out = <MatchEvent>[];
    final homeRaw = _raw(m.home);

    if (m.sport == Sport.football) {
      final list = d['keyEvents'];
      if (list is List) {
        for (final e in list) {
          final ty = (_s(e, ['type', 'text']) ?? '').toLowerCase();
          final names = <String>[];
          final parts = _at(e, ['participants']);
          if (parts is List) {
            for (final p in parts) {
              final n = _s(p, ['athlete', 'displayName']);
              if (n != null) names.add(n);
            }
          }
          final side = _s(e, ['team', 'id']) == null
              ? EventSide.none
              : (_s(e, ['team', 'id']) == homeRaw ? EventSide.home : EventSide.away);
          final minute = _s(e, ['clock', 'displayValue']) ?? '';
          final shortText = _s(e, ['shortText']) ?? _s(e, ['text']) ?? ty;
          EventType t;
          String text;
          if (ty.contains('goal') || ty.contains('scored') || e['scoringPlay'] == true) {
            t = EventType.goal;
            text = names.isEmpty
                ? shortText
                : 'Gol de ${names[0]}${names.length > 1 ? ' (asist. ${names[1]})' : ''}';
          } else if (ty.contains('yellow card')) {
            t = EventType.yellow;
            text = names.isEmpty ? shortText : 'Amarilla para ${names[0]}';
          } else if (ty.contains('red card')) {
            t = EventType.red;
            text = names.isEmpty ? shortText : 'Roja para ${names[0]}';
          } else if (ty.contains('substitution')) {
            t = EventType.sub;
            text = names.length >= 2 ? 'Entra ${names[0]}, sale ${names[1]}' : shortText;
          } else if (ty.contains('kickoff') || ty.contains('half') || ty.contains('full time') || ty.contains('end')) {
            t = EventType.period;
            text = shortText;
          } else {
            t = EventType.info;
            text = shortText;
          }
          if (text.length > 140) text = '${text.substring(0, 137)}...';
          out.add(MatchEvent(minute, t, side, text));
        }
      }
    } else if (m.sport == Sport.basketball) {
      final plays = d['plays'];
      if (plays is List) {
        final scoring = plays.where((p) => p is Map && p['scoringPlay'] == true).toList();
        final tail = scoring.length > 60 ? scoring.sublist(scoring.length - 60) : scoring;
        for (final p in tail) {
          final teamId = _s(p, ['team', 'id']);
          final side = teamId == null ? EventSide.none : (teamId == homeRaw ? EventSide.home : EventSide.away);
          final q = _s(p, ['period', 'number']) ?? '';
          final clock = _s(p, ['clock', 'displayValue']) ?? '';
          var text = _s(p, ['text']) ?? '';
          if (text.length > 110) text = '${text.substring(0, 107)}...';
          out.add(MatchEvent('Q$q $clock', EventType.basket, side, text));
        }
      }
    }

    if (out.isNotEmpty) {
      m.events
        ..clear()
        ..addAll(out);
    }
  }

  static String _pos(String? abbr) {
    final a = (abbr ?? '').toUpperCase();
    if (a.isEmpty) return '';
    if (a == 'SUB') return 'SUP';
    if (a.startsWith('G')) return 'POR';
    if (a.contains('D') || a.contains('B')) return 'DEF';
    if (a.contains('M')) return 'MED';
    if (a.contains('F') || a.contains('S') || a.contains('W')) return 'DEL';
    return a;
  }

  static void _applyLineups(MatchItem m, Map<String, dynamic> d) {
    if (m.sport == Sport.football) {
      final rosters = d['rosters'];
      if (rosters is! List) return;
      for (final r in rosters) {
        final isHome = r['homeAway'] == 'home';
        final list = _at(r, ['roster']);
        if (list is! List || list.isEmpty) continue;
        final formation = (r['formation'] is String ? r['formation'] as String : _s(r, ['formation', 'name'])) ?? '4-4-2';

        final starters = <MapEntry<int, LineupPlayer>>[];
        final bench = <LineupPlayer>[];
        for (final p in list) {
          final player = LineupPlayer(
            int.tryParse(_s(p, ['jersey']) ?? '') ?? 0,
            _s(p, ['athlete', 'displayName']) ?? 'Jugador',
            _pos(_s(p, ['position', 'abbreviation'])),
            photoUrl: _s(p, ['athlete', 'headshot', 'href']),
          );
          if (p['starter'] == true) {
            starters.add(MapEntry(int.tryParse(_s(p, ['formationPlace']) ?? '') ?? 99, player));
          } else {
            bench.add(player);
          }
        }
        starters.sort((a, b) => a.key.compareTo(b.key));
        if (starters.isEmpty) continue;
        final lineup = Lineup(formation, starters.map((e) => e.value).toList(), bench);
        if (isHome) {
          m.homeLineup = lineup;
        } else {
          m.awayLineup = lineup;
        }
      }
    } else if (m.sport == Sport.basketball) {
      final blocks = _at(d, ['boxscore', 'players']);
      if (blocks is! List) return;
      final homeRaw = _raw(m.home);
      for (final b in blocks) {
        final isHome = _s(b, ['team', 'id']) == homeRaw;
        final st = _at(b, ['statistics', 0]);
        final athletes = _at(st, ['athletes']);
        final labelsRaw = _at(st, ['labels']) ?? _at(st, ['names']);
        if (athletes is! List || labelsRaw is! List) continue;
        final labels = labelsRaw.map((e) => e.toString().toUpperCase()).toList();
        int idx(List<String> names) {
          for (final n in names) {
            final i = labels.indexOf(n);
            if (i >= 0) return i;
          }
          return -1;
        }

        final iMin = idx(['MIN', 'MINUTES']);
        final iPts = idx(['PTS', 'POINTS']);
        final iReb = idx(['REB', 'REBOUNDS']);
        final iAst = idx(['AST', 'ASSISTS']);
        final iFg = idx(['FG', 'FIELDGOALSMADE-FIELDGOALSATTEMPTED']);
        final iFt = idx(['FT', 'FREETHROWSMADE-FREETHROWSATTEMPTED']);
        final iOreb = idx(['OREB', 'OFFENSIVEREBOUNDS']);
        final iDreb = idx(['DREB', 'DEFENSIVEREBOUNDS']);
        final iStl = idx(['STL', 'STEALS']);
        final iBlk = idx(['BLK', 'BLOCKS']);
        final iTo = idx(['TO', 'TURNOVERS']);
        final iPf = idx(['PF', 'FOULS']);

        final starters = <LineupPlayer>[];
        final bench = <LineupPlayer>[];
        for (final a in athletes) {
          final stats = _at(a, ['stats']);
          if (stats is! List || stats.isEmpty) continue;
          double n(int i) => i < 0 || i >= stats.length ? 0 : (double.tryParse(stats[i].toString()) ?? 0);
          List<double> pair(int i) {
            if (i < 0 || i >= stats.length) return [0, 0];
            final p = stats[i].toString().split('-');
            if (p.length != 2) return [0, 0];
            return [double.tryParse(p[0]) ?? 0, double.tryParse(p[1]) ?? 0];
          }

          final minutes = n(iMin);
          final pts = n(iPts);
          final fg = pair(iFg), ft = pair(iFt);
          // Nota calculada con la fórmula "Game Score" (a partir de sus estadísticas).
          final gmsc = pts + 0.4 * fg[0] - 0.7 * fg[1] - 0.4 * (ft[1] - ft[0]) + 0.7 * n(iOreb) + 0.3 * n(iDreb) +
              n(iStl) + 0.7 * n(iAst) + 0.7 * n(iBlk) - 0.4 * n(iPf) - n(iTo);
          final rating = minutes > 0 ? (5.8 + gmsc / 5).clamp(3.0, 10.0).toDouble() : 0.0;

          final player = LineupPlayer(
            int.tryParse(_s(a, ['athlete', 'jersey']) ?? '') ?? 0,
            _s(a, ['athlete', 'displayName']) ?? 'Jugador',
            _s(a, ['athlete', 'position', 'abbreviation']) ?? '',
            pts: pts.toInt(),
            reb: n(iReb).toInt(),
            ast: n(iAst).toInt(),
            rating: rating,
            photoUrl: _s(a, ['athlete', 'headshot', 'href']),
          );
          if (a['starter'] == true) {
            starters.add(player);
          } else if (minutes > 0) {
            bench.add(player);
          }
        }
        bench.sort((x, y) => y.pts.compareTo(x.pts));
        if (starters.isEmpty) continue;
        final lineup = Lineup('5', starters, bench.take(8).toList());
        if (isHome) {
          m.homeLineup = lineup;
        } else {
          m.awayLineup = lineup;
        }
      }
    }
  }

  static const _soccerStats = {
    'possessionPct': 'Posesión',
    'totalShots': 'Tiros',
    'shotsOnTarget': 'Tiros al arco',
    'wonCorners': 'Córners',
    'foulsCommitted': 'Faltas',
    'offsides': 'Fuera de juego',
    'yellowCards': 'Amarillas',
    'redCards': 'Rojas',
    'saves': 'Atajadas',
  };

  static const _basketStats = {
    'fieldGoalPct': 'Tiros de campo %',
    'threePointFieldGoalPct': 'Triples %',
    'freeThrowPct': 'Tiros libres %',
    'totalRebounds': 'Rebotes',
    'assists': 'Asistencias',
    'turnovers': 'Pérdidas',
    'steals': 'Robos',
    'blocks': 'Bloqueos',
  };

  static void _applyStats(MatchItem m, Map<String, dynamic> d) {
    final teams = _at(d, ['boxscore', 'teams']);
    if (teams is! List) return;
    final homeRaw = _raw(m.home);
    final home = <String, double>{}, away = <String, double>{};
    for (final t in teams) {
      final isHome = _s(t, ['team', 'id']) == homeRaw;
      final list = _at(t, ['statistics']);
      if (list is! List) continue;
      for (final s in list) {
        final name = _s(s, ['name']);
        final v = double.tryParse((_s(s, ['displayValue']) ?? '').replaceAll('%', ''));
        if (name == null || v == null) continue;
        (isHome ? home : away)[name] = v;
      }
    }
    final names = m.sport == Sport.football ? _soccerStats : _basketStats;
    final out = <StatRow>[];
    names.forEach((key, label) {
      if (home.containsKey(key) && away.containsKey(key)) {
        out.add(StatRow(label, home[key]!, away[key]!, percent: key.toLowerCase().contains('pct')));
      }
    });
    if (out.isNotEmpty) m.stats = out;
  }

  static void _applyForm(MatchItem m, Map<String, dynamic> d) {
    final list = _at(d, ['boxscore', 'form']);
    if (list is! List) return;
    final homeRaw = _raw(m.home);
    for (final f in list) {
      final events = _at(f, ['events']);
      if (events is! List) continue;
      final form = _cleanForm(events.take(5).map((e) => _s(e, ['gameResult']) ?? '').join());
      if (form.isEmpty) continue;
      if (_s(f, ['team', 'id']) == homeRaw) {
        m.homeForm = form;
      } else {
        m.awayForm = form;
      }
    }
  }

  static void _applyH2H(MatchItem m, Map<String, dynamic> d) {
    final list = d['headToHeadGames'];
    if (list is! List || list.isEmpty) return;
    final events = _at(list, [0, 'events']);
    if (events is! List) return;
    final names = {_raw(m.home): m.home.name, _raw(m.away): m.away.name};
    final out = <H2HGame>[];
    final seen = <String>{};
    for (final e in events) {
      final hId = _s(e, ['homeTeamId']), aId = _s(e, ['awayTeamId']);
      final hs = int.tryParse(_s(e, ['homeTeamScore']) ?? ''), as2 = int.tryParse(_s(e, ['awayTeamScore']) ?? '');
      if (hId == null || aId == null || hs == null || as2 == null) continue;
      final key = _s(e, ['id']) ?? '$hId$aId${_s(e, ['date'])}';
      if (!seen.add(key)) continue;
      final date = (_s(e, ['gameDate']) ?? _s(e, ['date']) ?? '');
      out.add(H2HGame(
        date: date.length >= 10 ? date.substring(0, 10) : date,
        homeId: 'espn_$hId',
        awayId: 'espn_$aId',
        homeName: names[hId] ?? 'Local',
        awayName: names[aId] ?? 'Visitante',
        homeScore: hs,
        awayScore: as2,
        competition: _s(e, ['leagueName']) ?? '',
      ));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    if (out.isNotEmpty) {
      m.h2h
        ..clear()
        ..addAll(out.take(10));
    }
  }

  static void _applyPredictor(MatchItem m, Map<String, dynamic> d) {
    final h = double.tryParse(_s(d, ['predictor', 'homeTeam', 'gameProjection']) ?? '');
    final a = double.tryParse(_s(d, ['predictor', 'awayTeam', 'gameProjection']) ?? '');
    if (h == null || a == null) return;
    m.probHome = h;
    m.probAway = a;
    m.probDraw = m.sport == Sport.football ? (100 - h - a).clamp(0, 100).toDouble() : 0;
    m.probSource = 'ESPN';
  }

  // ───────────────────────── CLASIFICACIÓN ─────────────────────────
  /// Tabla de la liga. Si hay una tabla publicada a mano por un admin, se usa
  /// cuando la API falla o cuando el modo emergencia está encendido.
  static Future<List<StandingRow>> standings(League l, {bool force = false}) async {
    final manual = emergencyStore.tableFor(l.key);
    if (manual != null && emergencyStore.active) return manual;
    List<StandingRow> rows;
    try {
      rows = await _standingsFromApi(l, force: force);
    } catch (e) {
      Net.lastError = 'ESPN tabla: $e';
      rows = [];
    }
    if (rows.isEmpty && manual != null) return manual;
    return rows;
  }

  /// Última tabla de la API que quedó guardada (para copiarla y editarla).
  static List<StandingRow>? cachedStandings(String leagueKey) => _standings[leagueKey];

  static Future<List<StandingRow>> _standingsFromApi(League l, {bool force = false}) async {
    if (!force && _standings.containsKey(l.key)) return _standings[l.key]!;
    var data = await _getJson('$espnV2/${l.path}/standings');
    if (data == null || (data['children'] == null && data['standings'] == null)) {
      data = await _getJson('$espnSite/${l.path}/standings');
    }
    final rows = <StandingRow>[];
    if (data != null) {
      final groups = data['children'];
      if (groups is List && groups.isNotEmpty) {
        for (final g in groups) {
          _readEntries(_at(g, ['standings', 'entries']), _s(g, ['name']) ?? '', rows);
        }
      } else {
        _readEntries(_at(data, ['standings', 'entries']), '', rows);
      }
    }
    if (rows.isNotEmpty) _standings[l.key] = rows;
    return rows;
  }

  static void _readEntries(dynamic entries, String group, List<StandingRow> out) {
    if (entries is! List) return;
    var i = 0;
    for (final e in entries) {
      i++;
      final stats = <String, double>{};
      final st = _at(e, ['stats']);
      if (st is List) {
        for (final s in st) {
          final n = _s(s, ['name']);
          final v = s is Map ? s['value'] : null;
          if (n != null && v is num) stats[n] = v.toDouble();
        }
      }
      int g(String k) => (stats[k] ?? 0).toInt();
      out.add(StandingRow(
        rank: stats.containsKey('rank') ? g('rank') : i,
        teamId: _s(e, ['team', 'id']) ?? '',
        name: _s(e, ['team', 'displayName']) ?? '',
        logo: _s(e, ['team', 'logos', 0, 'href']),
        played: g('gamesPlayed'),
        wins: g('wins'),
        draws: g('ties') + g('draws'),
        losses: g('losses'),
        gf: g('pointsFor'),
        ga: g('pointsAgainst'),
        points: stats.containsKey('points') ? g('points') : g('wins'),
        group: group,
      ));
    }
    out.sort((a, b) {
      final c = a.group.compareTo(b.group);
      return c != 0 ? c : a.rank.compareTo(b.rank);
    });
  }
}
