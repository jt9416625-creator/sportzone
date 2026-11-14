import 'package:flutter/material.dart';

import '../models/models.dart';

/// Trofeo dibujado a mano (Champions, Europa League, Conference League).
/// Son dibujos estilizados: NO son las imágenes oficiales de la UEFA.
class TrophyIcon extends StatelessWidget {
  final TrophyKind kind;
  final double size;
  final bool locked;
  const TrophyIcon({super.key, required this.kind, this.size = 56, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.9,
      height: size,
      child: CustomPaint(painter: _TrophyPainter(kind, locked)),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  final TrophyKind kind;
  final bool locked;
  const _TrophyPainter(this.kind, this.locked);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    late Color light, dark, detail;
    late double ear;
    switch (kind) {
      case TrophyKind.champions:
        light = const Color(0xFFF2F5FA);
        dark = const Color(0xFF8E9BB0);
        detail = const Color(0xFF1B3A8A);
        ear = 0.28;
      case TrophyKind.europa:
        light = const Color(0xFFFFE08A);
        dark = const Color(0xFFD08A00);
        detail = const Color(0xFF8A4B00);
        ear = 0.20;
      case TrophyKind.conference:
        light = const Color(0xFFD6F5E1);
        dark = const Color(0xFF2E9E60);
        detail = const Color(0xFF0B5D33);
        ear = 0.13;
    }
    if (locked) {
      light = const Color(0xFF8A90A0);
      dark = const Color(0xFF5B6272);
      detail = const Color(0xFF444A58);
    }

    final shader = LinearGradient(
      colors: [light, dark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    final fill = Paint()..shader = shader;
    final edge = Paint()
      ..color = dark.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;

    // Asas (orejas)
    final handle = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    final left = Path()
      ..moveTo(w * .31, h * .12)
      ..cubicTo(w * (.30 - ear), h * .06, w * (.30 - ear), h * .46, w * .36, h * .47);
    final right = Path()
      ..moveTo(w * .69, h * .12)
      ..cubicTo(w * (.70 + ear), h * .06, w * (.70 + ear), h * .46, w * .64, h * .47);
    canvas.drawPath(left, handle);
    canvas.drawPath(right, handle);

    // Copa
    final bowl = Path()
      ..moveTo(w * .30, h * .06)
      ..lineTo(w * .70, h * .06)
      ..quadraticBezierTo(w * .73, h * .50, w * .56, h * .60)
      ..lineTo(w * .44, h * .60)
      ..quadraticBezierTo(w * .27, h * .50, w * .30, h * .06)
      ..close();
    canvas.drawPath(bowl, fill);
    canvas.drawPath(bowl, edge);

    // Detalles de la copa
    final d = Paint()..color = detail.withValues(alpha: 0.75);
    switch (kind) {
      case TrophyKind.champions:
        // "balón" de estrellas
        for (final o in [
          const Offset(.50, .22), const Offset(.42, .32), const Offset(.58, .32),
          const Offset(.46, .43), const Offset(.54, .43),
        ]) {
          canvas.drawCircle(Offset(w * o.dx, h * o.dy), w * .035, d);
        }
      case TrophyKind.europa:
        canvas.drawRect(Rect.fromLTWH(w * .31, h * .24, w * .38, h * .035), d);
        canvas.drawRect(Rect.fromLTWH(w * .33, h * .34, w * .34, h * .03), d);
      case TrophyKind.conference:
        canvas.drawCircle(Offset(w * .5, h * .27), w * .06, d);
        canvas.drawRect(Rect.fromLTWH(w * .35, h * .38, w * .30, h * .03), d);
    }

    // Brillo
    canvas.drawPath(
      Path()
        ..moveTo(w * .35, h * .10)
        ..quadraticBezierTo(w * .33, h * .38, w * .42, h * .50)
        ..lineTo(w * .45, h * .48)
        ..quadraticBezierTo(w * .38, h * .36, w * .40, h * .10)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: locked ? 0.1 : 0.45),
    );

    // Tallo y base
    final stem = RRect.fromLTRBR(w * .45, h * .60, w * .55, h * .83, const Radius.circular(3));
    canvas.drawRRect(stem, fill);
    final base = RRect.fromLTRBR(w * .30, h * .83, w * .70, h * .91, const Radius.circular(4));
    canvas.drawRRect(base, fill);
    canvas.drawRRect(base, edge);
    final plinth = RRect.fromLTRBR(w * .24, h * .91, w * .76, h * .98, const Radius.circular(4));
    canvas.drawRRect(plinth, Paint()..color = detail);
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter old) => old.kind != kind || old.locked != locked;
}
