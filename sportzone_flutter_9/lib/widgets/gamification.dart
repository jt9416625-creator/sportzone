import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import 'common.dart';
import 'trophy.dart';

/// Barra de progreso de XP que se llena con animación.
class XpProgressBar extends StatelessWidget {
  final double value; // 0 a 1
  final double height;
  const XpProgressBar({super.key, required this.value, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF0E1117) : const Color(0xFFE3E6EE),
            borderRadius: BorderRadius.circular(height),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v == 0 ? 0.02 : v,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  gradient: const LinearGradient(colors: [AppColors.green, Color(0xFF7DDB2B)]),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(height / 2, 3, height / 2, 0),
                    height: height / 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Llama de la racha, late suavemente.
class StreakFlame extends StatelessWidget {
  final double size;
  final bool active;
  const StreakFlame({super.key, this.size = 40, this.active = true});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.local_fire_department,
      size: size,
      color: active ? AppColors.fire : Colors.grey,
    );
    if (!active) return icon;
    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.15, 1.15),
          duration: 800.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Los 7 días de la semana con la llama en los días cumplidos.
class WeekStreakRow extends StatelessWidget {
  final int streak;
  const WeekStreakRow({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final filled = math.min(streak, 7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              Text(days[i], style: TextStyle(fontSize: 12, color: context.muted)),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + i * 80),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < filled
                      ? AppColors.fire.withValues(alpha: 0.18)
                      : (context.isDark ? const Color(0xFF0E1117) : const Color(0xFFE9ECF3)),
                  border: Border.all(color: i < filled ? AppColors.fire : Colors.transparent, width: 2),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: i < filled ? AppColors.fire : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Una insignia: a color si está ganada, gris con candado si no.
class BadgeTile extends StatelessWidget {
  final BadgeItem badge;
  final bool unlocked;
  const BadgeTile({super.key, required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(unlocked ? '${badge.name}: ${badge.description}' : 'Bloqueada · ${badge.description}')),
        );
      },
      child: AppCard(
        padding: const EdgeInsets.all(10),
        borderColor: unlocked ? badge.color.withValues(alpha: 0.7) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (badge.trophy != null)
                  SizedBox(
                    height: 58,
                    child: TrophyIcon(kind: badge.trophy!, size: 58, locked: !unlocked)
                        .animate(target: unlocked ? 1 : 0)
                        .shimmer(duration: 1600.ms, delay: 300.ms),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked ? badge.color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15),
                    ),
                    child: Icon(badge.icon, size: 28, color: unlocked ? badge.color : Colors.grey),
                  ),
                if (!unlocked) const Positioned(right: 4, bottom: 0, child: Icon(Icons.lock, size: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: unlocked ? null : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal de recompensa con confeti.
Future<void> showRewardDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  int xp = 0,
  TrophyKind? trophy,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => _RewardDialog(title: title, subtitle: subtitle, icon: icon, color: color, xp: xp, trophy: trophy),
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _RewardDialog extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final int xp;
  final TrophyKind? trophy;
  const _RewardDialog({required this.title, required this.subtitle, required this.icon, required this.color, required this.xp, this.trophy});

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              decoration: BoxDecoration(
                color: context.cardColor2,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: widget.color, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.trophy != null)
                    TrophyIcon(kind: widget.trophy!, size: 130)
                        .animate()
                        .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(duration: 1400.ms, delay: 500.ms)
                  else
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.2)),
                      child: Icon(widget.icon, size: 54, color: widget.color),
                    ).animate().shimmer(duration: 1400.ms, delay: 400.ms),
                  const SizedBox(height: 16),
                  Text('¡NUEVA RECOMPENSA!', style: display(16, color: context.muted)),
                  const SizedBox(height: 4),
                  Text(widget.title, textAlign: TextAlign.center, style: display(30)),
                  const SizedBox(height: 6),
                  Text(widget.subtitle, textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
                  if (widget.xp > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                      child: Text('+${widget.xp} XP', style: display(20, color: context.accent)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Text('¡GENIAL!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 28,
              gravity: 0.25,
              colors: const [AppColors.green, AppColors.fire, AppColors.gold, Colors.white, Color(0xFF4DA3FF)],
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el modal de la primera insignia nueva (si hay).
Future<void> showNewBadges(BuildContext context, List<BadgeItem> fresh) async {
  for (final b in fresh) {
    if (!context.mounted) return;
    await showRewardDialog(
      context,
      title: b.name,
      subtitle: b.description,
      icon: b.icon,
      color: b.color,
      xp: 100,
      trophy: b.trophy,
    );
  }
}

/// Encabezado de la racha con la identidad del fanático: avatar, @usuario,
/// días de racha y mejor racha. Se alimenta del usuario que inició sesión
/// (AppState → AuthService), así que cambia solo al entrar con otra cuenta
/// o cuando el admin corrige la racha.
class UserStreakHeader extends StatelessWidget {
  final String username;
  final int streak;
  final int bestStreak;
  final Widget avatar;
  final VoidCallback? onFlameLongPress;

  const UserStreakHeader({
    super.key,
    required this.username,
    required this.streak,
    required this.bestStreak,
    required this.avatar,
    this.onFlameLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: -8,
              bottom: -6,
              child: GestureDetector(onLongPress: onFlameLongPress, child: const StreakFlame(size: 30)),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: streak),
                duration: const Duration(milliseconds: 700),
                builder: (context, v, _) => Text('$v ${v == 1 ? 'día' : 'días'}', style: display(38, color: AppColors.fire)),
              ),
              Text(
                'de racha · mejor: $bestStreak ${bestStreak == 1 ? 'día' : 'días'}',
                style: TextStyle(fontSize: 12.5, color: context.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aviso cuando el usuario perdió una racha larga (para pedir que la restauren).
class LostStreakNotice extends StatelessWidget {
  final int lost;
  final VoidCallback onSupport;
  const LostStreakNotice({super.key, required this.lost, required this.onSupport});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.fire.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fire.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.heart_broken_outlined, size: 18, color: AppColors.fire),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Perdiste una racha de $lost días. ¿Fue un fallo de la app?',
                style: TextStyle(fontSize: 12.5, color: context.isDark ? Colors.white70 : Colors.black87)),
          ),
          TextButton(onPressed: onSupport, child: const Text('Soporte')),
        ],
      ),
    );
  }
}
