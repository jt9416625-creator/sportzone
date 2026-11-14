import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/album_models.dart';
import '../models/user_models.dart';
import '../services/album_service.dart';
import '../services/auth_service.dart';
import '../services/local_backend.dart';

/// Estado global simple (sin paquetes extra).
///
/// Los datos del fanático (xp, racha, favoritos, votos, avatar) ya NO viven
/// aquí: se leen del usuario que inició sesión. Así, si el admin le corrige la
/// racha a alguien, la pantalla de esa persona cambia al instante.
/// TODO(firebase): el usuario vendrá de Firestore; esta clase no cambia.
class AppState extends ChangeNotifier {
  static const xpPerLevel = 500;

  AppState() {
    // Cualquier cambio en el "servidor" (admin, avatar...) redibuja la app.
    backend.addListener(notifyListeners);
    AuthService().authStateChanges.listen((_) => notifyListeners());
  }

  ThemeMode themeMode = ThemeMode.dark;

  // Usuario invitado: solo existe para que nada se rompa si no hay sesión.
  final AppUser _guest = AppUser(uid: 'guest', username: 'invitado', password: '');

  AppUser get user => AuthService().currentUser ?? _guest;
  bool get loggedIn => AuthService().currentUser != null;
  bool get isAdmin => user.isAdmin;
  String get username => user.username;
  String get handle => user.handle;

  bool get onboardingDone => user.onboardingDone;
  Set<String> get favorites => user.favorites;
  int get xp => user.xp;
  int get streak => user.streak;
  int get lostStreak => user.lostStreak;
  Set<String> get unlocked => user.unlocked;
  Map<String, String> get votes => user.votes;

  bool get checkedInToday {
    final last = user.lastCheckIn;
    return last != null && _sameDay(last, DateTime.now());
  }

  bool get isDark => themeMode == ThemeMode.dark;
  int get level => xp ~/ xpPerLevel + 1;
  int get xpInLevel => xp % xpPerLevel;
  double get levelProgress => xpInLevel / xpPerLevel;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _save() {
    backend.saveProgress(user); // también dispara notifyListeners()
  }

  void toggleTheme() {
    themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void finishOnboarding() {
    user.onboardingDone = true;
    _save();
  }

  bool isFavorite(String id) => favorites.contains(id);

  /// Devuelve las insignias que se acaban de ganar.
  List<BadgeItem> toggleFavorite(String id) {
    HapticFeedback.lightImpact();
    if (favorites.contains(id)) {
      favorites.remove(id);
      _save();
      return [];
    }
    favorites.add(id);
    user.xp += 10;
    album.track(MissionEvent.follow, uniqueKey: id);
    return _evaluateBadges();
  }

  /// Reclamar la racha del día.
  /// - Si el último reclamo fue ayer: la racha sigue (+1).
  /// - Si pasó más de un día: la racha se pierde y se guarda en `lostStreak`
  ///   para que soporte la pueda restaurar si fue culpa de la app.
  List<BadgeItem> checkIn() {
    if (checkedInToday) return [];
    final u = user;
    final today = DateTime.now();
    final last = u.lastCheckIn;
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (last == null || _sameDay(last, yesterday) || u.streak == 0) {
      u.streak += 1;
    } else {
      if (u.streak > 1) u.lostStreak = u.streak;
      u.streak = 1;
    }
    if (u.streak > u.bestStreak) u.bestStreak = u.streak;
    u.lastCheckIn = today;
    u.xp += 50;
    album.track(MissionEvent.checkIn);
    HapticFeedback.mediumImpact();
    return _evaluateBadges();
  }

  /// Solo para pruebas: simula que pasó un día para poder reclamar otra vez.
  void simulateNextDay() {
    final last = user.lastCheckIn;
    if (last != null) user.lastCheckIn = last.subtract(const Duration(days: 1));
    _save();
  }

  List<BadgeItem> vote(String matchId, String option) {
    if (votes.containsKey(matchId)) return [];
    votes[matchId] = option;
    user.xp += 25;
    album.track(MissionEvent.vote, uniqueKey: matchId);
    HapticFeedback.mediumImpact();
    return _evaluateBadges();
  }

  List<BadgeItem> _evaluateBadges() {
    final sportsFollowed = <Sport>{};
    for (final t in allFollowables) {
      if (favorites.contains(t.id)) sportsFollowed.add(t.sport);
    }
    final conditions = <String, bool>{
      'fav3': favorites.length >= 3,
      'streak3': streak >= 3,
      'streak7': streak >= 7,
      'streak14': streak >= 14,
      'predictor': votes.isNotEmpty,
      'multi': sportsFollowed.length >= 3,
      'legend': xp >= 1000,
    };
    final fresh = <BadgeItem>[];
    conditions.forEach((id, ok) {
      if (ok && !unlocked.contains(id)) {
        unlocked.add(id);
        user.xp += 100;
        fresh.add(allBadges.firstWhere((b) => b.id == id));
      }
    });
    _save();
    return fresh;
  }
}

final appState = AppState();
