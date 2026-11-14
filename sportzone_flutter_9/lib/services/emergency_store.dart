import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/user_models.dart';
import 'live_sim.dart';

/// Contenido de contingencia publicado a mano por un administrador.
///
/// Sirve para que la app siga mostrando resultados, tablas y noticias
/// aunque ESPN, TheSportsDB o Google Noticias se caigan por completo.
/// - Los partidos manuales se meten en la lista `matches` (salen en
///   Resultados, En vivo e Inicio como cualquier otro).
/// - Las tablas manuales reemplazan a la de la API si la API falla o si el
///   modo emergencia está encendido.
/// - Las noticias manuales salen fijadas arriba en Inicio.
/// TODO(firebase): colecciones `manual_matches`, `manual_tables`, `manual_news`.
class EmergencyStore extends ChangeNotifier {
  EmergencyStore._();
  static final EmergencyStore instance = EmergencyStore._();

  /// Modo emergencia: muestra un aviso y prioriza el contenido manual.
  bool active = false;
  String bannerText = 'Algunos proveedores de datos están caídos. Te mostramos resultados verificados por el equipo de SportZone.';

  final List<ManualNews> news = [];
  final Map<String, ManualStanding> tables = {};
  int _next = 1;

  List<MatchItem> get manualMatches => matches.where((m) => isManual(m)).toList();

  static bool isManual(MatchItem m) => m.id.startsWith('manual_');

  void setActive(bool v, {String? text}) {
    active = v;
    if (text != null && text.trim().isNotEmpty) bannerText = text.trim();
    notifyListeners();
    liveSim.refresh();
  }

  // ─────────────────────────── PARTIDOS ───────────────────────────

  MatchItem publishMatch({
    required League league,
    required Team home,
    required Team away,
    required int homeScore,
    required int awayScore,
    required MatchStatus status,
    required String clock,
    String? note,
    DateTime? kickoff,
  }) {
    final m = MatchItem(
      id: 'manual_${_next++}',
      sport: league.sport,
      competition: '${league.name} · Verificado',
      home: home,
      away: away,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
      clock: clock,
      detail: note == null || note.trim().isEmpty ? null : note.trim(),
      kickoff: kickoff ?? DateTime.now(),
      leagueKey: league.key,
    );
    matches.insert(0, m);
    _changed();
    return m;
  }

  void updateMatch(MatchItem m, {int? homeScore, int? awayScore, MatchStatus? status, String? clock}) {
    if (homeScore != null) m.homeScore = homeScore;
    if (awayScore != null) m.awayScore = awayScore;
    if (status != null) m.status = status;
    if (clock != null) m.clock = clock;
    _changed();
  }

  void removeMatch(MatchItem m) {
    matches.removeWhere((x) => x.id == m.id);
    _changed();
  }

  // ─────────────────────────── TABLAS ───────────────────────────

  void saveTable(String leagueKey, List<StandingRow> rows, AppUser admin) {
    final sorted = [...rows]..sort((a, b) {
        final p = b.points.compareTo(a.points);
        return p != 0 ? p : b.gd.compareTo(a.gd);
      });
    final ranked = [
      for (var i = 0; i < sorted.length; i++)
        StandingRow(
          rank: i + 1,
          teamId: sorted[i].teamId,
          name: sorted[i].name,
          logo: sorted[i].logo,
          played: sorted[i].played,
          wins: sorted[i].wins,
          draws: sorted[i].draws,
          losses: sorted[i].losses,
          gf: sorted[i].gf,
          ga: sorted[i].ga,
          points: sorted[i].points,
          group: sorted[i].group,
        ),
    ];
    tables[leagueKey] = ManualStanding(leagueKey, ranked, admin.username);
    _changed();
  }

  void removeTable(String leagueKey) {
    tables.remove(leagueKey);
    _changed();
  }

  /// Tabla manual de una liga (null si no hay).
  List<StandingRow>? tableFor(String leagueKey) => tables[leagueKey]?.rows;

  // ─────────────────────────── NOTICIAS ───────────────────────────

  void publishNews({
    required Sport sport,
    required String title,
    required String summary,
    required String body,
    String? imageUrl,
    String? url,
    required AppUser admin,
  }) {
    final item = NewsItem(
      id: 'manual_news_${_next++}',
      sport: sport,
      title: title.trim(),
      summary: summary.trim().isEmpty ? 'Publicado por SportZone' : summary.trim(),
      tag: 'DESTACADO',
      ago: 'Ahora',
      body: body.trim().isEmpty ? summary.trim() : body.trim(),
      imageUrl: imageUrl == null || !imageUrl.trim().startsWith('http') ? null : imageUrl.trim(),
      url: url == null || !url.trim().startsWith('http') ? null : url.trim(),
    );
    news.insert(0, ManualNews(item, admin.username));
    _changed();
  }

  void removeNews(ManualNews n) {
    news.remove(n);
    _changed();
  }

  void togglePin(ManualNews n) {
    n.pinned = !n.pinned;
    _changed();
  }

  /// Noticias manuales en el orden en que deben salir arriba del feed.
  List<NewsItem> get feedItems => [
        ...news.where((n) => n.pinned).map((n) => n.item),
        ...news.where((n) => !n.pinned).map((n) => n.item),
      ];

  void _changed() {
    notifyListeners();
    liveSim.refresh(); // las pantallas de partidos escuchan a liveSim
  }
}

final emergencyStore = EmergencyStore.instance;
