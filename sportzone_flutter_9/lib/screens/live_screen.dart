import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/espn_api.dart';
import '../services/live_sim.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

/// Todo lo que está pasando ahora mismo en todas las ligas.
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Se actualiza solo cada 45 segundos.
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      await EspnApi.loadAll().timeout(const Duration(seconds: 25));
    } catch (_) {
      // Sin red: se queda con lo último que cargó (y los partidos manuales).
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListenableBuilder(
          listenable: liveSim,
          builder: (context, _) {
            final live = matches.where((m) => m.status == MatchStatus.live).toList();
            final liveFights = fights.where((f) => f.status == MatchStatus.live).toList();
            final next = matches
                .where((m) => m.status == MatchStatus.upcoming && m.kickoff != null)
                .toList()
              ..sort((a, b) => a.kickoff!.compareTo(b.kickoff!));

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_loading && live.isEmpty && liveFights.isEmpty)
                  const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 130, radius: 18))
                else if (live.isEmpty && liveFights.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text('No hay partidos en vivo ahora mismo.', textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
                  ),
                for (final m in live) ...[MatchCard(match: m), const SizedBox(height: 12)],
                for (final f in liveFights) ...[FightCard(fight: f), const SizedBox(height: 12)],
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('PRÓXIMOS', style: display(22)),
                  const SizedBox(height: 10),
                  for (final m in next.take(12)) ...[MatchCard(match: m), const SizedBox(height: 12)],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
