// Intermediario CORS para correr SportZone en Chrome sin bloqueos.
//
// Chrome no deja que una página web pida datos directo a ESPN o TheSportsDB
// (bloqueo CORS). Este programa corre en TU compu, pide los datos por la app
// y se los devuelve con permiso para el navegador.
//
// Uso (en otra terminal, dentro del proyecto):
//   dart run tool/cors_proxy.dart
// Deja esa terminal abierta y corre la app normal en Chrome:
//   flutter run -d chrome
//
// Solo atiende a localhost y solo a los servidores de deportes de la lista,
// así no queda como un proxy abierto. Más adelante esto mismo se sube como
// Cloud Function de Firebase.
import 'dart:io';

const port = 8787;

/// Servidores permitidos.
const allowedHosts = [
  'espn.com',
  'espncdn.com',
  'thesportsdb.com',
  'rss2json.com',
  'wikipedia.org',
  'wikimedia.org',
  'news.google.com',
];

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final client = HttpClient()..userAgent = 'SportZoneApp/1.0 (proyecto estudiantil)';
  stdout.writeln('✅ Intermediario SportZone en http://localhost:$port  (Ctrl+C para cerrar)');

  await for (final req in server) {
    final res = req.response;
    res.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
      ..set('Access-Control-Allow-Headers', '*');
    if (req.method == 'OPTIONS') {
      await res.close();
      continue;
    }
    final target = Uri.tryParse(req.uri.queryParameters['url'] ?? '');
    if (target == null || !target.hasScheme || !allowedHosts.any((h) => target.host == h || target.host.endsWith('.$h'))) {
      res.statusCode = HttpStatus.forbidden;
      res.write('Servidor no permitido');
      await res.close();
      continue;
    }
    try {
      final up = await client.getUrl(target).timeout(const Duration(seconds: 10));
      final upRes = await up.close().timeout(const Duration(seconds: 15));
      res.statusCode = upRes.statusCode;
      final type = upRes.headers.contentType;
      if (type != null) res.headers.contentType = type;
      await upRes.pipe(res);
      stdout.writeln('${upRes.statusCode}  ${target.host}${target.path}');
    } catch (e) {
      res.statusCode = HttpStatus.badGateway;
      res.write('Error: $e');
      await res.close();
      stdout.writeln('ERROR  ${target.host}: $e');
    }
  }
}
