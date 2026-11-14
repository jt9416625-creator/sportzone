import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/match_tabs.dart';

const _redCorner = Color(0xFFE74C3C);
const _blueCorner = Color(0xFF3498DB);

/// Detalle de una pelea de UFC: resultado, cronología y golpes.
class FightDetailScreen extends StatelessWidget {
  final String fightId;
  const FightDetailScreen({super.key, required this.fightId});

  @override
  Widget build(BuildContext context) {
    final f = fights.firstWhere((x) => x.id == fightId);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text('${f.eventName} · ${f.weightClass}', style: const TextStyle(fontSize: 14))),
        body: Column(
          children: [
            _FightHeader(fight: f),
            TabBar(
              indicatorColor: context.accent,
              labelColor: context.accent,
              unselectedLabelColor: context.muted,
              tabs: const [Tab(text: 'Cronología'), Tab(text: 'Golpes'), Tab(text: 'Chat')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Timeline(events: f.events, homeLabel: 'Esquina roja', awayLabel: 'Esquina azul'),
                  _StrikesTab(fight: f),
                  ChatPanel(roomId: f.id, home: f.red.name, away: f.blue.name, live: f.status == MatchStatus.live),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FightHeader extends StatelessWidget {
  final Fight fight;
  const _FightHeader({required this.fight});

  @override
  Widget build(BuildContext context) {
    final f = fight;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: [_redCorner.withValues(alpha: 0.28), _blueCorner.withValues(alpha: 0.28)]),
        border: Border.all(color: context.borderColor2),
      ),
      child: Column(
        children: [
          if (f.status == MatchStatus.live) LiveBadge(clock: f.clock) else Text(f.clock, style: display(16, color: context.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _fighter(context, f.red, _redCorner)),
              Text('VS', style: display(32, color: context.muted)),
              Expanded(child: _fighter(context, f.blue, _blueCorner)),
            ],
          ),
          if (f.winner != null && f.method != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.7)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(f.method!.icon, color: context.accent),
                      const SizedBox(width: 8),
                      Text('GANA ${f.winner!.name.toUpperCase()}', style: display(24, color: context.accent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (f.methodDetail == null || f.methodDetail!.isEmpty || f.methodDetail == f.method!.label)
                        ? f.method!.label
                        : '${f.method!.label} · ${f.methodDetail}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (f.round != null) Text('Round ${f.round} · ${f.time ?? ''}', style: TextStyle(color: context.muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fighter(BuildContext context, Fighter x, Color corner) {
    final decided = fight.winner != null;
    final won = fight.winner?.id == x.id;
    return Opacity(
      opacity: decided && !won ? 0.55 : 1,
      child: Column(
        children: [
          FighterAvatar(fighter: x, ring: corner, size: 64),
          const SizedBox(height: 8),
          Text(x.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${x.flag} ${x.record}', style: TextStyle(fontSize: 11, color: context.muted)),
          if (decided)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(won ? 'GANADOR' : 'PERDEDOR', style: display(14, color: won ? context.accent : context.muted)),
            ),
        ],
      ),
    );
  }
}

class _StrikesTab extends StatelessWidget {
  final Fight fight;
  const _StrikesTab({required this.fight});

  @override
  Widget build(BuildContext context) {
    final f = fight;
    if (f.redStrikes.isEmpty && f.stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Las estadísticas de golpes de esta pelea todavía no están disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.muted),
          ),
        ),
      );
    }
    final rounds = f.redStrikes.length;
    final maxV = [...f.redStrikes, ...f.blueStrikes].fold<int>(1, (a, b) => b > a ? b : a);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rounds > 0) ...[
        Text('GOLPES POR ROUND', style: display(22)),
        const SizedBox(height: 4),
        Row(children: [
          _legend(f.red.lastName, _redCorner),
          const SizedBox(width: 16),
          _legend(f.blue.lastName, _blueCorner),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxV * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('R${v.toInt() + 1}', style: TextStyle(color: context.muted, fontSize: 12)),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < rounds; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(toY: f.redStrikes[i].toDouble(), color: _redCorner, width: 14, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: f.blueStrikes[i].toDouble(), color: _blueCorner, width: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        ],
        const SizedBox(height: 20),
        Text('COMPARACIÓN', style: display(22)),
        const SizedBox(height: 4),
        for (final r in f.stats) StatBar(row: r, homeColor: _redCorner, awayColor: _blueCorner),
        const SizedBox(height: 12),
        Text('Datos de ejemplo', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.muted)),
      ],
    );
  }

  Widget _legend(String name, Color c) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(name, style: const TextStyle(fontSize: 13)),
    ]);
  }
}
