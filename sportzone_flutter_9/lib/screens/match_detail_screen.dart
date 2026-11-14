import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/predict.dart';
import '../core/ratings.dart';
import '../data/mock_data.dart';
import '../models/album_models.dart';
import '../models/models.dart';
import '../services/album_service.dart';
import '../services/espn_api.dart';
import '../services/live_sim.dart';
import '../widgets/common.dart';
import '../widgets/match_tabs.dart';
import '../widgets/pitch.dart';
import '../widgets/player_face.dart';

/// Detalle del partido: resumen, cronología, alineaciones, estadísticas,
/// previa, predicciones, chat, clasificación y cara a cara.
class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late final MatchItem m;
  List<StandingRow> _table = [];
  bool _tableLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    m = matches.firstWhere((x) => x.id == widget.matchId);
    album.track(MissionEvent.openMatch, uniqueKey: m.id); // misión "Mira 2 partidos"
    _load();
    // Partido en vivo: se actualiza solo cada 20 segundos.
    if (m.status != MatchStatus.finished && m.espnId != null) {
      _timer = Timer.periodic(const Duration(seconds: 20), (_) async {
        await EspnApi.loadSummary(m);
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _load() async {
    final league = leagueFor(m);
    await Future.wait([
      EspnApi.loadSummary(m),
      () async {
        if (league != null) _table = await EspnApi.standings(league);
      }(),
    ]);
    estimateProbabilities(m, _table);
    if (mounted) setState(() => _tableLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = m.sport == Sport.football || m.sport == Sport.basketball;
    final tabs = <(String, Widget)>[
      ('Resumen', SummaryTab(match: m)),
      ('Cronología', Timeline(events: m.events, homeLabel: m.home.short, awayLabel: m.away.short)),
      if (team) (m.sport == Sport.football ? 'Alineaciones' : 'Quintetos', m.sport == Sport.football ? _FootballLineups(match: m) : _BasketLineups(match: m)),
      if (team) ('Estadísticas', _Stats(match: m)),
      if (team) ('Previa', PreviewTab(match: m, table: _table)),
      if (team) ('Predicciones', PredictionsTab(match: m)),
      ('Chat', ChatPanel(roomId: m.id, home: m.home.name, away: m.away.name, live: m.status == MatchStatus.live)),
      if (team) ('Clasificación', TableTab(match: m, sport: m.sport, leagueName: leagueFor(m)?.name ?? '', table: _table, loading: _tableLoading)),
      if (team) ('Cara a cara', H2HTab(match: m)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(m.competition, style: const TextStyle(fontSize: 14)),
        ),
        body: ListenableBuilder(
          listenable: liveSim,
          builder: (context, _) {
            return Column(
              children: [
                _Header(match: m),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: context.accent,
                  labelColor: context.accent,
                  unselectedLabelColor: context.muted,
                  tabs: [for (final t in tabs) Tab(text: t.$1)],
                ),
                Expanded(
                  child: TabBarView(children: [for (final t in tabs) t.$2]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MatchItem match;
  const _Header({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final upcoming = m.status == MatchStatus.upcoming;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [m.home.color.withValues(alpha: 0.35), m.away.color.withValues(alpha: 0.35)],
        ),
        border: Border.all(color: context.borderColor2),
      ),
      child: Column(
        children: [
          if (m.status == MatchStatus.live) LiveBadge(clock: m.clock) else Text(m.clock, style: display(16, color: context.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _team(m.home)),
              if (upcoming)
                Text('VS', style: display(34, color: context.muted))
              else
                Column(
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      BouncyScore(value: m.homeScore, size: 58),
                      Text('  -  ', style: display(44, color: context.muted)),
                      BouncyScore(value: m.awayScore, size: 58),
                    ]),
                    if (m.detail != null) Text(m.detail!, style: TextStyle(color: context.muted)),
                  ],
                ),
              Expanded(child: _team(m.away)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _team(Team t) {
    return Column(
      children: [
        TeamCrest(team: t, size: 56),
        const SizedBox(height: 8),
        Text(t.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.muted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
          ],
        ),
      ),
    );
  }
}

/// Alineaciones de fútbol: cancha + nota del equipo + suplentes.
class _FootballLineups extends StatefulWidget {
  final MatchItem match;
  const _FootballLineups({required this.match});

  @override
  State<_FootballLineups> createState() => _FootballLineupsState();
}

class _FootballLineupsState extends State<_FootballLineups> {
  bool _home = true;

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final lineup = _home ? m.homeLineup : m.awayLineup;
    if (m.homeLineup == null || m.awayLineup == null || lineup == null) {
      return const _Empty(
        icon: Icons.groups_outlined,
        text: 'Las alineaciones todavía no están disponibles.\nSuelen publicarse cerca del inicio del partido.',
      );
    }
    final team = _home ? m.home : m.away;
    final hint = team.name.split(' ').last;
    final avg = teamAverage(m, lineup);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _toggle(context, m.home, true)),
            const SizedBox(width: 10),
            Expanded(child: _toggle(context, m.away, false)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Formación ${lineup.formation}', style: display(20, color: context.muted)),
            const Spacer(),
            if (avg > 0) ...[
              Text('Nota del equipo  ', style: TextStyle(color: context.muted, fontSize: 13)),
              RatingChip(avg),
            ],
          ],
        ),
        const SizedBox(height: 8),
        PitchView(lineup: lineup, shirt: team.color, match: m, teamHint: hint),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Row(mainAxisSize: MainAxisSize.min, children: [GoalBall(size: 18), SizedBox(width: 5), Text('Gol', style: TextStyle(fontSize: 12))]),
            const Row(mainAxisSize: MainAxisSize.min, children: [AssistDot(), SizedBox(width: 5), Text('Asistencia', style: TextStyle(fontSize: 12))]),
            Row(mainAxisSize: MainAxisSize.min, children: [const RatingChip(7.5, small: true), const SizedBox(width: 5), Text('Nota del jugador', style: TextStyle(fontSize: 12, color: context.muted))]),
          ],
        ),
        const SizedBox(height: 16),
        Text('SUPLENTES', style: display(20)),
        const SizedBox(height: 8),
        for (final p in lineup.bench) _benchRow(context, m, team, hint, p),
        const SizedBox(height: 4),
        Text('Datos de ejemplo', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.muted)),
      ],
    );
  }

  Widget _benchRow(BuildContext context, MatchItem m, Team team, String hint, LineupPlayer p) {
    final line = liveLine(m, p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          PlayerFace(name: p.name, sport: Sport.football, teamHint: hint, size: 36, color: team.color, fallbackText: '${p.number}'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('#${p.number} · ${p.pos}', style: TextStyle(color: context.muted, fontSize: 12)),
              ],
            ),
          ),
          if (line.goals > 0) Padding(padding: const EdgeInsets.only(right: 6), child: GoalBall(count: line.goals)),
          if (line.assists > 0) Padding(padding: const EdgeInsets.only(right: 6), child: AssistDot(count: line.assists)),
          if (line.rating > 0) RatingChip(line.rating),
        ]),
      ),
    );
  }

  Widget _toggle(BuildContext context, Team t, bool home) {
    final on = _home == home;
    return GestureDetector(
      onTap: () => setState(() => _home = home),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on ? AppColors.green.withValues(alpha: 0.15) : context.cardColor2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? context.accent : context.borderColor2, width: on ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TeamCrest(team: t, size: 24),
            const SizedBox(width: 8),
            Text(t.short, style: display(20)),
          ],
        ),
      ),
    );
  }
}

/// Quintetos de básquetbol con cara, estadísticas y nota.
class _BasketLineups extends StatelessWidget {
  final MatchItem match;
  const _BasketLineups({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    if (m.homeLineup == null || m.awayLineup == null) {
      return const _Empty(
        icon: Icons.groups_outlined,
        text: 'Los quintetos todavía no están disponibles.\nSuelen publicarse cerca del inicio del partido.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _table(context, m, m.home, m.homeLineup!),
        const SizedBox(height: 16),
        _table(context, m, m.away, m.awayLineup!),
        const SizedBox(height: 8),
        Text('Datos de ejemplo', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.muted)),
      ],
    );
  }

  Widget _table(BuildContext context, MatchItem m, Team t, Lineup l) {
    final hint = t.name.split(' ').last;
    final avg = teamAverage(m, l);

    Widget row(LineupPlayer p) {
      TextStyle s(bool strong) => TextStyle(fontSize: 13, fontWeight: strong ? FontWeight.w700 : FontWeight.w500);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          PlayerFace(name: p.name, sport: Sport.basketball, teamHint: hint, size: 34, color: t.color, fallbackText: '${p.number}'),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: s(true), overflow: TextOverflow.ellipsis),
                Text('#${p.number} · ${p.pos}', style: TextStyle(fontSize: 11, color: context.muted)),
              ],
            ),
          ),
          SizedBox(width: 30, child: Text('${p.pts}', textAlign: TextAlign.center, style: s(true))),
          SizedBox(width: 30, child: Text('${p.reb}', textAlign: TextAlign.center, style: s(false))),
          SizedBox(width: 30, child: Text('${p.ast}', textAlign: TextAlign.center, style: s(false))),
          SizedBox(width: 44, child: p.rating > 0 ? Center(child: RatingChip(p.rating, small: true)) : const SizedBox()),
        ]),
      );
    }

    Widget header(String label) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Row(children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: context.muted))),
            for (final h in ['PTS', 'REB', 'AST'])
              SizedBox(width: 30, child: Text(h, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.muted))),
            SizedBox(width: 44, child: Text('NOTA', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.muted))),
          ]),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TeamCrest(team: t, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text(t.name, style: display(22))),
            if (avg > 0) ...[
              Text('Nota  ', style: TextStyle(color: context.muted, fontSize: 12)),
              RatingChip(avg),
            ],
          ]),
          header('QUINTETO TITULAR'),
          for (final p in l.starters) row(p),
          const Divider(),
          header('BANCA'),
          for (final p in l.bench) row(p),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final MatchItem match;
  const _Stats({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    if (m.stats.isEmpty) {
      return const _Empty(icon: Icons.bar_chart, text: 'Todavía no hay estadísticas para este partido.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(m.home.short, style: display(22, color: m.home.color)),
            Text(m.away.short, style: display(22, color: m.away.color)),
          ],
        ),
        for (final r in m.stats) StatBar(row: r, homeColor: m.home.color, awayColor: m.away.color),
      ],
    );
  }
}
