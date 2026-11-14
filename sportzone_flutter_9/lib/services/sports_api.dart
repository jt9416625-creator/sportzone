import 'package:flutter/material.dart';

import '../models/models.dart';
import 'espn_api.dart';
import 'net.dart';

/// Direcciones y claves de las APIs. Si algún día quieres una clave de pago,
/// solo cambias esta clase.
class ApiConfig {
  /// Clave gratuita de TheSportsDB (partidos, equipos, fotos de jugadores).
  static const sportsDbKey = '123';
  static const sportsDbBase = 'https://www.thesportsdb.com/api/v1/json/$sportsDbKey';

  /// Convierte los RSS de Google Noticias a JSON (permite usarlo desde web).
  static const rssProxy = 'https://api.rss2json.com/v1/api.json?rss_url=';
}

// ───────────────────── FOTOS DE DEPORTISTAS ─────────────────────
/// Caras de deportistas. Dos fuentes gratis y sin clave:
///  1. Wikipedia (Chrome NO la bloquea y no tiene límite práctico).
///     Se valida que la página sea de un deportista del deporte correcto.
///  2. TheSportsDB (límite gratis ~30 pedidos/min, por eso va en cola).
/// Si una foto falla, se reintenta a los 2 minutos (no se queda vacía para siempre).
class PhotoService {
  static final Map<String, Future<String?>> _cache = {};
  static final Map<String, DateTime> _failedAt = {};
  static Future<void> _gate = Future.value();

  static const _sportName = {
    Sport.football: 'Soccer',
    Sport.basketball: 'Basketball',
    Sport.tennis: 'Tennis',
    Sport.ufc: 'Fighting',
  };

  /// Palabras que debe tener la descripción de Wikipedia según el deporte.
  static const _wikiWords = {
    Sport.football: ['footballer', 'soccer', 'football'],
    Sport.basketball: ['basketball'],
    Sport.tennis: ['tennis'],
    Sport.ufc: ['mixed martial', 'fighter', 'mma', 'boxer', 'wrestler', 'judoka'],
  };

  static const _wikiSearchHint = {
    Sport.football: 'footballer',
    Sport.basketball: 'basketball player',
    Sport.tennis: 'tennis player',
    Sport.ufc: 'mixed martial artist',
  };

  /// Devuelve la URL de la foto (o null). Se guarda en memoria para no repetir.
  /// [wikiTitle] = título exacto en Wikipedia cuando el nombre es ambiguo.
  static Future<String?> photoFor(String name, Sport sport, {String? teamHint, String? wikiTitle}) {
    final key = '$sport|$name|$teamHint';
    final failed = _failedAt[key];
    if (failed != null && DateTime.now().difference(failed) > const Duration(minutes: 2)) {
      _cache.remove(key);
      _failedAt.remove(key);
    }
    return _cache.putIfAbsent(key, () async {
      String? url;
      try {
        url = await _wiki(wikiTitle ?? name, sport);
        url ??= await _queue(name, sport, teamHint);
        url ??= await _wikiSearch(name, sport);
      } catch (e) {
        Net.lastError = 'Fotos: $e';
      }
      if (url == null) _failedAt[key] = DateTime.now();
      return url;
    });
  }

  static bool _isAthlete(String description, Sport sport) {
    final d = description.toLowerCase();
    return _wikiWords[sport]!.any(d.contains);
  }

  /// Resumen de Wikipedia: foto principal de la página del deportista.
  static Future<String?> _wiki(String title, Sport sport) async {
    final t = Uri.encodeComponent(title.trim().replaceAll(' ', '_'));
    final data = await Net.getJson('https://en.wikipedia.org/api/rest_v1/page/summary/$t?redirect=true');
    if (data is! Map || data['type'] == 'disambiguation') return null;
    if (!_isAthlete('${data['description'] ?? ''} ${data['extract'] ?? ''}', sport)) return null;
    final thumb = data['thumbnail'];
    final url = thumb is Map ? '${thumb['source'] ?? ''}' : '';
    return url.startsWith('http') ? url : null;
  }

  /// Búsqueda en Wikipedia ("Rodri footballer") cuando el nombre exacto no sirve.
  static Future<String?> _wikiSearch(String name, Sport sport) async {
    final q = Uri.encodeComponent('$name ${_wikiSearchHint[sport]}');
    final data = await Net.getJson('https://en.wikipedia.org/w/api.php?action=query&format=json&origin=*'
        '&generator=search&gsrsearch=$q&gsrlimit=3&prop=pageimages|description&piprop=thumbnail&pithumbsize=400');
    final pages = data is Map && data['query'] is Map ? (data['query'] as Map)['pages'] : null;
    if (pages is! Map) return null;
    final list = pages.values.whereType<Map>().toList()..sort((a, b) => ((a['index'] ?? 99) as num).compareTo((b['index'] ?? 99) as num));
    for (final p in list) {
      if (!_isAthlete('${p['description'] ?? ''}', sport)) continue;
      final thumb = p['thumbnail'];
      final url = thumb is Map ? '${thumb['source'] ?? ''}' : '';
      if (url.startsWith('http')) return url;
    }
    return null;
  }

  // TheSportsDB: de a uno, con pausa, para no pasarnos del límite gratis.
  static Future<String?> _queue(String name, Sport sport, String? hint) {
    final result = _gate.then((_) => _fetch(name, sport, hint));
    _gate = result.then((_) => Future<void>.delayed(const Duration(milliseconds: 2100)), onError: (_) {});
    return result;
  }

  static String _ascii(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñçšžćčđłņģķļ';
    const to = 'aaaaaeeeeiiiiooooouuuuncszccdlngkl';
    var out = s;
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]).replaceAll(from[i].toUpperCase(), to[i].toUpperCase());
    }
    return out.replaceAll(' Jr.', ' Junior').replaceAll('Jr.', 'Junior');
  }

  static Future<String?> _fetch(String name, Sport sport, String? hint) async {
    try {
      final q = Uri.encodeComponent(_ascii(name));
      final data = await Net.getJson('${ApiConfig.sportsDbBase}/searchplayers.php?p=$q');
      final list = data is Map && data['player'] is List ? data['player'] as List : const [];
      for (final p in list) {
        if (p is! Map) continue;
        if (p['strSport'] != _sportName[sport]) continue;
        if (hint != null) {
          final team = '${p['strTeam'] ?? ''}'.toLowerCase();
          if (!team.contains(_ascii(hint).toLowerCase())) continue;
        }
        final cut = '${p['strCutout'] ?? ''}';
        final thumb = '${p['strThumb'] ?? ''}';
        final url = cut.startsWith('http') ? cut : thumb;
        if (url.startsWith('http')) return url;
      }
    } catch (e) {
      Net.lastError = 'Fotos: $e';
    }
    return null;
  }
}

// ───────────────────── BUSCADOR (TheSportsDB) ─────────────────────
class SearchApi {
  static Sport? _sport(String? s) => switch (s) {
        'Soccer' => Sport.football,
        'Basketball' => Sport.basketball,
        'Tennis' => Sport.tennis,
        'Fighting' => Sport.ufc,
        _ => null,
      };

  static Color _color(String id) {
    final h = (int.tryParse(id) ?? id.hashCode).abs() % 360;
    return HSLColor.fromAHSL(1, h.toDouble(), 0.55, 0.42).toColor();
  }

  static String _short(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) return words.take(3).map((w) => w[0]).join().toUpperCase();
    return (name.length >= 3 ? name.substring(0, 3) : name).toUpperCase();
  }

  static Future<List<dynamic>> _list(String path, String key) async {
    try {
      final data = await Net.getJson('${ApiConfig.sportsDbBase}/$path');
      final l = data is Map ? data[key] : null;
      return l is List ? l : [];
    } catch (e) {
      Net.lastError = 'Buscador: $e';
      return [];
    }
  }

  /// Busca equipos, jugadores y peleadores por nombre en internet.
  static Future<List<Team>> search(String query) async {
    final q = Uri.encodeComponent(query.trim());
    if (q.isEmpty) return [];
    final results = await Future.wait([
      _list('searchteams.php?t=$q', 'teams'),
      _list('searchplayers.php?p=$q', 'player'),
    ]);
    final out = <Team>[];
    for (final t in results[0]) {
      if (t is! Map) continue;
      final sport = _sport(t['strSport']?.toString());
      final name = t['strTeam']?.toString();
      final id = t['idTeam']?.toString();
      if (sport == null || name == null || id == null) continue;
      final badge = '${t['strBadge'] ?? t['strTeamBadge'] ?? ''}';
      out.add(Team(
        id: 'sdb_t_$id',
        name: name,
        short: _short(name),
        sport: sport,
        crestUrl: badge.startsWith('http') ? badge : null,
        color: _color(id),
        country: '${t['strCountry'] ?? ''}',
      ));
    }
    for (final p in results[1]) {
      if (p is! Map) continue;
      final sport = _sport(p['strSport']?.toString());
      final name = p['strPlayer']?.toString();
      final id = p['idPlayer']?.toString();
      if (sport == null || name == null || id == null) continue;
      final cut = '${p['strCutout'] ?? ''}';
      final thumb = '${p['strThumb'] ?? ''}';
      final img = cut.startsWith('http') ? cut : (thumb.startsWith('http') ? thumb : null);
      out.add(Team(
        id: 'sdb_p_$id',
        name: name,
        short: _short(name),
        sport: sport,
        // En fútbol/básquet el jugador usa la foto; el widget la muestra como cara.
        crestUrl: img,
        color: _color(id),
        country: '${p['strTeam'] ?? p['strNationality'] ?? ''}',
      ));
    }
    return out;
  }
}

// ───────────────────── NOTICIAS REALES ─────────────────────
class NewsApi {
  static const _queries = {
    Sport.football: 'fútbol',
    Sport.basketball: 'NBA baloncesto',
    Sport.ufc: 'UFC',
    Sport.tennis: 'tenis ATP',
  };

  static const _tags = {
    Sport.football: 'FÚTBOL',
    Sport.basketball: 'NBA',
    Sport.ufc: 'UFC',
    Sport.tennis: 'TENIS',
  };

  /// Fuente principal: ESPN (noticias verificadas, con foto, en tiempo real).
  static const _espnFeeds = [
    ('soccer/esp.1', Sport.football, 'LALIGA'),
    ('soccer/eng.1', Sport.football, 'PREMIER'),
    ('soccer/uefa.champions', Sport.football, 'CHAMPIONS'),
    ('soccer/col.1', Sport.football, 'BETPLAY'),
    ('basketball/nba', Sport.basketball, 'NBA'),
    ('mma/ufc', Sport.ufc, 'UFC'),
    ('tennis/atp', Sport.tennis, 'TENIS'),
  ];

  static Future<List<NewsItem>> load() async {
    Future<List<NewsItem>> safe(Future<List<NewsItem>> Function() f) async {
      try {
        return await f();
      } catch (e) {
        Net.lastError = 'Noticias: $e';
        return <NewsItem>[];
      }
    }

    final results = await Future.wait([
      Future.wait(_espnFeeds.map((x) => safe(() => _espn(x.$1, x.$2, x.$3)))),
      Future.wait(_queries.entries.map((q) => safe(() => _one(q.key, q.value)))),
    ]);
    final espn = results[0], google = results[1];

    // Mezcla un deporte tras otro para que el feed no sea todo de lo mismo.
    List<NewsItem> mix(List<List<NewsItem>> lists, int max) {
      final out = <NewsItem>[];
      for (var i = 0; i < max; i++) {
        for (final l in lists) {
          if (i < l.length) out.add(l[i]);
        }
      }
      return out;
    }

    final seen = <String>{};
    bool fresh(NewsItem n) => seen.add(n.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9áéíóúñ]'), ''));
    // Primero ESPN (siempre traen foto); después Google Noticias en español.
    return [
      ...mix(espn, 6).where(fresh),
      ...mix(google, 5).where(fresh),
    ];
  }

  /// Noticias de ESPN de una liga. Intenta en español y si no, en inglés.
  static Future<List<NewsItem>> _espn(String path, Sport sport, String tag) async {
    for (final q in const ['lang=es&region=us&limit=12', 'limit=12']) {
      final data = await Net.getJson('$espnSite/$path/news?$q');
      final arts = data is Map ? data['articles'] : null;
      if (arts is! List || arts.isEmpty) continue;
      final out = <NewsItem>[];
      for (final a in arts) {
        try {
          if (a is! Map) continue;
          final title = '${a['headline'] ?? ''}'.trim();
          if (title.isEmpty) continue;
          String? image;
          final imgs = a['images'];
          if (imgs is List) {
            for (final i in imgs) {
              final u = i is Map ? '${i['url'] ?? ''}' : '';
              if (u.startsWith('http')) {
                image = u;
                break;
              }
            }
          }
          final links = a['links'];
          final web = links is Map && links['web'] is Map ? '${links['web']['href'] ?? ''}' : '';
          final desc = '${a['description'] ?? ''}'.trim();
          final byline = '${a['byline'] ?? ''}'.trim();
          out.add(NewsItem(
            id: 'espn_${a['id'] ?? title.hashCode}',
            sport: sport,
            title: title,
            summary: desc.isEmpty ? 'ESPN' : desc,
            tag: tag,
            ago: _ago('${a['published'] ?? ''}'),
            body: '${desc.isEmpty ? title : desc}\n\n${byline.isEmpty ? 'Fuente: ESPN.' : 'Por $byline · ESPN.'} '
                'Toca el botón de abajo para leer la nota completa.',
            url: web.startsWith('http') ? web : null,
            imageUrl: image,
            source: 'ESPN',
          ));
        } catch (_) {
          // Un artículo raro no tumba los demás.
        }
      }
      if (out.isNotEmpty) return out;
    }
    return [];
  }

  static Future<List<NewsItem>> _one(Sport sport, String query) async {
    final rss = 'https://news.google.com/rss/search?q=${Uri.encodeComponent(query)}&hl=es-419&gl=CO&ceid=CO:es-419';
    final dynamic data;
    try {
      data = await Net.getJson('${ApiConfig.rssProxy}${Uri.encodeComponent(rss)}');
    } catch (e) {
      Net.lastError = 'Noticias: $e';
      return [];
    }
    final items = data is Map ? data['items'] : null;
    if (items is! List) return [];

    final out = <NewsItem>[];
    for (final it in items.take(8)) {
      try {
      if (it is! Map) continue;
      final raw = '${it['title'] ?? ''}'.trim();
      if (raw.isEmpty) continue;
      final cut = raw.lastIndexOf(' - ');
      final title = cut > 0 ? raw.substring(0, cut) : raw;
      final source = cut > 0 ? raw.substring(cut + 3) : '';
      final link = '${it['link'] ?? ''}';

      String? image;
      final thumb = '${it['thumbnail'] ?? ''}';
      if (thumb.startsWith('http')) image = thumb;
      final enc = it['enclosure'];
      if (image == null && enc is Map && '${enc['link'] ?? ''}'.startsWith('http') && '${enc['type'] ?? ''}'.startsWith('image')) {
        image = '${enc['link']}';
      }

      out.add(NewsItem(
        id: 'g${link.hashCode}',
        sport: sport,
        title: title,
        summary: source.isEmpty ? 'Noticia' : 'Fuente: $source',
        tag: _tags[sport]!,
        ago: _ago('${it['pubDate'] ?? ''}'),
        body: 'Esta noticia viene de ${source.isEmpty ? 'una fuente externa' : source}. '
            'Toca el botón de abajo para leer la nota completa.',
        url: link.startsWith('http') ? link : null,
        imageUrl: image,
        source: source.isEmpty ? 'Google Noticias' : source,
      ));
      } catch (_) {
        // Una noticia mal formada no tumba las demás.
      }
    }
    return out;
  }

  static String _ago(String pubDate) {
    final iso = pubDate.replaceFirst(' ', 'T');
    final d = DateTime.tryParse(iso.endsWith('Z') || iso.contains('+') ? iso : '${iso}Z');
    if (d == null) return '';
    final diff = DateTime.now().toUtc().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }
}

// ───────────────────── CARGA GENERAL ─────────────────────
/// Junta todo: pide los datos reales y los mete en las listas de la app.
/// Si internet falla, la app sigue mostrando los datos de ejemplo.
class DataRepo {
  static List<NewsItem> liveNews = [];
  static bool newsOk = false;
  static bool matchesOk = false;
  static bool _loadingMatches = false;

  /// Carga marcadores reales de todas las ligas (ESPN).
  static Future<void> loadMatches() async {
    if (_loadingMatches) return;
    _loadingMatches = true;
    try {
      await EspnApi.loadAll();
      matchesOk = EspnApi.loaded.isNotEmpty;
      EspnApi.loadAllTeams().catchError((Object e) => Net.lastError = 'Equipos: $e'); // en segundo plano
    } catch (e) {
      matchesOk = false;
      Net.lastError = 'Marcadores: $e';
    } finally {
      _loadingMatches = false;
    }
  }

  static Future<void> loadNews() async {
    try {
      final list = await NewsApi.load();
      if (list.isNotEmpty) {
        liveNews = list;
        newsOk = true;
      } else {
        newsOk = false;
      }
    } catch (e) {
      newsOk = false;
      Net.lastError = 'Noticias: $e';
    }
  }
}
