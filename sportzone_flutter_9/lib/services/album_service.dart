import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/app_state.dart';
import '../data/album_data.dart';
import '../models/album_models.dart';
import '../models/user_models.dart';
import 'local_backend.dart';

/// Resultado de abrir un sobre.
class PackResult {
  final List<Sticker> stickers;
  final List<bool> isNew;
  final List<String> rewards; // "¡Completaste la página X! +1 sobre"
  const PackResult(this.stickers, this.isNew, this.rewards);
}

/// Misiones, sobres y álbum. Todo vive en `AppUser.album` (memoria).
/// TODO(firebase): guardar AlbumState en Firestore y hacer el sorteo de
/// sobres en el servidor (Cloud Function) para que nadie pueda hacer trampa.
class AlbumService extends ChangeNotifier {
  AlbumService._();
  static final AlbumService instance = AlbumService._();

  static const stickersPerPack = 5;
  static const maxMissionPacksPerDay = 3; // límite diario de sobres por misiones
  static const pityEvery = 5; // garantía: al menos una rara cada 5 sobres
  static const duplicatesPerPack = 5; // 5 repetidas = 1 sobre
  static const newsSecondsToCount = 4;

  math.Random _rnd = math.Random();

  @visibleForTesting
  set random(math.Random r) => _rnd = r;

  AlbumState get state => appState.user.album;

  // ─────────────────────────── PERIODOS ───────────────────────────

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';
  static String _week(DateTime d) {
    final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    return 'w${_day(monday)}';
  }

  /// Reinicia las misiones diarias y semanales cuando cambia el día/semana.
  void ensurePeriod([AlbumState? s, DateTime? now]) {
    final st = s ?? state;
    final t = now ?? DateTime.now();
    if (st.dayKey != _day(t)) {
      st.dayKey = _day(t);
      st.packsFromMissionsToday = 0;
      st.seenToday.clear();
      for (final m in albumMissions.where((m) => m.period == MissionPeriod.daily)) {
        st.progress.remove(m.id);
        st.claimed.remove(m.id);
      }
    }
    if (st.weekKey != _week(t)) {
      st.weekKey = _week(t);
      for (final m in albumMissions.where((m) => m.period == MissionPeriod.weekly)) {
        st.progress.remove(m.id);
        st.claimed.remove(m.id);
      }
    }
  }

  /// Tiempo que falta para que se reinicien las diarias.
  Duration get untilReset {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + 1).difference(n);
  }

  // ─────────────────────────── MISIONES ───────────────────────────

  /// Las pantallas avisan aquí lo que hizo el usuario.
  /// [uniqueKey] evita contar dos veces lo mismo en el día (misma noticia, mismo partido).
  void track(MissionEvent event, {String? uniqueKey, int amount = 1}) {
    if (!appState.loggedIn) return;
    final s = state;
    ensurePeriod(s);
    if (uniqueKey != null && !s.seenToday.add('${event.name}:$uniqueKey')) return;
    var changed = false;
    for (final m in albumMissions.where((m) => m.event == event)) {
      if (s.claimed.contains(m.id)) continue;
      final p = s.progress[m.id] ?? 0;
      if (p >= m.target) continue;
      s.progress[m.id] = math.min(m.target, p + amount);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  int progressOf(Mission m) => math.min(m.target, state.progress[m.id] ?? 0);
  bool isDone(Mission m) => progressOf(m) >= m.target;
  bool isClaimed(Mission m) => state.claimed.contains(m.id);
  bool canClaim(Mission m) => isDone(m) && !isClaimed(m);
  int get claimable {
    ensurePeriod();
    return albumMissions.where(canClaim).length;
  }

  /// Reclama el premio. Devuelve un texto para mostrar.
  String claim(Mission m) {
    final s = state;
    ensurePeriod(s);
    if (!canClaim(m)) return 'Todavía no completas esta misión.';
    s.claimed.add(m.id);
    var packs = m.packs;
    var capped = false;
    if (m.period == MissionPeriod.daily) {
      final room = maxMissionPacksPerDay - s.packsFromMissionsToday;
      if (packs > room) {
        packs = math.max(0, room);
        capped = true;
      }
      s.packsFromMissionsToday += packs;
    }
    s.packs += packs;
    appState.user.xp += m.xp;
    backend.saveProgress(appState.user);
    notifyListeners();
    final parts = [if (packs > 0) '+$packs ${packs == 1 ? 'sobre' : 'sobres'}', if (m.xp > 0) '+${m.xp} XP'];
    return '${parts.join(' · ')}${capped ? ' (ya llegaste al límite de $maxMissionPacksPerDay sobres diarios por misiones)' : ''}';
  }

  // ─────────────────────────── SOBRES ───────────────────────────

  StickerRarity _roll({bool rareOrBetter = false}) {
    final pool = StickerRarity.values.where((r) => !rareOrBetter || r != StickerRarity.common).toList();
    final total = pool.fold(0, (a, r) => a + r.weight);
    var x = _rnd.nextInt(total);
    for (final r in pool) {
      if (x < r.weight) return r;
      x -= r.weight;
    }
    return pool.last;
  }

  Sticker _pick(StickerRarity r) {
    final list = albumStickers.where((s) => s.rarity == r).toList();
    return list[_rnd.nextInt(list.length)];
  }

  /// Abre un sobre: 5 láminas al azar según su rareza.
  PackResult openPack() {
    final s = state;
    if (s.packs <= 0) return const PackResult([], [], []);
    s.packs--;
    s.packsSinceRare++;
    final picks = [for (var i = 0; i < stickersPerPack; i++) _pick(_roll())];
    // Garantía contra la mala suerte.
    if (s.packsSinceRare >= pityEvery && picks.every((p) => p.rarity == StickerRarity.common)) {
      picks[picks.length - 1] = _pick(_roll(rareOrBetter: true));
    }
    if (picks.any((p) => p.rarity != StickerRarity.common)) s.packsSinceRare = 0;

    final isNew = <bool>[];
    var newCount = 0;
    for (final p in picks) {
      final fresh = !s.has(p.id);
      isNew.add(fresh);
      s.owned[p.id] = s.countOf(p.id) + 1;
      if (fresh) {
        s.fresh.add(p.id);
        newCount++;
      }
    }
    track(MissionEvent.openPack);
    if (newCount > 0) track(MissionEvent.newSticker, amount: newCount);
    final rewards = _checkCompletion(s, appState.user);
    backend.saveProgress(appState.user);
    notifyListeners();
    return PackResult(picks, isNew, rewards);
  }

  /// Premios por completar páginas y el álbum entero.
  List<String> _checkCompletion(AlbumState s, AppUser u) {
    final out = <String>[];
    for (final page in albumPages.where((p) => p.index > 0)) {
      if (s.pagesRewarded.contains(page.index)) continue;
      if (stickersOfPage(page.index).every((x) => s.has(x.id))) {
        s.pagesRewarded.add(page.index);
        s.packs += 1;
        u.xp += 100;
        out.add('¡Completaste "${page.title}"! +1 sobre y +100 XP');
      }
    }
    if (!s.albumRewarded && albumStickers.every((x) => s.has(x.id))) {
      s.albumRewarded = true;
      s.packs += 3;
      u.xp += 500;
      u.inventory.add('neck_medal_gold');
      u.unlocked.add('album');
      out.add('🏆 ¡ÁLBUM COMPLETO! +3 sobres, +500 XP y la Medalla de oro para tu avatar');
    }
    return out;
  }

  int get ownedCount => albumStickers.where((x) => state.has(x.id)).length;
  double get completion => ownedCount / albumStickers.length;
  int ownedInPage(int page) => stickersOfPage(page).where((x) => state.has(x.id)).length;

  void markSeen(String stickerId) {
    if (state.fresh.remove(stickerId)) notifyListeners();
  }

  /// Canjea 5 repetidas por 1 sobre (gasta primero las más repetidas).
  bool exchangeDuplicates() {
    final s = state;
    if (s.duplicates < duplicatesPerPack) return false;
    var left = duplicatesPerPack;
    while (left > 0) {
      final id = s.owned.entries.where((e) => e.value > 1).reduce((a, b) => a.value >= b.value ? a : b).key;
      s.owned[id] = s.owned[id]! - 1;
      left--;
    }
    s.packs++;
    notifyListeners();
    return true;
  }

  // ─────────────────────────── ADMIN ───────────────────────────

  /// Endpoint: POST /admin/users/{uid}/packs
  void giftPacks(AppUser admin, AppUser target, int n) {
    if (!admin.isAdmin) throw const BackendException('Solo un administrador puede regalar sobres.');
    target.album.packs += n;
    backend.log.insert(0, AdminLogEntry(admin.username, target.uid, 'Regalo: $n ${n == 1 ? 'sobre' : 'sobres'}'));
    backend.saveProgress(target);
    notifyListeners();
  }
}

final album = AlbumService.instance;
