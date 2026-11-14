import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/sports_api.dart';

/// Cara del deportista. Busca la foto en internet (TheSportsDB) y, mientras
/// carga o si no la encuentra, muestra un círculo con iniciales o número.
class PlayerFace extends StatelessWidget {
  final String name;
  final Sport sport;
  final String? teamHint;
  final double size;
  final Color color;
  final Color? ring;
  final String? fallbackText;
  final String? photoUrl; // si ya tenemos la foto, no la buscamos

  const PlayerFace({
    super.key,
    required this.name,
    required this.sport,
    required this.color,
    this.teamHint,
    this.size = 44,
    this.ring,
    this.fallbackText,
    this.photoUrl,
  });

  String get _initials {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _fallback() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(fallbackText ?? _initials, style: display(size * 0.4, color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) return _circle(photoUrl);
    return FutureBuilder<String?>(
      future: PhotoService.photoFor(name, sport, teamHint: teamHint),
      builder: (context, snap) => _circle(snap.data),
    );
  }

  Widget _circle(String? url) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: ring == null ? null : Border.all(color: ring!, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: ClipOval(
            child: url == null
                ? _fallback()
                : CachedNetworkImage(
                    // En la web las fotos pasan por un redimensionador (wsrv.nl)
                    // que sí permite mostrarlas y las recorta al rostro.
                    imageUrl: kIsWeb
                        ? 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=240&h=240&fit=cover&a=top&output=png'
                        : url,
                    imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => _fallback(),
                    errorWidget: (_, __, ___) => _fallback(),
                  ),
          ),
        );
  }
}

/// Color de la nota: verde alto, lima, naranja, rojo.
Color ratingColor(double r) {
  if (r >= 8.0) return const Color(0xFF1FBF6B);
  if (r >= 7.0) return const Color(0xFF8CC63F);
  if (r >= 6.0) return const Color(0xFFF2A33A);
  return const Color(0xFFE5484D);
}

class RatingChip extends StatelessWidget {
  final double value;
  final bool small;
  const RatingChip(this.value, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 8, vertical: small ? 1 : 3),
      decoration: BoxDecoration(
        color: ratingColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.toStringAsFixed(1),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 10.5 : 13),
      ),
    );
  }
}

/// Balón de gol (con número si metió más de uno).
class GoalBall extends StatelessWidget {
  final int count;
  final double size;
  const GoalBall({super.key, this.count = 1, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: count > 1
          ? Text('$count', style: TextStyle(fontSize: size * .6, fontWeight: FontWeight.w900, color: Colors.black))
          : Icon(Icons.sports_soccer, size: size * .85, color: Colors.black),
    );
  }
}

/// Círculo azul con "A" = asistencia.
class AssistDot extends StatelessWidget {
  final int count;
  final double size;
  const AssistDot({super.key, this.count = 1, this.size = 17});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
      child: Text(count > 1 ? '$count' : 'A', style: TextStyle(fontSize: size * .6, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}
