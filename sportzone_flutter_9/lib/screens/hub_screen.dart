import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import '../services/support_store.dart';
import '../widgets/avatar_view.dart';
import '../widgets/gamification.dart';
import '../data/album_data.dart';
import '../services/album_service.dart';
import '../widgets/sticker_card.dart';
import 'admin/admin_panel_screen.dart';
import 'album/album_screen.dart';
import 'album/missions_screen.dart';
import 'avatar_screen.dart';
import 'support_chat_screen.dart';

/// Hub del Fanático: tema, nivel, racha, mi equipo, predicción e insignias.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _ProfileCard()),
            if (appState.isAdmin) const SliverToBoxAdapter(child: _AdminCard()),
            SliverToBoxAdapter(child: _StreakCard()),
            const SliverToBoxAdapter(child: _AlbumCard()),
            SliverToBoxAdapter(child: _MyTeamCard()),
            SliverToBoxAdapter(child: _PredictionCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    Text('SALA DE TROFEOS', style: display(22)),
                    const Spacer(),
                    Text('${appState.unlocked.length}/${allBadges.length}', style: display(20, color: context.accent)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => BadgeTile(badge: allBadges[i], unlocked: appState.unlocked.contains(allBadges[i].id)),
                  childCount: allBadges.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => AuthService().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        );
      },
    );
  }
}

/// Interruptor claro/oscuro con el sol y la luna deslizándose.
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final dark = appState.isDark;
    return GestureDetector(
      onTap: appState.toggleTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: 66,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: dark ? const Color(0xFF303746) : const Color(0xFFFFD27A),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutBack,
          alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dark ? AppColors.bg : Colors.white),
            child: Icon(
              dark ? Icons.nightlight_round : Icons.wb_sunny,
              size: 17,
              color: dark ? AppColors.green : const Color(0xFFFF9F1A),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarScreen())),
                  child: Hero(tag: 'my-avatar', child: AvatarBubble(equipped: u.equipped, size: 60, border: context.accent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(u.handle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        if (u.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                            child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.bg)),
                          ),
                        ],
                      ]),
                      if (u.email != null) Text(u.email!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.muted)),
                      Text('Nivel ${appState.level}', style: display(24, color: context.accent)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Editar avatar',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarScreen())),
                  icon: const Icon(Icons.checkroom),
                ),
              ],
            ),
            const SizedBox(height: 14),
            XpProgressBar(value: appState.levelProgress),
            const SizedBox(height: 6),
            Text('${appState.xpInLevel} / ${AppState.xpPerLevel} XP para el siguiente nivel', style: TextStyle(fontSize: 12, color: context.muted)),
          ],
        ),
      ),
    );
  }
}

/// Álbum SportZone + misiones.
class _AlbumCard extends StatelessWidget {
  const _AlbumCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: album,
      builder: (context, _) {
        final s = album.state;
        final claim = album.claimable;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: AppCard(
            borderColor: AppColors.green.withValues(alpha: 0.5),
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(children: [
                Positioned.fill(child: SzWatermark(color: context.accent, opacity: 0.05, fontSize: 16)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.collections_bookmark, color: context.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text('ÁLBUM SPORTZONE', style: display(22))),
                      Text('${album.ownedCount}/${albumStickers.length}', style: display(20, color: context.accent)),
                    ]),
                    const SizedBox(height: 10),
                    XpProgressBar(value: album.completion, height: 10),
                    const SizedBox(height: 10),
                    Text(
                      '${s.packs} ${s.packs == 1 ? 'sobre' : 'sobres'} sin abrir · $claim ${claim == 1 ? 'misión lista' : 'misiones listas'} para reclamar',
                      style: TextStyle(fontSize: 12.5, color: context.muted),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsScreen())),
                          icon: Badge(isLabelVisible: claim > 0, label: Text('$claim'), child: const Icon(Icons.task_alt, size: 18)),
                          label: const Text('Misiones'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumScreen())),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.bg),
                          icon: const Icon(Icons.auto_stories, size: 18),
                          label: const Text('Ver álbum'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Acceso al panel (solo si el usuario tiene rol admin).
class _AdminCard extends StatelessWidget {
  const _AdminCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ListenableBuilder(
        listenable: supportStore,
        builder: (context, _) {
          final pending = supportStore.unreadForAdmin;
          return AppCard(
            borderColor: AppColors.gold.withValues(alpha: 0.6),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.gold, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PANEL DE ADMINISTRACIÓN', style: display(19)),
                      Text(
                        pending > 0 ? '$pending ${pending == 1 ? 'ticket nuevo' : 'tickets nuevos'} en la mesa de ayuda' : 'Soporte, usuarios, inventario y modo emergencia',
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    ],
                  ),
                ),
                if (pending > 0) Badge(label: Text('$pending')),
                const Icon(Icons.chevron_right),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final done = appState.checkedInToday;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppCard(
        borderColor: AppColors.fire.withValues(alpha: 0.5),
        child: Column(
          children: [
            UserStreakHeader(
              username: appState.username,
              streak: appState.streak,
              bestStreak: appState.user.bestStreak,
              avatar: AvatarBubble(equipped: appState.user.equipped, size: 64, border: AppColors.fire),
              // Solo para pruebas: mantén presionada la llama para simular un día más.
              onFlameLongPress: () {
                appState.simulateNextDay();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modo pruebas: pasó un día. Ya puedes reclamar otra vez.')),
                );
              },
            ),
            if (appState.lostStreak > 1)
              LostStreakNotice(
                lost: appState.lostStreak,
                onSupport: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
              ),
            const SizedBox(height: 14),
            WeekStreakRow(streak: appState.streak),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: done
                    ? null
                    : () async {
                        final fresh = appState.checkIn();
                        await showRewardDialog(
                          context,
                          title: '¡${appState.handle}, racha de ${appState.streak} días!',
                          subtitle: 'Vuelve mañana para mantener la llama encendida.',
                          icon: Icons.local_fire_department,
                          color: AppColors.fire,
                          xp: 50,
                        );
                        if (context.mounted) await showNewBadges(context, fresh);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.fire,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
                child: Text(done ? '¡Ya reclamaste hoy!' : 'RECLAMAR RACHA DE HOY (+50 XP)', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTeamCard extends StatelessWidget {
  const _MyTeamCard();

  @override
  Widget build(BuildContext context) {
    Team? fav;
    for (final t in allFollowables) {
      if (appState.isFavorite(t.id)) {
        fav = t;
        break;
      }
    }

    Widget body;
    if (fav == null) {
      body = Text('Todavía no sigues a nadie. Ve a Buscar y marca tus favoritos con la estrella.', style: TextStyle(color: context.muted));
    } else {
      MatchItem? next;
      for (final m in matches) {
        if (m.status == MatchStatus.upcoming && m.kickoff != null && (m.home.id == fav.id || m.away.id == fav.id)) {
          next = m;
          break;
        }
      }
      if (next == null) {
        body = Row(children: [
          TeamCrest(team: fav, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text('${fav.name} no tiene partidos próximos en los datos de ejemplo.', style: TextStyle(color: context.muted))),
        ]);
      } else {
        body = Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TeamCrest(team: next.home, size: 44),
                Text('VS', style: display(26, color: context.muted)),
                TeamCrest(team: next.away, size: 44),
              ],
            ),
            const SizedBox(height: 12),
            _Countdown(target: next.kickoff!),
          ],
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fav == null ? 'MI EQUIPO' : 'MI EQUIPO · ${fav.name.toUpperCase()}', style: display(20)),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  final DateTime target;
  const _Countdown({required this.target});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var left = widget.target.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');
    Widget box(String v, String label) => Column(children: [
          Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF0E1117) : const Color(0xFFE9ECF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(v, style: display(30, color: context.accent)),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.muted)),
        ]);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        box(two(left.inHours), 'HORAS'),
        const SizedBox(width: 10),
        box(two(left.inMinutes % 60), 'MIN'),
        const SizedBox(width: 10),
        box(two(left.inSeconds % 60), 'SEG'),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard();

  static const _base = {'home': 480, 'draw': 180, 'away': 340};

  @override
  Widget build(BuildContext context) {
    final m = matches.firstWhere((x) => x.id == 'm3');
    final voted = appState.votes[m.id];

    final counts = {..._base};
    if (voted != null) counts[voted] = counts[voted]! + 1;
    final total = counts.values.reduce((a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿QUIÉN GANA HOY?', style: display(20)),
            Text(m.competition, style: TextStyle(fontSize: 12, color: context.muted)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TeamCrest(team: m.home, size: 40),
                Text('VS', style: display(24, color: context.muted)),
                TeamCrest(team: m.away, size: 40),
              ],
            ),
            const SizedBox(height: 14),
            if (voted == null)
              Row(
                children: [
                  for (final o in [('home', m.home.short), ('draw', 'Empate'), ('away', m.away.short)])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () async {
                            final fresh = appState.vote(m.id, o.$1);
                            await showRewardDialog(
                              context,
                              title: '¡Predicción enviada!',
                              subtitle: 'Mira cómo votó el resto de fanáticos.',
                              icon: Icons.insights,
                              color: const Color(0xFF4DA3FF),
                              xp: 25,
                            );
                            if (context.mounted) await showNewBadges(context, fresh);
                          },
                          child: Text(o.$2),
                        ),
                      ),
                    ),
                ],
              )
            else
              Column(
                children: [
                  for (final o in [('home', m.home.short), ('draw', 'Empate'), ('away', m.away.short)])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(width: 56, child: Text(o.$2, style: TextStyle(fontWeight: voted == o.$1 ? FontWeight.w800 : FontWeight.w500))),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: counts[o.$1]! / total),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: v,
                                  minHeight: 12,
                                  backgroundColor: context.isDark ? const Color(0xFF0E1117) : const Color(0xFFE3E6EE),
                                  color: voted == o.$1 ? AppColors.green : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 52, child: Text('${(counts[o.$1]! / total * 100).round()}%', textAlign: TextAlign.right, style: display(18))),
                        ],
                      ),
                    ),
                ],
              ),
            if (voted == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('+25 XP por votar', style: TextStyle(fontSize: 12, color: context.accent)),
              ),
          ],
        ),
      ),
    );
  }
}
