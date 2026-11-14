import 'package:flutter/material.dart';

enum Sport { football, basketball, ufc, tennis }

extension SportX on Sport {
  String get label => switch (this) {
        Sport.football => 'Fútbol',
        Sport.basketball => 'Básquetbol',
        Sport.ufc => 'UFC',
        Sport.tennis => 'Tenis',
      };

  IconData get icon => switch (this) {
        Sport.football => Icons.sports_soccer,
        Sport.basketball => Icons.sports_basketball,
        Sport.ufc => Icons.sports_mma,
        Sport.tennis => Icons.sports_tennis,
      };

  Color get color => switch (this) {
        Sport.football => const Color(0xFF2ECC71),
        Sport.basketball => const Color(0xFFFF8A1F),
        Sport.ufc => const Color(0xFFE74C3C),
        Sport.tennis => const Color(0xFFF1C40F),
      };
}

enum MatchStatus { live, finished, upcoming }

/// Equipo, club o jugador que se puede seguir.
class Team {
  final String id;
  final String name;
  final String short;
  final Sport sport;
  final String? crestUrl; // escudo oficial por URL (puede ser null)
  final Color color;
  final Color? altColor; // segundo color del club (para la ropa del avatar)
  final String country;

  const Team({
    required this.id,
    required this.name,
    required this.short,
    required this.sport,
    required this.color,
    this.altColor,
    this.crestUrl,
    this.country = '',
  });

  Team copyWith({String? crestUrl, Color? color, Color? altColor, String? country}) => Team(
        id: id,
        name: name,
        short: short,
        sport: sport,
        color: color ?? this.color,
        altColor: altColor ?? this.altColor,
        crestUrl: crestUrl ?? this.crestUrl,
        country: country ?? this.country,
      );
}

enum EventType {
  goal,
  yellow,
  red,
  sub,
  period,
  basket,
  strike,
  takedown,
  submissionTry,
  info
}

enum EventSide { home, away, none }

class MatchEvent {
  final String minute;
  final EventType type;
  final EventSide side;
  final String text;

  const MatchEvent(this.minute, this.type, this.side, this.text);
}

class LineupPlayer {
  final int number;
  final String name;
  final String pos;
  final int pts, reb, ast; // solo básquetbol
  final double rating; // nota de 0 a 10 (0 = sin nota)
  final String? photoUrl; // foto si la API la trae

  const LineupPlayer(this.number, this.name, this.pos,
      {this.pts = 0, this.reb = 0, this.ast = 0, this.rating = 0, this.photoUrl});
}

class Lineup {
  final String formation; // "4-3-3" (fútbol). En básquet: "5"
  final List<LineupPlayer> starters;
  final List<LineupPlayer> bench;

  const Lineup(this.formation, this.starters, this.bench);
}

class StatRow {
  final String label;
  final double home;
  final double away;
  final bool percent;

  const StatRow(this.label, this.home, this.away, {this.percent = false});
}

/// Una fila de la tabla de clasificación.
class StandingRow {
  final int rank;
  final String teamId; // id crudo de la API
  final String name;
  final String? logo;
  final int played, wins, draws, losses, gf, ga, points;
  final String group; // grupo / conferencia (NBA)

  const StandingRow({
    required this.rank,
    required this.teamId,
    required this.name,
    this.logo,
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.gf = 0,
    this.ga = 0,
    this.points = 0,
    this.group = '',
  });

  int get gd => gf - ga;
}

/// Un partido anterior entre los dos equipos.
class H2HGame {
  final String date; // 2025-03-15
  final String homeId, awayId; // Team.id
  final String homeName, awayName;
  final int homeScore, awayScore;
  final String competition;

  const H2HGame({
    required this.date,
    required this.homeId,
    required this.awayId,
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
    this.competition = '',
  });
}

/// Una liga o categoría que se puede elegir.
class League {
  final String key; // esp.1
  final String name;
  final String path; // soccer/esp.1
  final Sport sport;
  final String flag;
  final int daysBack, daysForward;

  const League(this.key, this.name, this.path, this.sport, this.flag,
      {this.daysBack = 7, this.daysForward = 7});
}

/// Partido de fútbol, básquetbol o tenis.
class MatchItem {
  final String id;
  final Sport sport;
  final String competition;
  final Team home;
  final Team away;
  int homeScore;
  int awayScore;
  MatchStatus status;
  String clock; // 67' | FINAL | Q3 5:42 | 25/10 20:00
  String? detail; // tenis: "6-4 3-6 7-5"
  final List<MatchEvent> events;
  Lineup? homeLineup;
  Lineup? awayLineup;
  List<StatRow> stats;
  final DateTime? kickoff;

  // --- datos reales (API) ---
  final String leagueKey; // 'demo' = datos de ejemplo
  final String? espnPath; // soccer/esp.1
  final String? espnId;
  String? venue;
  String homeForm; // 'WDLWW'
  String awayForm;
  final List<H2HGame> h2h;
  double? probHome, probDraw, probAway; // 0 a 100
  String probSource;
  bool detailsLoaded;

  MatchItem({
    required this.id,
    required this.sport,
    required this.competition,
    required this.home,
    required this.away,
    this.homeScore = 0,
    this.awayScore = 0,
    required this.status,
    required this.clock,
    this.detail,
    List<MatchEvent>? events,
    this.homeLineup,
    this.awayLineup,
    this.stats = const [],
    this.kickoff,
    this.leagueKey = 'demo',
    this.espnPath,
    this.espnId,
    this.venue,
    this.homeForm = '',
    this.awayForm = '',
    List<H2HGame>? h2h,
    this.probHome,
    this.probDraw,
    this.probAway,
    this.probSource = '',
    this.detailsLoaded = false,
  })  : events = events ?? [],
        h2h = h2h ?? [];
}

class ChatMessage {
  final String user;
  final String text;
  final DateTime time;
  final bool mine;
  final Color color;

  const ChatMessage(this.user, this.text, this.time, this.mine, this.color);
}

class Fighter {
  final String id;
  final String name;
  final String nickname;
  final String record;
  final String flag;
  final Color color;
  final String? imageUrl;

  const Fighter({
    required this.id,
    required this.name,
    required this.nickname,
    required this.record,
    required this.flag,
    required this.color,
    this.imageUrl,
  });

  String get initials {
    final parts = name.split(' ');
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get lastName => name.split(' ').last;
}

enum FightMethod { ko, submission, decision }

extension FightMethodX on FightMethod {
  String get label => switch (this) {
        FightMethod.ko => 'KO / TKO',
        FightMethod.submission => 'Sumisión',
        FightMethod.decision => 'Decisión unánime',
      };

  IconData get icon => switch (this) {
        FightMethod.ko => Icons.bolt,
        FightMethod.submission => Icons.back_hand,
        FightMethod.decision => Icons.gavel,
      };
}

class Fight {
  final String id;
  final String eventName;
  final String weightClass;
  final Fighter red;
  final Fighter blue;
  MatchStatus status;
  String clock; // FINAL | Round 3 · 2:10 | Sábado 22:00
  final Fighter? winner;
  final FightMethod? method;
  final String? methodDetail; // tipo de golpe o llave
  final int? round;
  final String? time;
  final List<int> redStrikes; // golpes conectados por round
  final List<int> blueStrikes;
  final List<StatRow> stats;
  final List<MatchEvent> events;
  final String leagueKey;
  final DateTime? date;

  Fight({
    required this.id,
    required this.eventName,
    required this.weightClass,
    required this.red,
    required this.blue,
    required this.status,
    required this.clock,
    this.winner,
    this.method,
    this.methodDetail,
    this.round,
    this.time,
    this.redStrikes = const [],
    this.blueStrikes = const [],
    this.stats = const [],
    this.events = const [],
    this.leagueKey = 'demo',
    this.date,
  });
}

class NewsItem {
  final String id;
  final Sport sport;
  final String title;
  final String summary;
  final String tag;
  final String ago;
  final String body;
  final String? url; // enlace a la nota real
  final String? imageUrl; // foto de la noticia (si la trae)
  final String source; // ESPN, Google Noticias, SportZone...

  const NewsItem({
    required this.id,
    required this.sport,
    required this.title,
    required this.summary,
    required this.tag,
    required this.ago,
    required this.body,
    this.url,
    this.imageUrl,
    this.source = '',
  });
}

/// Trofeos de la sala de racha.
enum TrophyKind { conference, europa, champions }

class BadgeItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final TrophyKind? trophy; // si no es null, se dibuja un trofeo

  const BadgeItem(this.id, this.name, this.description, this.icon, this.color,
      {this.trophy});
}
