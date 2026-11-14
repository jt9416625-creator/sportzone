import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/album_models.dart';
import '../models/models.dart';
import '../services/sports_api.dart';
import 'common.dart';

/// Marca de agua "SPORTZONE" repetida en diagonal (portada y páginas).
class SzWatermark extends StatelessWidget {
  final Color color;
  final double opacity;
  final double fontSize;
  const SzWatermark({super.key, this.color = Colors.white, this.opacity = 0.06, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    // Ocupa solo el espacio que le den. Si el espacio es infinito (por ejemplo
    // dentro de una lista), no dibuja nada: antes eso congelaba el Hub.
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        if (!c.hasBoundedWidth || !c.hasBoundedHeight) return const SizedBox.shrink();
        return ClipRect(child: CustomPaint(painter: _WatermarkPainter(color.withValues(alpha: opacity), fontSize), size: c.biggest));
      }),
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  final Color color;
  final double fontSize;
  _WatermarkPainter(this.color, this.fontSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.isEmpty) return; // seguridad: nunca un ciclo infinito
    final tp = TextPainter(
      text: TextSpan(text: 'SPORTZONE', style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: 3)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.5);
    final span = size.longestSide * 1.3;
    final stepX = tp.width + 40, stepY = tp.height * 2.6;
    var row = 0;
    for (var y = -span; y < span; y += stepY) {
      final off = (row++ % 2) * stepX / 2;
      for (var x = -span - off; x < span; x += stepX) {
        tp.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter old) => old.color != color;
}

/// Lámina del álbum (llena o vacía).
class StickerCard extends StatelessWidget {
  final Sticker sticker;
  final bool owned;
  final int count;
  final bool fresh;
  final VoidCallback? onTap;

  const StickerCard({super.key, required this.sticker, required this.owned, this.count = 1, this.fresh = false, this.onTap});

  static const ratio = 0.72;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: ratio,
      child: GestureDetector(onTap: onTap, child: owned ? _full(context) : _empty(context)),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(sticker.kind == StickerKind.club ? Icons.shield_outlined : Icons.person, size: 34, color: Colors.black.withValues(alpha: 0.18)),
          Text('${sticker.number}', style: display(26, color: Colors.black.withValues(alpha: 0.35))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(sticker.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: Colors.black.withValues(alpha: 0.45))),
          ),
        ],
      ),
    );
  }

  Widget _full(BuildContext context) {
    final r = sticker.rarity;
    Widget card = LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        padding: EdgeInsets.all(w * 0.035),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.08),
          gradient: LinearGradient(colors: r.frame, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: r.color.withValues(alpha: r == StickerRarity.common ? 0.15 : 0.45), blurRadius: r == StickerRarity.common ? 3 : 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(w * 0.06),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [sticker.color, Color.lerp(sticker.color, Colors.black, 0.45)!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Positioned.fill(child: SzWatermark(opacity: 0.08, fontSize: 9)),
              Column(
                children: [
                  Expanded(child: _photo(w)),
                  _nameBand(w),
                ],
              ),
              Positioned(left: w * 0.05, top: w * 0.04, child: _numberChip(w)),
              Positioned(right: w * 0.05, top: w * 0.04, child: Icon(sticker.sport.icon, size: w * 0.13, color: Colors.white.withValues(alpha: 0.85))),
              Positioned(
                right: w * 0.05,
                bottom: w * 0.31,
                child: Text('SZ', style: display(w * 0.1, color: Colors.white.withValues(alpha: 0.55))),
              ),
              if (count > 1)
                Positioned(
                  right: 0,
                  top: w * 0.2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 1),
                    decoration: const BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.horizontal(left: Radius.circular(6))),
                    child: Text('x$count', style: TextStyle(color: Colors.white, fontSize: w * 0.09, fontWeight: FontWeight.w800)),
                  ),
                ),
              if (fresh)
                Positioned(
                  left: 0,
                  right: 0,
                  top: w * 0.55,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(6)),
                      child: Text('NUEVA', style: TextStyle(color: AppColors.bg, fontSize: w * 0.08, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
    if (r == StickerRarity.epic || r == StickerRarity.legendary) {
      card = card.animate(onPlay: (c) => c.repeat()).shimmer(duration: 2400.ms, delay: 1200.ms, color: Colors.white.withValues(alpha: 0.5));
    }
    return card;
  }

  Widget _numberChip(double w) => Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 1),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(5)),
        child: Text('${sticker.number}', style: display(w * 0.12, color: Colors.white)),
      );

  Widget _nameBand(double w) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.04),
        color: Colors.black.withValues(alpha: 0.55),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(sticker.name.toUpperCase(), maxLines: 1, style: display(w * 0.12, color: Colors.white)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${sticker.country} · ${sticker.role}', maxLines: 1, style: TextStyle(fontSize: w * 0.075, color: Colors.white70)),
            ),
          ],
        ),
      );

  Widget _photo(double w) {
    if (sticker.kind == StickerKind.club) {
      final team = allFollowables.where((t) => t.id == sticker.teamId).firstOrNull;
      return Padding(
        padding: EdgeInsets.fromLTRB(w * 0.14, w * 0.2, w * 0.14, w * 0.04),
        child: team == null ? const SizedBox.shrink() : FittedBox(child: TeamCrest(team: team, size: w)),
      );
    }
    final fallback = Center(
      child: Text(
        sticker.name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join(),
        style: display(w * 0.36, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
    // Foto en vivo: Wikipedia y, si no, TheSportsDB (se guarda en caché).
    return FutureBuilder<String?>(
      future: PhotoService.photoFor(sticker.name, sticker.sport, wikiTitle: sticker.wiki),
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) return fallback;
        return Padding(
          padding: EdgeInsets.only(top: w * 0.12),
          child: CachedNetworkImage(
            imageUrl: url,
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}

/// Sobre cerrado de SportZone.
class PackArt extends StatelessWidget {
  final double width;
  const PackArt({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.07),
        gradient: const LinearGradient(colors: [Color(0xFF1E2A3A), Color(0xFF0B0E14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppColors.green, width: 3),
        boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.35), blurRadius: 24)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.06),
        child: Stack(
          children: [
            const Positioned.fill(child: SzWatermark(opacity: 0.07, fontSize: 14)),
            // tira para rasgar
            Positioned(
              top: width * 0.12,
              left: 0,
              right: 0,
              child: Container(height: width * 0.05, color: AppColors.green.withValues(alpha: 0.85)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer, color: AppColors.green, size: width * 0.22),
                  Text('SPORTZONE', style: display(width * 0.15, color: AppColors.green)),
                  Text('ÁLBUM MULTIDEPORTE', style: TextStyle(color: Colors.white70, fontSize: width * 0.055, letterSpacing: 2)),
                  SizedBox(height: width * 0.06),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final s in Sport.values) Padding(padding: EdgeInsets.all(width * 0.015), child: Icon(s.icon, color: s.color, size: width * 0.1)),
                  ]),
                  SizedBox(height: width * 0.06),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: width * 0.02),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                    child: Text('5 LÁMINAS', style: display(width * 0.08, color: AppColors.bg)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
