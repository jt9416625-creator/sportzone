import '../models/models.dart';

/// Goles, asistencias y nota de un jugador, calculados con los eventos del
/// partido. Así, cuando cae un gol en vivo, el jugador sube de nota solo.
({int goals, int assists, double rating}) liveLine(MatchItem m, LineupPlayer p) {
  var g = 0, a = 0;
  for (final e in m.events) {
    if (e.type != EventType.goal) continue;
    if (e.text.contains('Gol de ${p.name}')) g++;
    if (e.text.contains('asist. ${p.name}')) a++;
  }
  final r = p.rating == 0 ? 0.0 : (p.rating + g * 0.6 + a * 0.4).clamp(0.0, 10.0).toDouble();
  return (goals: g, assists: a, rating: r);
}

/// Nota promedio del equipo (solo jugadores con nota).
double teamAverage(MatchItem m, Lineup l) {
  final notes = <double>[];
  for (final p in [...l.starters, ...l.bench]) {
    final r = liveLine(m, p).rating;
    if (r > 0) notes.add(r);
  }
  if (notes.isEmpty) return 0;
  return notes.reduce((a, b) => a + b) / notes.length;
}
