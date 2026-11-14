import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import '../screens/fight_detail_screen.dart';
import '../screens/match_detail_screen.dart';
import '../services/live_sim.dart';
import 'common.dart';

/// Tarjeta de partido (fútbol, básquetbol y tenis).
class MatchCard extends StatelessWidget {
  final MatchItem match;
  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveSim,
      builder: (context, _) {
        final m = match;
        final live = m.status == MatchStatus.live;
        final upcoming = m.status == MatchStatus.upcoming;
        return AppCard(
          borderColor: live ? AppColors.live.withValues(alpha: 0.6) : null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.id))),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(m.sport.icon, size: 14, color: m.sport.color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(m.competition, style: TextStyle(fontSize: 12, color: context.muted))),
                  if (live)
                    LiveBadge(clock: m.clock)
                  else
                    Text(m.clock, style: display(14, color: context.muted)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _side(context, m.home)),
                  if (upcoming)
                    Text('VS', style: display(26, color: context.muted))
                  else
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BouncyScore(value: m.homeScore),
                            Text('  -  ', style: display(30, color: context.muted)),
                            BouncyScore(value: m.awayScore),
                          ],
                        ),
                        if (m.detail != null) Text(m.detail!, style: TextStyle(fontSize: 12, color: context.muted)),
                      ],
                    ),
                  Expanded(child: _side(context, m.away)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _side(BuildContext context, Team t) {
    return Column(
      children: [
        TeamCrest(team: t, size: 46),
        const SizedBox(height: 6),
        Text(t.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Tarjeta de pelea de UFC: rojo vs azul + cómo terminó.
class FightCard extends StatelessWidget {
  final Fight fight;
  const FightCard({super.key, required this.fight});

  @override
  Widget build(BuildContext context) {
    final f = fight;
    final live = f.status == MatchStatus.live;
    return AppCard(
      borderColor: live ? AppColors.live.withValues(alpha: 0.6) : null,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FightDetailScreen(fightId: f.id))),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.sports_mma, size: 14, color: Sport.ufc.color),
              const SizedBox(width: 6),
              Expanded(child: Text('${f.eventName} · ${f.weightClass}', style: TextStyle(fontSize: 12, color: context.muted))),
              if (live) LiveBadge(clock: f.clock) else Text(f.clock, style: display(14, color: context.muted)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _fighter(context, f.red, const Color(0xFFE74C3C))),
              Text('VS', style: display(24, color: context.muted)),
              Expanded(child: _fighter(context, f.blue, const Color(0xFF3498DB))),
            ],
          ),
          if (f.status == MatchStatus.finished && f.method != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: context.isDark ? 0.12 : 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f.method!.icon, size: 18, color: context.accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Ganó ${f.winner!.lastName} · ${f.method!.label} · R${f.round} ${f.time}',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.accent),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
    final dim = decided && !won;
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              FighterAvatar(fighter: x, ring: corner),
              if (won)
                const Positioned(right: -4, bottom: -2, child: CircleAvatar(radius: 11, backgroundColor: AppColors.green, child: Icon(Icons.check, size: 15, color: AppColors.bg))),
            ],
          ),
          const SizedBox(height: 6),
          Text(x.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text('${x.flag} ${x.record}', style: TextStyle(fontSize: 11, color: context.muted)),
        ],
      ),
    );
  }
}
