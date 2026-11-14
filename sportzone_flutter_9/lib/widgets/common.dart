import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import 'player_face.dart';

/// Escudo oficial por URL. Si falla, muestra un círculo con las iniciales.
class TeamCrest extends StatelessWidget {
  final Team team;
  final double size;
  const TeamCrest({super.key, required this.team, this.size = 44});

  @override
  Widget build(BuildContext context) {
    // Tenistas y peleadores: se muestra su cara, no un escudo.
    if (team.sport == Sport.tennis || team.sport == Sport.ufc) {
      return PlayerFace(
        name: team.name,
        sport: team.sport,
        size: size,
        color: team.color,
        fallbackText: team.short,
        photoUrl: team.crestUrl,
      );
    }
    final url = team.crestUrl;
    if (url == null) return _fallback();
    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: url,
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
        fit: BoxFit.contain,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    // Si el color del equipo es muy oscuro (negro), lo aclaramos.
    final hsl = HSLColor.fromColor(team.color);
    final base = hsl.lightness < 0.30 ? hsl.withLightness(0.38).withSaturation(math.max(hsl.saturation, 0.35)).toColor() : team.color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [base, base.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        team.short,
        style: display(size * 0.36, color: Colors.white),
      ),
    );
  }
}

/// Cara del peleador con el anillo del color de su esquina.
class FighterAvatar extends StatelessWidget {
  final Fighter fighter;
  final double size;
  final Color ring;
  const FighterAvatar({
    super.key,
    required this.fighter,
    this.size = 56,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerFace(
      name: fighter.name,
      sport: Sport.ufc,
      size: size,
      color: fighter.color,
      ring: ring,
      fallbackText: fighter.initials,
      photoUrl: fighter.imageUrl,
    );
  }
}

/// Punto rojo que parpadea.
class PulsingDot extends StatelessWidget {
  final double size;
  const PulsingDot({super.key, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.25, end: 1, duration: 700.ms);
  }
}

/// Etiqueta "EN VIVO" + minuto.
class LiveBadge extends StatelessWidget {
  final String clock;
  const LiveBadge({super.key, required this.clock});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PulsingDot(),
        const SizedBox(width: 6),
        Text('EN VIVO', style: display(14, color: AppColors.live)),
        const SizedBox(width: 6),
        Text(clock, style: display(14, color: context.muted)),
      ],
    );
  }
}

/// Número que "rebota" cuando cambia (marcador).
class BouncyScore extends StatelessWidget {
  final int value;
  final double size;
  final Color? color;
  const BouncyScore({super.key, required this.value, this.size = 34, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: Text(
        '$value',
        key: ValueKey(value),
        style: display(size, color: color),
      ),
    );
  }
}

/// Tarjeta base con el estilo del login.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor ?? context.borderColor2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Caja gris que brilla mientras carga.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF232937) : const Color(0xFFE3E6EE),
      highlightColor: dark ? const Color(0xFF30384A) : const Color(0xFFF7F8FB),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Filas de chips para elegir deporte.
class SportChips extends StatelessWidget {
  final Sport? selected;
  final ValueChanged<Sport?> onChanged;
  const SportChips({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'Todo', Icons.apps),
          for (final s in Sport.values) _chip(context, s, s.label, s.icon),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, Sport? s, String label, IconData icon) {
    final on = selected == s;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: on,
        showCheckmark: false,
        avatar: Icon(icon, size: 18, color: on ? AppColors.bg : context.muted),
        label: Text(label),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: on ? AppColors.bg : null,
        ),
        selectedColor: AppColors.green,
        backgroundColor: context.cardColor2,
        side: BorderSide(color: context.borderColor2),
        onSelected: (_) => onChanged(s),
      ),
    );
  }
}

/// Barra de comparación local vs visitante (posesión, tiros, golpes...).
class StatBar extends StatelessWidget {
  final StatRow row;
  final Color homeColor;
  final Color awayColor;
  const StatBar({super.key, required this.row, required this.homeColor, required this.awayColor});

  @override
  Widget build(BuildContext context) {
    final total = (row.home + row.away) == 0 ? 1 : row.home + row.away;
    final h = (row.home / total * 1000).round().clamp(1, 999).toInt();
    String fmt(double v) => row.percent ? '${v.round()}%' : '${v.round()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(fmt(row.home), style: display(20)),
              Expanded(
                child: Text(row.label, textAlign: TextAlign.center, style: TextStyle(color: context.muted, fontSize: 13)),
              ),
              Text(fmt(row.away), style: display(20)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(flex: h, child: Container(height: 8, color: homeColor)),
                const SizedBox(width: 3),
                Expanded(flex: 1000 - h, child: Container(height: 8, color: awayColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícono según el tipo de evento.
Widget eventIcon(EventType t, {double size = 20}) {
  switch (t) {
    case EventType.goal:
      return Icon(Icons.sports_soccer, size: size, color: AppColors.green);
    case EventType.yellow:
      return Container(width: size * .6, height: size * .8, decoration: BoxDecoration(color: const Color(0xFFFFD60A), borderRadius: BorderRadius.circular(2)));
    case EventType.red:
      return Container(width: size * .6, height: size * .8, decoration: BoxDecoration(color: AppColors.live, borderRadius: BorderRadius.circular(2)));
    case EventType.sub:
      return Icon(Icons.swap_vert, size: size, color: const Color(0xFF4DA3FF));
    case EventType.period:
      return Icon(Icons.flag, size: size, color: Colors.grey);
    case EventType.basket:
      return Icon(Icons.sports_basketball, size: size, color: AppColors.fire);
    case EventType.strike:
      return Icon(Icons.sports_mma, size: size, color: AppColors.live);
    case EventType.takedown:
      return Icon(Icons.accessibility_new, size: size, color: const Color(0xFF4DA3FF));
    case EventType.submissionTry:
      return Icon(Icons.back_hand, size: size, color: AppColors.gold);
    case EventType.info:
      return Icon(Icons.circle, size: size * .5, color: Colors.grey);
  }
}

/// Cronología vertical (partidos y peleas).
class Timeline extends StatelessWidget {
  final List<MatchEvent> events;
  final String homeLabel;
  final String awayLabel;
  const Timeline({super.key, required this.events, required this.homeLabel, required this.awayLabel});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Text('Todavía no hay eventos', style: TextStyle(color: context.muted)));
    }
    final list = events.reversed.toList(); // lo más nuevo arriba
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        final label = e.side == EventSide.home ? homeLabel : e.side == EventSide.away ? awayLabel : '';
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 62, child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(e.minute, style: display(16, color: context.muted)))),
              Column(
                children: [
                  Container(width: 2, height: 10, color: context.borderColor2),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.cardColor2, border: Border.all(color: context.borderColor2)),
                    child: eventIcon(e.type, size: 18),
                  ),
                  Expanded(child: Container(width: 2, color: context.borderColor2)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label.isNotEmpty) Text(label, style: display(14, color: context.accent)),
                      Text(e.text, style: const TextStyle(fontSize: 14.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (40 * (i > 8 ? 8 : i)).ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}
