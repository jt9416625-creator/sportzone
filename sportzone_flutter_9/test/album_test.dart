import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_app_movil/core/app_state.dart';
import 'package:proyecto_app_movil/data/album_data.dart';
import 'package:proyecto_app_movil/models/album_models.dart';
import 'package:proyecto_app_movil/services/album_service.dart';
import 'package:proyecto_app_movil/services/auth_service.dart';
import 'package:proyecto_app_movil/services/local_backend.dart';

/// Azar "trucado": siempre devuelve 0 → siempre sale común y la primera lámina.
class _AlwaysZero implements math.Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AuthService().login('Sofi.Futbol', '123456');
    album.state.reset();
    album.random = math.Random(7);
  });
  tearDown(() => AuthService().logout());

  test('el álbum tiene 62 láminas, 9 páginas y números únicos', () {
    expect(albumStickers.length, 62);
    expect(albumStickers.map((s) => s.id).toSet().length, 62);
    expect(albumStickers.map((s) => s.number).toSet().length, 62);
    for (var p = 1; p <= 9; p++) {
      expect(stickersOfPage(p).length, inInclusiveRange(6, 8));
    }
  });

  test('un sobre trae 5 láminas y gasta un sobre', () {
    final s = album.state;
    final before = s.packs;
    final r = album.openPack();
    expect(r.stickers.length, 5);
    expect(s.packs, before - 1);
    expect(r.isNew.first, isTrue);
  });

  test('garantía: al menos una rara cada 5 sobres', () {
    album.random = _AlwaysZero(); // sin trampa, todo saldría común
    final s = album.state;
    s.packs = 10;
    s.packsSinceRare = 0;
    final results = [for (var i = 0; i < 5; i++) album.openPack()];
    expect(results.take(4).every((r) => r.stickers.every((x) => x.rarity == StickerRarity.common)), isTrue);
    expect(results.last.stickers.any((x) => x.rarity != StickerRarity.common), isTrue);
  });

  test('misión "Lee 5 noticias": la misma noticia no cuenta dos veces', () {
    final m = albumMissions.firstWhere((m) => m.id == 'd_news');
    for (final id in ['a', 'a', 'b', 'c', 'd']) {
      album.track(MissionEvent.readNews, uniqueKey: id);
    }
    expect(album.progressOf(m), 4);
    album.track(MissionEvent.readNews, uniqueKey: 'e');
    expect(album.canClaim(m), isTrue);
    final packs = album.state.packs;
    album.claim(m);
    expect(album.state.packs, packs + 1);
    expect(album.canClaim(m), isFalse);
  });

  test('límite de 3 sobres diarios por misiones', () {
    final s = album.state;
    final start = s.packs;
    album.track(MissionEvent.checkIn);
    album.track(MissionEvent.vote, uniqueKey: 'm1');
    album.track(MissionEvent.openMatch, uniqueKey: 'p1');
    album.track(MissionEvent.openMatch, uniqueKey: 'p2');
    album.track(MissionEvent.avatar);
    for (final m in albumMissions.where((m) => m.period == MissionPeriod.daily)) {
      if (album.canClaim(m)) album.claim(m);
    }
    expect(s.packsFromMissionsToday, AlbumService.maxMissionPacksPerDay);
    expect(s.packs - start, lessThanOrEqualTo(AlbumService.maxMissionPacksPerDay));
  });

  test('5 repetidas se canjean por 1 sobre', () {
    final s = album.state;
    s.owned['s01'] = 4;
    s.owned['s02'] = 3;
    final packs = s.packs;
    expect(album.exchangeDuplicates(), isTrue);
    expect(s.packs, packs + 1);
    expect(s.duplicates, 0);
  });

  test('completar una página da sobre y XP; el álbum completo da la medalla', () {
    final s = album.state;
    final u = appState.user;
    for (final x in stickersOfPage(9)) {
      s.owned[x.id] = 1;
    }
    for (final x in albumStickers) {
      s.owned.putIfAbsent(x.id, () => 1);
    }
    final firstCommon = albumStickers.firstWhere((x) => x.rarity == StickerRarity.common).id;
    s.owned.remove(firstCommon);
    s.packs = 1;
    album.random = _AlwaysZero(); // saca la primera lámina común
    final r = album.openPack();
    expect(r.rewards.any((t) => t.contains('ÁLBUM COMPLETO')), isTrue);
    expect(u.inventory, contains('neck_medal_gold'));
    expect(u.unlocked, contains('album'));
  });

  test('el admin puede regalar sobres y queda en el historial', () {
    final admin = backend.userById('u_admin')!;
    final target = backend.userById('u_hincha')!;
    final before = target.album.packs;
    album.giftPacks(admin, target, 5);
    expect(target.album.packs, before + 5);
    expect(backend.log.first.action, contains('sobres'));
    expect(() => album.giftPacks(target, admin, 1), throwsA(isA<BackendException>()));
  });
}
