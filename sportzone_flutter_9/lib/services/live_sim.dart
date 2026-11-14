import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/mock_data.dart';
import '../models/models.dart';

/// Simula el partido en vivo (Madrid vs Barça) para que se vea "real":
/// avanza el minuto, aparecen goles y el marcador rebota.
/// TODO(api): cuando haya API, esto se cambia por un stream real.
class LiveSim extends ChangeNotifier {
  Timer? _timer;
  int _minute = 67;

  MatchItem get _m => matches.firstWhere((m) => m.id == 'm1');

  /// Avisa a las pantallas que la lista de partidos cambió (datos reales).
  void refresh() => notifyListeners();

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  void _tick() {
    final m = _m;
    if (m.status != MatchStatus.live) {
      _timer?.cancel();
      return;
    }
    _minute++;
    m.clock = "$_minute'";

    if (_minute == 70) {
      m.awayScore++;
      m.events.add(const MatchEvent("70'", EventType.goal, EventSide.away, 'Gol de Lewandowski (asist. Raphinha)'));
      HapticFeedback.heavyImpact();
    } else if (_minute == 78) {
      m.homeScore++;
      m.events.add(const MatchEvent("78'", EventType.goal, EventSide.home, 'Gol de Bellingham (asist. Valverde)'));
      HapticFeedback.heavyImpact();
    } else if (_minute >= 90) {
      m.status = MatchStatus.finished;
      m.clock = 'FINAL';
      m.events.add(const MatchEvent("90'", EventType.period, EventSide.none, 'Final del partido'));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final liveSim = LiveSim();
