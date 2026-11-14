import 'dart:math' as math;

import '../models/models.dart';

/// ¿Es la misma fila de la tabla que este equipo?
bool sameTeam(StandingRow r, Team t) {
  if (r.teamId.isNotEmpty && (t.id == r.teamId || t.id == 'espn_${r.teamId}')) return true;
  String n(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll('fc ', '')
      .replaceAll(' fc', '')
      .trim();
  final a = n(r.name), b = n(t.name);
  if (a.isEmpty || b.isEmpty) return false;
  return a == b || a.contains(b) || b.contains(a);
}

StandingRow? rowFor(List<StandingRow> table, Team t) {
  for (final r in table) {
    if (sameTeam(r, t)) return r;
  }
  return null;
}

/// Puntos por partido a partir de la racha (G=3, E=1, P=0).
double? _formPpg(String form) {
  if (form.isEmpty) return null;
  var pts = 0;
  for (final c in form.split('')) {
    if (c == 'W') pts += 3;
    if (c == 'D') pts += 1;
  }
  return pts / form.length;
}

/// Cuenta victorias del local, empates y victorias del visitante en el cara a cara.
({int home, int draws, int away}) h2hCounts(MatchItem m) {
  var h = 0, d = 0, a = 0;
  for (final g in m.h2h) {
    if (g.homeScore == g.awayScore) {
      d++;
      continue;
    }
    final winnerId = g.homeScore > g.awayScore ? g.homeId : g.awayId;
    if (winnerId == m.home.id) {
      h++;
    } else if (winnerId == m.away.id) {
      a++;
    }
  }
  return (home: h, draws: d, away: a);
}

/// Si la API no trae probabilidades, hacemos una estimación propia con la
/// tabla, la racha y el cara a cara. Es una estimación de SportZone, no oficial.
void estimateProbabilities(MatchItem m, List<StandingRow> table) {
  if (m.probHome != null) return;
  final football = m.sport == Sport.football;

  double strength(Team t, String form) {
    final row = rowFor(table, t);
    double? fromTable;
    if (row != null && row.played > 0) {
      fromTable = football ? row.points / row.played : row.wins / math.max(1, row.played) * 3;
    }
    final f = _formPpg(form);
    final fromForm = f;
    if (fromTable != null && fromForm != null) return fromTable * 0.6 + fromForm * 0.4;
    return fromTable ?? fromForm ?? (football ? 1.3 : 1.5);
  }

  final sh = strength(m.home, m.homeForm);
  final sa = strength(m.away, m.awayForm);
  final c = h2hCounts(m);
  final total = c.home + c.draws + c.away;
  final h2hBias = total == 0 ? 0.0 : (c.home - c.away) / total * 0.15;

  final d = (sh + (football ? 0.25 : 0.35)) - sa + h2hBias;
  final ph = 1 / (1 + math.exp(-d / (football ? 1.1 : 0.8)));

  if (football) {
    final draw = 0.29 - 0.07 * math.min(1.0, d.abs());
    final home = ((1 - draw) * ph * 100).round();
    final away = ((1 - draw) * (1 - ph) * 100).round();
    m.probHome = home.toDouble();
    m.probAway = away.toDouble();
    m.probDraw = (100 - home - away).toDouble();
  } else {
    final home = (ph * 100).round();
    m.probHome = home.toDouble();
    m.probAway = (100 - home).toDouble();
    m.probDraw = 0;
  }
  m.probSource = 'Estimación SportZone';
}
