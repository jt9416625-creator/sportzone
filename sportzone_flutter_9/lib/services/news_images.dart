import '../data/mock_data.dart';
import '../models/models.dart';
import 'net.dart';
import 'sports_api.dart';

/// Busca una imagen REFERENTE a la noticia cuando la fuente no trae foto.
///
/// 1. Lee el titular y detecta de quién habla (equipo, jugador o peleador).
/// 2. Pide a TheSportsDB una foto de ese equipo (estadio / afición) o de ese
///    deportista (foto de acción).
/// 3. Si no reconoce a nadie, usa una foto de la liga del deporte.
/// Todo queda en caché para no repetir pedidos.
class NewsImages {
  NewsImages._();

  static final Map<String, Future<String?>> _byItem = {};
  static final Map<String, Future<String?>> _byEntity = {};
  static Future<void> _gate = Future.value();

  /// Apodos y nombres que suelen salir en titulares en español.
  static const Map<String, (String, Sport, bool)> _aliases = {
    // texto en el titular: (nombre para buscar, deporte, es jugador)
    'barça': ('FC Barcelona', Sport.football, false),
    'barcelona': ('FC Barcelona', Sport.football, false),
    'real madrid': ('Real Madrid', Sport.football, false),
    'atlético de madrid': ('Atletico Madrid', Sport.football, false),
    'atleti': ('Atletico Madrid', Sport.football, false),
    'manchester city': ('Manchester City', Sport.football, false),
    'manchester united': ('Manchester United', Sport.football, false),
    'liverpool': ('Liverpool', Sport.football, false),
    'arsenal': ('Arsenal', Sport.football, false),
    'chelsea': ('Chelsea', Sport.football, false),
    'bayern': ('Bayern Munich', Sport.football, false),
    'psg': ('Paris SG', Sport.football, false),
    'juventus': ('Juventus', Sport.football, false),
    'inter': ('Inter Milan', Sport.football, false),
    'milan': ('AC Milan', Sport.football, false),
    'nacional': ('Atletico Nacional', Sport.football, false),
    'millonarios': ('Millonarios', Sport.football, false),
    'america de cali': ('America de Cali', Sport.football, false),
    'junior': ('Junior', Sport.football, false),
    'boca': ('Boca Juniors', Sport.football, false),
    'river': ('River Plate', Sport.football, false),
    'selección colombia': ('Colombia', Sport.football, false),
    'mbappé': ('Kylian Mbappe', Sport.football, true),
    'vinícius': ('Vinicius Junior', Sport.football, true),
    'bellingham': ('Jude Bellingham', Sport.football, true),
    'lamine yamal': ('Lamine Yamal', Sport.football, true),
    'yamal': ('Lamine Yamal', Sport.football, true),
    'lewandowski': ('Robert Lewandowski', Sport.football, true),
    'haaland': ('Erling Haaland', Sport.football, true),
    'messi': ('Lionel Messi', Sport.football, true),
    'cristiano': ('Cristiano Ronaldo', Sport.football, true),
    'luis díaz': ('Luis Diaz', Sport.football, true),
    'james rodríguez': ('James Rodriguez', Sport.football, true),
    'salah': ('Mohamed Salah', Sport.football, true),
    'kane': ('Harry Kane', Sport.football, true),
    'lebron': ('LeBron James', Sport.basketball, true),
    'curry': ('Stephen Curry', Sport.basketball, true),
    'dončić': ('Luka Doncic', Sport.basketball, true),
    'doncic': ('Luka Doncic', Sport.basketball, true),
    'jokić': ('Nikola Jokic', Sport.basketball, true),
    'jokic': ('Nikola Jokic', Sport.basketball, true),
    'wembanyama': ('Victor Wembanyama', Sport.basketball, true),
    'antetokounmpo': ('Giannis Antetokounmpo', Sport.basketball, true),
    'gilgeous-alexander': ('Shai Gilgeous-Alexander', Sport.basketball, true),
    'tatum': ('Jayson Tatum', Sport.basketball, true),
  };

  /// Foto de la liga por deporte (ids de TheSportsDB).
  static const Map<Sport, String> _leagueIds = {
    Sport.football: '4480', // Champions League
    Sport.basketball: '4387', // NBA
    Sport.ufc: '4443', // UFC
    Sport.tennis: '4464', // ATP
  };

  static Future<String?> forItem(NewsItem item) {
    if (item.imageUrl != null) return Future.value(item.imageUrl);
    return _byItem.putIfAbsent(item.id, () => _resolve(item));
  }

  static String _norm(String s) => s.toLowerCase();

  static Future<String?> _resolve(NewsItem item) async {
    final text = _norm('${item.title} ${item.summary}');

    // 1) Equipos / deportistas que la app conoce (nombres largos primero).
    final known = allFollowables.where((t) => t.name.length >= 5).toList()..sort((a, b) => b.name.length.compareTo(a.name.length));
    for (final t in known) {
      if (text.contains(_norm(t.name))) {
        final person = t.sport == Sport.tennis || t.sport == Sport.ufc;
        final img = await _entity(t.name, t.sport, person);
        if (img != null) return img;
        break;
      }
    }
    // 2) Apodos frecuentes.
    for (final e in _aliases.entries) {
      if (text.contains(e.key)) {
        final img = await _entity(e.value.$1, e.value.$2, e.value.$3);
        if (img != null) return img;
      }
    }
    // 3) Foto de la liga.
    return _league(item.sport);
  }

  /// Cola: un pedido a la vez, para no pasarnos del límite gratis.
  static Future<T> _queued<T>(Future<T> Function() f) {
    final r = _gate.then((_) => f());
    _gate = r.then((_) => Future<void>.delayed(const Duration(milliseconds: 300)), onError: (_) {});
    return r;
  }

  static Future<String?> _entity(String name, Sport sport, bool person) {
    return _byEntity.putIfAbsent('$sport|$name|$person', () => _queued(() async {
          try {
            final q = Uri.encodeComponent(name);
            if (person) {
              final data = await Net.getJson('${ApiConfig.sportsDbBase}/searchplayers.php?p=$q');
              final list = data is Map && data['player'] is List ? data['player'] as List : const [];
              for (final p in list) {
                if (p is! Map) continue;
                for (final k in ['strFanart1', 'strThumb', 'strCutout', 'strRender']) {
                  final u = '${p[k] ?? ''}';
                  if (u.startsWith('http')) return u;
                }
              }
            } else {
              final data = await Net.getJson('${ApiConfig.sportsDbBase}/searchteams.php?t=$q');
              final list = data is Map && data['teams'] is List ? data['teams'] as List : const [];
              for (final t in list) {
                if (t is! Map) continue;
                for (final k in ['strFanart1', 'strFanart2', 'strStadiumThumb', 'strBanner', 'strBadge']) {
                  final u = '${t[k] ?? ''}';
                  if (u.startsWith('http')) return u;
                }
              }
            }
          } catch (e) {
            Net.lastError = 'Imagen de noticia: $e';
          }
          return null;
        }));
  }

  static Future<String?> _league(Sport sport) {
    return _byEntity.putIfAbsent('league|$sport', () => _queued(() async {
          try {
            final data = await Net.getJson('${ApiConfig.sportsDbBase}/lookupleague.php?id=${_leagueIds[sport]}');
            final list = data is Map && data['leagues'] is List ? data['leagues'] as List : const [];
            for (final l in list) {
              if (l is! Map) continue;
              for (final k in ['strFanart1', 'strFanart2', 'strBanner', 'strPoster']) {
                final u = '${l[k] ?? ''}';
                if (u.startsWith('http')) return u;
              }
            }
          } catch (e) {
            Net.lastError = 'Imagen de liga: $e';
          }
          return null;
        }));
  }
}
