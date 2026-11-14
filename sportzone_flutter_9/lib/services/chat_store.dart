import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';

/// Chat en vivo de ejemplo. Guarda los mensajes en memoria y simula a otros
/// hinchas hablando. Cuando conectemos la base de datos, esto se cambia por
/// mensajes reales de todos los usuarios.
/// TODO(firebase): reemplazar por Firestore (una colección por sala).
class ChatStore extends ChangeNotifier {
  final Map<String, List<ChatMessage>> _rooms = {};
  final _rnd = math.Random();

  static const _fans = [
    ('Camilo_10', Color(0xFFFF8A1F)),
    ('LaPulga_fan', Color(0xFF4DA3FF)),
    ('Dani77', Color(0xFFB7F34A)),
    ('GolDeLeyenda', Color(0xFFFF5C8A)),
    ('Sofi.Futbol', Color(0xFFFFC83D)),
    ('JuanchoTV', Color(0xFF2ECC71)),
  ];

  List<ChatMessage> room(String id) => _rooms.putIfAbsent(id, () => []);

  void send(String id, String user, String text) {
    room(id).add(ChatMessage(user, text, DateTime.now(), true, const Color(0xFFB7F34A)));
    notifyListeners();
  }

  /// Un hincha de mentira dice algo sobre el partido.
  void fakeFan(String id, String home, String away, {bool live = false}) {
    final fan = _fans[_rnd.nextInt(_fans.length)];
    final lines = live
        ? [
            '¡Qué partidazo, $home está jugando increíble!',
            'Ese árbitro no ve nada 😤',
            'Vamos $away, todavía se puede 💪',
            'Jajaja eso era gol, no puede ser',
            'Cambio necesario ya, el técnico está dormido',
            '¡¡¡GOOOOL!!! 🔥',
            'Qué nivel de $home hoy',
            'Esto se define en los últimos minutos',
          ]
        : [
            '¿Quién creen que gana, $home o $away?',
            'Yo voy con $home, pero está parejo',
            'Ya quiero que empiece 🔥',
            'Mi pronóstico: 2-1',
            '¡Vamos $away!',
          ];
    room(id).add(ChatMessage(fan.$1, lines[_rnd.nextInt(lines.length)], DateTime.now(), false, fan.$2));
    notifyListeners();
  }
}

final chatStore = ChatStore();
