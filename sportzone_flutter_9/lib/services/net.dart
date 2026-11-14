import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Capa de red única de la app. TODAS las peticiones pasan por aquí.
///
/// - Tiempo máximo por petición: [defaultTimeout] (10 s). Si la API no
///   responde, se corta y la pantalla sigue funcionando con datos de respaldo.
/// - Todo va dentro de try-catch: nunca lanza excepciones hacia la interfaz,
///   devuelve null y deja el motivo en [lastError].
/// - En la versión web (Chrome), el navegador bloquea las llamadas a ESPN y
///   TheSportsDB (CORS). Entonces se prueban VARIOS intermediarios públicos
///   a la vez, se usa el primero que responda y se recuerda para la próxima.
///   En el celular (Android/iOS) nada de esto hace falta.
class Net {
  Net._();

  static const defaultTimeout = Duration(seconds: 10);

  /// Último error, para mostrarlo en pantalla y saber qué pasó.
  static String lastError = '';

  /// true si la última petición salió bien. Sirve para avisos de "sin conexión".
  static final ValueNotifier<bool> online = ValueNotifier(true);

  /// Intermediarios CORS públicos (gratis, sin clave). Si uno se cae,
  /// la app usa otro. Puedes agregar o quitar de esta lista.
  static final List<String Function(String)> _proxies = [
    (u) => 'https://corsproxy.io/?url=${Uri.encodeComponent(u)}',
    (u) => 'https://api.codetabs.com/v1/proxy/?quest=${Uri.encodeComponent(u)}',
    (u) => 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(u)}',
    (u) => 'https://thingproxy.freeboard.io/fetch/$u',
  ];

  /// Intermediario que funcionó la última vez (se prueba primero).
  static int? _goodProxy;

  /// En web: servidores que Chrome ya bloqueó (CORS). Se recuerda POR
  /// servidor: que ESPN esté bloqueado no significa que Wikipedia lo esté.
  static final Set<String> _blockedHosts = {};

  /// Intermediario propio (tool/cors_proxy.dart) corriendo en tu compu.
  /// Es el más confiable en Chrome: `dart run tool/cors_proxy.dart`
  static const localProxy = 'http://localhost:8787/?url=';
  static bool? _localProxyUp; // null = no se ha probado

  /// Cliente HTTP. Las pruebas lo cambian por uno falso (MockClient).
  @visibleForTesting
  static http.Client client = http.Client();

  static Future<http.Response?> get(String url, {Duration timeout = defaultTimeout}) async {
    final host = Uri.tryParse(url)?.host ?? '';
    if (!kIsWeb || !_blockedHosts.contains(host)) {
      final direct = await _once(url, timeout);
      if (direct != null) return direct;
      if (kIsWeb && lastError.startsWith('Sin conexión')) _blockedHosts.add(host); // CORS
    }
    if (kIsWeb) {
      // 1) Intermediario propio en tu compu (si lo tienes corriendo).
      if (_localProxyUp != false) {
        final local = await _once('$localProxy${Uri.encodeComponent(url)}', timeout);
        if (local != null) {
          _localProxyUp = true;
          return local;
        }
        if (lastError.startsWith('Sin conexión')) _localProxyUp = false; // no está corriendo
      }
      // 2) Intermediarios públicos.
      final viaProxy = await _viaProxies(url, timeout);
      if (viaProxy != null) return viaProxy;
      lastError = 'Chrome bloqueó la conexión y ningún intermediario respondió ($lastError). '
          'Solución: en otra terminal corre "dart run tool/cors_proxy.dart", o usa el celular.';
    }
    online.value = false;
    return null;
  }

  /// Primero el intermediario que funcionó antes; si falla, todos a la vez
  /// y gana el primero que responda bien.
  static Future<http.Response?> _viaProxies(String url, Duration timeout) async {
    final good = _goodProxy;
    if (good != null) {
      final r = await _once(_proxies[good](url), timeout);
      if (r != null) return r;
      _goodProxy = null;
    }
    final done = Completer<http.Response?>();
    var pending = _proxies.length;
    for (var i = 0; i < _proxies.length; i++) {
      if (i == good) {
        pending--;
        continue;
      }
      _once(_proxies[i](url), timeout).then((r) {
        if (done.isCompleted) return;
        if (r != null) {
          _goodProxy = i;
          done.complete(r);
        } else if (--pending == 0) {
          done.complete(null);
        }
      });
    }
    if (pending == 0 && !done.isCompleted) done.complete(null);
    return done.future;
  }

  /// Pide y convierte a JSON. Devuelve null si algo falla (red o formato).
  static Future<dynamic> getJson(String url, {Duration timeout = defaultTimeout}) async {
    final res = await get(url, timeout: timeout);
    if (res == null) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException catch (e) {
      lastError = 'Respuesta inválida del servidor (${e.message})';
      return null;
    } catch (e) {
      lastError = 'No se pudo leer la respuesta: $e';
      return null;
    }
  }

  static Future<http.Response?> _once(String url, Duration timeout) async {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException {
      lastError = 'Dirección inválida';
      return null;
    }
    try {
      // Wikipedia pide identificarse (en web el navegador no deja cambiarlo).
      final headers = kIsWeb ? null : const {'User-Agent': 'SportZoneApp/1.0 (proyecto estudiantil)'};
      final r = await client.get(uri, headers: headers).timeout(timeout);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        online.value = true;
        return r;
      }
      lastError = 'El servidor respondió HTTP ${r.statusCode}';
    } on TimeoutException {
      lastError = 'El servidor tardó más de ${timeout.inSeconds} s en responder';
    } on http.ClientException catch (e) {
      // Sin internet, DNS, conexión rechazada o bloqueo CORS en web.
      lastError = 'Sin conexión con el servidor (${e.message.split('\n').first})';
    } catch (e) {
      lastError = 'Error de red: ${e.toString().split('\n').first}';
    }
    if (kDebugMode) debugPrint('[Net] $url -> $lastError');
    return null;
  }
}
