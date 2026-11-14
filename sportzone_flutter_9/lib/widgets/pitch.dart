import 'package:flutter/material.dart';

import '../core/ratings.dart';
import '../models/models.dart';
import 'player_face.dart';

/// Cancha de fútbol vista desde arriba con los 11 titulares en su formación.
/// Cada jugador muestra su cara, su nota, su gol (balón) y su asistencia (A).
class PitchView extends StatelessWidget {
  final Lineup lineup;
  final Color shirt;
  final MatchItem match;
  final String teamHint;
  const PitchView({
    super.key,
    required this.lineup,
    required this.shirt,
    required this.match,
    required this.teamHint,
  });

  @override
  Widget build(BuildContext context) {
    var rows = <int>[1];
    try {
      rows = [1, ...lineup.formation.split('-').map(int.parse)];
    } catch (_) {}
    final n = lineup.starters.length;
    if (rows.fold<int>(0, (a, b) => a + b) != n || rows.length < 2) {
      // La formación no coincide con los jugadores: los repartimos en 3 líneas.
      final rest = n - 1;
      final a = rest ~/ 3;
      rows = rest < 3 ? [n] : [1, a, a, rest - 2 * a];
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 0.70,
        child: LayoutBuilder(
          builder: (context, cons) {
            final w = cons.maxWidth;
            final h = cons.maxHeight;
            final children = <Widget>[
              const Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
            ];
            var idx = 0;
            for (var r = 0; r < rows.length; r++) {
              final y = rows.length == 1 ? 0.5 : 0.9 - r * (0.78 / (rows.length - 1));
              for (var j = 0; j < rows[r]; j++) {
                if (idx >= lineup.starters.length) break;
                final p = lineup.starters[idx++];
                final x = (j + 1) / (rows[r] + 1);
                children.add(Positioned(
                  left: x * w - 38,
                  top: y * h - 32,
                  width: 76,
                  child: _PlayerDot(player: p, shirt: shirt, match: match, teamHint: teamHint),
                ));
              }
            }
            return Stack(children: children);
          },
        ),
      ),
    );
  }
}

class _PlayerDot extends StatelessWidget {
  final LineupPlayer player;
  final Color shirt;
  final MatchItem match;
  final String teamHint;
  const _PlayerDot({required this.player, required this.shirt, required this.match, required this.teamHint});

  @override
  Widget build(BuildContext context) {
    final line = liveLine(match, player);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              PlayerFace(
                name: player.name,
                sport: Sport.football,
                teamHint: teamHint,
                size: 42,
                color: shirt,
                ring: Colors.white,
                fallbackText: '${player.number}',
              ),
              if (line.rating > 0) Positioned(right: -2, top: -5, child: RatingChip(line.rating, small: true)),
              if (line.goals > 0) Positioned(left: -2, top: -5, child: GoalBall(count: line.goals, size: 19)),
              if (line.assists > 0) Positioned(left: -2, bottom: -3, child: AssistDot(count: line.assists)),
              Positioned(
                right: 1,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                  child: Text('${player.number}', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Franjas de pasto
    const stripes = 10;
    final sh = size.height / stripes;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * sh, size.width, sh),
        Paint()..color = i.isEven ? const Color(0xFF237A3F) : const Color(0xFF1F6E39),
      );
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const m = 10.0;
    final f = Rect.fromLTRB(m, m, size.width - m, size.height - m);
    canvas.drawRect(f, line);
    canvas.drawLine(Offset(f.left, size.height / 2), Offset(f.right, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.13, line);

    final bigW = f.width * 0.58, bigH = f.height * 0.15;
    final smallW = f.width * 0.28, smallH = f.height * 0.06;
    final cx = size.width / 2;

    canvas.drawRect(Rect.fromLTWH(cx - bigW / 2, f.top, bigW, bigH), line);
    canvas.drawRect(Rect.fromLTWH(cx - smallW / 2, f.top, smallW, smallH), line);
    canvas.drawRect(Rect.fromLTWH(cx - bigW / 2, f.bottom - bigH, bigW, bigH), line);
    canvas.drawRect(Rect.fromLTWH(cx - smallW / 2, f.bottom - smallH, smallW, smallH), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
