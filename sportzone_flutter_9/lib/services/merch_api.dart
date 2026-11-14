import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/user_models.dart';
import 'net.dart';
import 'sports_api.dart';

/// Camiseta oficial de un club (imagen real de la temporada).
class OfficialKit {
  final String season; // 2024-2025
  final String type; // 1st, 2nd, 3rd, Goalkeeper
  final String imageUrl;
  const OfficialKit(this.season, this.type, this.imageUrl);

  String get typeLabel => switch (type.toLowerCase()) {
        '1st' || 'home' => 'Local',
        '2nd' || 'away' => 'Visitante',
        '3rd' || 'third' => 'Alterna',
        'goalkeeper' || 'gk' => 'Portero',
        _ => type,
      };
}

/// Tipos de merch de un club que se le pueden poner al avatar.
enum MerchKind { kit, scarf, cap, official }

extension MerchKindX on MerchKind {
  AvatarSlot get slot => switch (this) {
        MerchKind.kit || MerchKind.official => AvatarSlot.top,
        MerchKind.scarf => AvatarSlot.neck,
        MerchKind.cap => AvatarSlot.head,
      };
  String get label => switch (this) {
        MerchKind.kit => 'Camiseta del club',
        MerchKind.scarf => 'Bufanda del club',
        MerchKind.cap => 'Gorra del club',
        MerchKind.official => 'Camiseta oficial',
      };
}

/// Prenda de un club puesta en el avatar.
class MerchRef {
  final String id; // se guarda en AppUser.equipped
  final Team team;
  final MerchKind kind;
  final String? imageUrl; // solo para las oficiales (foto real)
  final String? detail; // "2024-2025 · Local"

  const MerchRef({required this.id, required this.team, required this.kind, this.imageUrl, this.detail});

  AvatarSlot get slot => kind.slot;
  String get name => '${kind.label} · ${team.name}';
}

/// API de merchandising oficial para el avatar.
///
/// - Camisetas OFICIALES: TheSportsDB (`searchteams` → `lookupequipment`)
///   devuelve las fotos reales de las camisetas de cada temporada.
/// - Diseños del club (camiseta, bufanda, gorra): se dibujan con los colores
///   y el escudo oficial del equipo (ESPN), así TODOS los equipos tienen ropa
///   aunque la API no tenga sus camisetas o no haya internet.
///
/// Las imágenes oficiales son propiedad de cada club / TheSportsDB: sirven
/// para uso personal y de estudio. Para publicar la app en una tienda hay que
/// revisar licencias.
class MerchApi {
  MerchApi._();

  static final Map<String, MerchRef> _registry = {};
  static final Map<String, Future<List<OfficialKit>>> _kits = {};

  static bool isMerch(String? id) => id != null && (id.startsWith('club:') || id.startsWith('official:'));

  static MerchRef? byId(String? id) => id == null ? null : _registry[id];

  /// Diseño del club (siempre disponible).
  static MerchRef clubItem(Team team, MerchKind kind) {
    final id = 'club:${kind.name}:${team.id}';
    return _registry.putIfAbsent(id, () => MerchRef(id: id, team: team, kind: kind));
  }

  /// Camiseta oficial (foto real de la API).
  static MerchRef officialItem(Team team, OfficialKit kit) {
    final id = 'official:${team.id}:${kit.imageUrl.hashCode}';
    return _registry.putIfAbsent(
      id,
      () => MerchRef(id: id, team: team, kind: MerchKind.official, imageUrl: kit.imageUrl, detail: '${kit.season} · ${kit.typeLabel}'),
    );
  }

  /// Camisetas oficiales de un equipo (de la más nueva a la más vieja).
  static Future<List<OfficialKit>> officialKits(Team team) {
    final f = _kits.putIfAbsent(team.id, () => _fetchKits(team));
    // Si falló (sin red), se borra del caché para reintentar después.
    f.then((list) {
      if (list.isEmpty) _kits.remove(team.id);
    });
    return f;
  }

  static String _ascii(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    var out = s;
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]).replaceAll(from[i].toUpperCase(), to[i].toUpperCase());
    }
    return out;
  }

  /// Busca el id del equipo en TheSportsDB probando variantes del nombre.
  static Future<String?> _teamId(Team team) async {
    final sport = team.sport == Sport.basketball ? 'Basketball' : 'Soccer';
    final base = _ascii(team.name);
    final variants = <String>{
      base,
      base.replaceAll(RegExp(r'\b(FC|CF|AFC|SC|CD|AC)\b'), '').trim(),
      base.split(' ').first,
    }.where((v) => v.length >= 3);
    for (final v in variants) {
      try {
        final data = await Net.getJson('${ApiConfig.sportsDbBase}/searchteams.php?t=${Uri.encodeComponent(v)}');
        final list = data is Map && data['teams'] is List ? data['teams'] as List : const [];
        Map? best;
        for (final t in list) {
          if (t is! Map || t['strSport'] != sport) continue;
          best ??= t;
          if ('${t['strTeam']}'.toLowerCase() == base.toLowerCase()) {
            best = t;
            break;
          }
        }
        if (best != null) return '${best['idTeam']}';
      } catch (e) {
        Net.lastError = 'Merch: $e';
      }
    }
    return null;
  }

  static Future<List<OfficialKit>> _fetchKits(Team team) async {
    if (team.sport != Sport.football && team.sport != Sport.basketball) return [];
    try {
      final id = await _teamId(team);
      if (id == null) return [];
      final data = await Net.getJson('${ApiConfig.sportsDbBase}/lookupequipment.php?id=$id');
      final list = data is Map && data['equipment'] is List ? data['equipment'] as List : const [];
      final kits = <OfficialKit>[];
      for (final e in list) {
        if (e is! Map) continue;
        final url = '${e['strEquipment'] ?? ''}';
        if (!url.startsWith('http')) continue;
        kits.add(OfficialKit('${e['strSeason'] ?? ''}', '${e['strType'] ?? ''}', url));
      }
      kits.sort((a, b) => b.season.compareTo(a.season));
      return kits.take(18).toList();
    } catch (e) {
      Net.lastError = 'Merch: $e';
      return [];
    }
  }

  /// Segundo color legible para el diseño del club.
  static Color secondColor(Team t) {
    final alt = t.altColor;
    if (alt != null && (alt.computeLuminance() - t.color.computeLuminance()).abs() > 0.12) return alt;
    return t.color.computeLuminance() > 0.5 ? const Color(0xFF1E1E28) : Colors.white;
  }
}
