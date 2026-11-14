import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';

import '../data/avatar_catalog.dart';
import '../models/models.dart';
import '../models/user_models.dart';
import '../services/merch_api.dart';

/// Avatar armado por capas: un Stack de PNG transparentes del mismo tamaño
/// (400 x 560). Orden de atrás hacia adelante:
/// cuerpo → tatuaje → cabello → inferior → superior → cintura → cuello → cara → cabeza → manos.
/// Las prendas de un club (merch) se dibujan con sus colores y escudo, o se
/// muestra la foto de la camiseta oficial.
class AvatarView extends StatelessWidget {
  final Map<AvatarSlot, String> equipped;
  final double? height;

  const AvatarView({super.key, required this.equipped, this.height});

  static const ratio = 400 / 560;

  @override
  Widget build(BuildContext context) {
    final stack = AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final slot in AvatarSlot.values)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
              ),
              child: _layer(slot),
            ),
        ],
      ),
    );
    return height == null ? stack : SizedBox(height: height, child: stack);
  }

  Widget _layer(AvatarSlot slot) {
    final id = equipped[slot];
    if (MerchApi.isMerch(id)) {
      final ref = MerchApi.byId(id);
      if (ref != null) return MerchLayer(key: ValueKey(id), merch: ref);
    }
    final item = avatarItemById(id);
    if (item == null) return SizedBox.expand(key: ValueKey('${slot.name}-none'));
    return Image.asset(
      item.asset,
      key: ValueKey(item.id),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
  }
}

/// Una prenda de club dentro del lienzo de 400 x 560.
class MerchLayer extends StatelessWidget {
  final MerchRef merch;
  const MerchLayer({super.key, required this.merch});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final k = c.maxWidth / 400; // escala del lienzo
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(left: x * k, top: y * k, width: w * k, height: h * k, child: child);

      Widget crest(double size) => _NetImage(url: merch.team.crestUrl, fit: BoxFit.contain, fallback: _Initials(team: merch.team, size: size * k));

      if (merch.kind == MerchKind.official) {
        return Stack(children: [
          at(86, 146, 228, 214, _NetImage(url: merch.imageUrl, fit: BoxFit.contain, fallback: CustomPaint(painter: _GearPainter(merch.team, MerchKind.kit)))),
        ]);
      }
      final basket = merch.team.sport == Sport.basketball;
      return Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GearPainter(merch.team, merch.kind))),
        switch (merch.kind) {
          MerchKind.kit => basket ? at(178, 204, 44, 44, crest(44)) : at(208, 194, 34, 34, crest(34)),
          MerchKind.scarf => at(211, 236, 24, 24, crest(24)),
          MerchKind.cap => at(186, 30, 28, 28, crest(28)),
          MerchKind.official => const SizedBox.shrink(),
        },
      ]);
    });
  }
}

class _NetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget fallback;
  const _NetImage({required this.url, required this.fit, required this.fallback});

  @override
  Widget build(BuildContext context) {
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
      fit: fit,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _Initials extends StatelessWidget {
  final Team team;
  final double size;
  const _Initials({required this.team, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: MerchApi.secondColor(team)),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(team.short, style: TextStyle(fontWeight: FontWeight.w900, color: team.color, fontSize: size * 0.4)),
        ),
      ),
    );
  }
}

/// Dibuja camiseta / bufanda / gorra con los colores del club,
/// usando la misma geometría que los PNG (tool/generate_avatar_assets.py).
class _GearPainter extends CustomPainter {
  final Team team;
  final MerchKind kind;
  _GearPainter(this.team, this.kind);

  static const _outline = Color(0xFF1E1E28);
  static const _shL = Offset(146, 184), _hdL = Offset(104, 320);
  static const _shR = Offset(254, 184), _hdR = Offset(296, 320);

  Path _arm(Offset sh, Offset hd, double t0, double t1, double w) {
    final d = hd - sh;
    final len = d.distance;
    final n = Offset(-d.dy / len * w / 2, d.dx / len * w / 2);
    final a = sh + d * t0, b = sh + d * t1;
    return Path()
      ..moveTo((a + n).dx, (a + n).dy)
      ..lineTo((b + n).dx, (b + n).dy)
      ..lineTo((b - n).dx, (b - n).dy)
      ..lineTo((a - n).dx, (a - n).dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 400);
    final c1 = team.color;
    final c2 = MerchApi.secondColor(team);
    final fill = Paint()..color = c1;
    final fill2 = Paint()..color = c2;
    final stroke = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    void both(Path p, Paint f) {
      canvas.drawPath(p, f);
      canvas.drawPath(p, stroke);
    }

    switch (kind) {
      case MerchKind.kit:
      case MerchKind.official:
        if (team.sport == Sport.basketball) {
          canvas.saveLayer(Offset.zero & const Size(400, 560), Paint());
          final body = RRect.fromLTRBR(140, 164, 260, 340, const Radius.circular(26));
          canvas.drawRRect(body, fill);
          canvas.drawRRect(body, stroke);
          canvas.drawOval(const Rect.fromLTRB(170, 140, 230, 200), Paint()..blendMode = BlendMode.clear);
          final trim = Paint()
            ..color = c2
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7;
          canvas.drawArc(const Rect.fromLTRB(170, 140, 230, 200), 0, math.pi, false, trim);
          canvas.drawLine(const Offset(140, 210), const Offset(160, 168), trim);
          canvas.drawLine(const Offset(260, 210), const Offset(240, 168), trim);
          trim.strokeWidth = 5;
          canvas.drawLine(const Offset(141, 214), const Offset(141, 334), trim);
          canvas.drawLine(const Offset(259, 214), const Offset(259, 334), trim);
          canvas.restore();
        } else {
          for (final (sh, hd) in [(_shL, _hdL), (_shR, _hdR)]) {
            both(_arm(sh, hd, -0.04, 0.42, 42), fill);
            both(_arm(sh, hd, 0.34, 0.42, 42), fill2);
          }
          final body = RRect.fromLTRBR(134, 164, 266, 338, const Radius.circular(30));
          canvas.drawRRect(body, fill);
          // franjas laterales con el segundo color
          canvas.save();
          canvas.clipRRect(body);
          canvas.drawRect(const Rect.fromLTRB(134, 164, 146, 338), fill2);
          canvas.drawRect(const Rect.fromLTRB(254, 164, 266, 338), fill2);
          canvas.restore();
          canvas.drawRRect(body, stroke);
          both(Path()..addPolygon(const [Offset(182, 164), Offset(218, 164), Offset(200, 192)], true), fill2);
        }
      case MerchKind.scarf:
        both(Path()..addRRect(RRect.fromLTRBR(170, 158, 230, 184, const Radius.circular(12))), fill);
        both(Path()..addPolygon(const [Offset(206, 176), Offset(232, 176), Offset(240, 300), Offset(214, 300)], true), fill);
        for (final y in [196.0, 276.0]) {
          final dx = (y - 176) * 0.06;
          canvas.drawPath(
            Path()..addPolygon([Offset(208 + dx, y), Offset(234 + dx, y), Offset(235 + dx, y + 14), Offset(209 + dx, y + 14)], true),
            fill2,
          );
        }
        final fringe = Paint()
          ..color = c1
          ..strokeWidth = 3;
        for (var x = 214.0; x < 242; x += 6) {
          canvas.drawLine(Offset(x, 300), Offset(x, 314), fringe);
        }
      case MerchKind.cap:
        final dome = Path()..addArc(const Rect.fromLTRB(142, 18, 258, 120), math.pi, math.pi);
        dome.close();
        both(dome, fill);
        both(Path()..addRRect(RRect.fromLTRBR(150, 62, 292, 80, const Radius.circular(9))), fill2);
        canvas.drawCircle(const Offset(200, 22), 6, fill2);
    }
  }

  @override
  bool shouldRepaint(covariant _GearPainter old) => old.team.id != team.id || old.kind != kind;
}

/// Avatar en círculo (solo la cabeza), para la barra superior y perfiles.
class AvatarBubble extends StatelessWidget {
  final Map<AvatarSlot, String> equipped;
  final double size;
  final Color background;
  final Color? border;

  const AvatarBubble({
    super.key,
    required this.equipped,
    this.size = 40,
    this.background = const Color(0xFFDCE8F5),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final w = size * 2; // se agranda el avatar al doble y se recorta la cabeza
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: border == null ? null : Border.all(color: border!, width: 2),
      ),
      child: ClipOval(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -size / 2,
              top: size * 0.08,
              width: w,
              height: w / AvatarView.ratio,
              child: AvatarView(equipped: equipped),
            ),
          ],
        ),
      ),
    );
  }
}
