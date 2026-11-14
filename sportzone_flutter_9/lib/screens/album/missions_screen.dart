import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../data/album_data.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';
import '../../widgets/common.dart';
import '../../widgets/gamification.dart';
import 'album_screen.dart';
import 'pack_opening_screen.dart';

/// Misiones diarias y semanales que dan sobres.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    album.ensurePeriod();
    return Scaffold(
      appBar: AppBar(
        title: Text('MISIONES', style: display(26)),
        actions: [
          IconButton(
            tooltip: 'Álbum',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumScreen())),
            icon: const Icon(Icons.collections_bookmark),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: album,
        builder: (context, _) {
          final s = album.state;
          final left = album.untilReset;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AppCard(
                  borderColor: AppColors.green.withValues(alpha: 0.5),
                  child: Row(children: [
                    const Icon(Icons.mail, color: AppColors.green, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${s.packs} ${s.packs == 1 ? 'SOBRE' : 'SOBRES'} PARA ABRIR', style: display(20)),
                        Text(
                          'Hoy ganaste ${s.packsFromMissionsToday}/${AlbumService.maxMissionPacksPerDay} sobres con misiones diarias',
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                      ]),
                    ),
                    FilledButton(
                      onPressed: s.packs > 0 ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackOpeningScreen())) : null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.bg),
                      child: const Text('ABRIR'),
                    ),
                  ]),
                ),
              ),
              _section(context, 'DIARIAS', 'Se reinician en ${left.inHours} h ${left.inMinutes % 60} min'),
              for (final m in albumMissions.where((m) => m.period == MissionPeriod.daily)) _MissionTile(mission: m),
              _section(context, 'SEMANALES', 'Se reinician el lunes · no cuentan para el límite diario'),
              for (final m in albumMissions.where((m) => m.period == MissionPeriod.weekly)) _MissionTile(mission: m),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Cada sobre trae ${AlbumService.stickersPerPack} láminas. Garantía: al menos una rara cada '
                  '${AlbumService.pityEvery} sobres. ${AlbumService.duplicatesPerPack} repetidas se canjean por un sobre en el álbum.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: context.muted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, String sub) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          Text(title, style: display(22)),
          const SizedBox(width: 10),
          Expanded(child: Text(sub, textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, color: context.muted))),
        ]),
      );
}

class _MissionTile extends StatelessWidget {
  final Mission mission;
  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final p = album.progressOf(m);
    final claimed = album.isClaimed(m);
    final can = album.canClaim(m);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AppCard(
        borderColor: can ? AppColors.green : null,
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: claimed ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (can ? AppColors.green : context.accent).withValues(alpha: 0.15),
                  child: Icon(claimed ? Icons.check : m.icon, color: can ? AppColors.green : context.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(m.description, style: TextStyle(fontSize: 12, color: context.muted)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: XpProgressBar(value: p / m.target, height: 10)),
                const SizedBox(width: 10),
                Text('$p/${m.target}', style: display(16)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _reward(context, Icons.mail, '${m.packs} ${m.packs == 1 ? 'sobre' : 'sobres'}'),
                if (m.xp > 0) _reward(context, Icons.bolt, '+${m.xp} XP'),
                const Spacer(),
                if (claimed)
                  Text('Reclamada ✓', style: TextStyle(color: context.muted, fontWeight: FontWeight.w700))
                else
                  FilledButton(
                    onPressed: can
                        ? () {
                            HapticFeedback.mediumImpact();
                            final msg = album.claim(m);
                            showRewardDialog(
                              context,
                              title: m.title,
                              subtitle: msg,
                              icon: Icons.mail,
                              color: AppColors.green,
                              xp: m.xp,
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.bg, visualDensity: VisualDensity.compact),
                    child: const Text('RECLAMAR'),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reward(BuildContext context, IconData icon, String text) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: context.borderColor2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      );
}
