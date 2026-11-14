import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/espn_api.dart';
import '../services/live_sim.dart';
import '../services/net.dart';
import '../data/mock_data.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/match_tabs.dart';

/// Resultados: eliges la liga y ves marcadores en vivo, próximos y finales.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _key = 'esp.1'; // 'demo' = datos de ejemplo
  bool _loading = false;
  bool _failed = false;
  bool _showTable = false; // false = partidos, true = clasificación
  String? _weight; // categoría de peso UFC (null = todas)
  List<StandingRow> _table = [];
  bool _tableLoading = false;

  @override
  void initState() {
    super.initState();
    _select(_key);
  }

  Future<void> _select(String key, {bool force = false}) async {
    setState(() {
      _key = key;
      _failed = false;
      _weight = null;
      _table = [];
    });
    final l = leagueByKey(key);
    if (l == null) {
      setState(() => _showTable = false);
      return; // demo
    }
    final hasTable = l.sport == Sport.football || l.sport == Sport.basketball;
    if (!hasTable && _showTable) setState(() => _showTable = false);
    if (_showTable) _loadTable(l, force: force);
    if (EspnApi.loaded.contains(key) && !force) return;
    setState(() => _loading = true);
    final ok = await EspnApi.loadLeague(l);
    if (mounted) {
      setState(() {
        _loading = false;
        _failed = !ok;
      });
    }
  }

  Future<void> _loadTable(League l, {bool force = false}) async {
    setState(() => _tableLoading = true);
    final rows = await EspnApi.standings(l, force: force);
    if (mounted && _key == l.key) {
      setState(() {
        _table = rows;
        _tableLoading = false;
      });
    }
  }

  int _rank(MatchStatus s) => switch (s) {
        MatchStatus.live => 0,
        MatchStatus.upcoming => 1,
        MatchStatus.finished => 2,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _chips(context),
          _modeBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _select(_key, force: true),
              child: ListenableBuilder(
                listenable: liveSim,
                builder: (context, _) => _list(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barra extra: Partidos / Clasificación, o categorías de peso en la UFC.
  Widget _modeBar(BuildContext context) {
    final l = leagueByKey(_key);
    if (l == null) return const SizedBox(height: 8);

    if (l.sport == Sport.ufc) {
      final present = fights.where((f) => f.leagueKey == _key).map((f) => f.weightClass).toSet();
      final list = weightClasses.where(present.contains).toList();
      return SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          children: [
            for (final w in [null, ...list])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _weight == w,
                  showCheckmark: false,
                  label: Text(w ?? 'Todas las categorías'),
                  labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _weight == w ? AppColors.bg : null),
                  selectedColor: AppColors.green,
                  backgroundColor: context.cardColor2,
                  side: BorderSide(color: context.borderColor2),
                  onSelected: (_) => setState(() => _weight = w),
                ),
              ),
          ],
        ),
      );
    }

    final hasTable = l.sport == Sport.football || l.sport == Sport.basketball;
    if (!hasTable) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: false, label: Text('Partidos'), icon: Icon(Icons.scoreboard_outlined)),
          ButtonSegment(value: true, label: Text('Clasificación'), icon: Icon(Icons.leaderboard_outlined)),
        ],
        selected: {_showTable},
        onSelectionChanged: (v) {
          setState(() => _showTable = v.first);
          if (v.first && _table.isEmpty) _loadTable(l);
        },
      ),
    );
  }

  Widget _chips(BuildContext context) {
    Widget chip(String key, String label, String lead) {
      final on = _key == key;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          selected: on,
          showCheckmark: false,
          label: Text('$lead  $label'),
          labelStyle: TextStyle(fontWeight: FontWeight.w600, color: on ? AppColors.bg : null),
          selectedColor: AppColors.green,
          backgroundColor: context.cardColor2,
          side: BorderSide(color: context.borderColor2),
          onSelected: (_) => _select(key),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final l in leagues) chip(l.key, l.name, l.flag),
          chip('demo', 'Demo', '🧪'),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    final league = leagueByKey(_key);
    if (_showTable && league != null) {
      return TableTab(sport: league.sport, leagueName: league.name, table: _table, loading: _tableLoading);
    }
    final cards = <Widget>[];

    if (league?.sport == Sport.ufc || _key == 'demo') {
      final list = fights.where((f) => f.leagueKey == _key && (_weight == null || f.weightClass == _weight)).toList()
        ..sort((a, b) => _rank(a.status).compareTo(_rank(b.status)));
      for (final f in list) {
        cards.add(FightCard(fight: f));
      }
    }
    if (league?.sport != Sport.ufc) {
      final list = matches.where((m) => m.leagueKey == _key).toList()
        ..sort((a, b) {
          final r = _rank(a.status).compareTo(_rank(b.status));
          if (r != 0) return r;
          final da = a.kickoff ?? DateTime(2000), db = b.kickoff ?? DateTime(2000);
          // próximos: el más cercano primero; finales: el más reciente primero
          return a.status == MatchStatus.finished ? db.compareTo(da) : da.compareTo(db);
        });
      for (final m in list) {
        cards.add(MatchCard(match: m));
      }
    }
    if (_loading && cards.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 130, radius: 18))],
      );
    }

    if (cards.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(_failed ? Icons.wifi_off : Icons.event_busy, size: 46, color: context.muted),
                const SizedBox(height: 12),
                Text(
                  _failed
                      ? 'No pudimos conectar con el servidor de marcadores.\nDesliza hacia abajo para reintentar, o toca "Demo" para ver partidos de ejemplo.\n\nDetalle técnico: ${Net.lastError}'
                      : 'No hay partidos en estas fechas para esta liga.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: cards.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == cards.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _key == 'demo'
                  ? 'Datos de ejemplo'
                  : (matches.any((m) => m.leagueKey == _key && m.id.startsWith('manual_'))
                      ? 'Datos: ESPN + resultados verificados por SportZone'
                      : 'Datos: ESPN'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.muted),
            ),
          );
        }
        return cards[i];
      },
    );
  }
}
