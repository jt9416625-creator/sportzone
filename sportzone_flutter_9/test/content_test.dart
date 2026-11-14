import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_app_movil/data/avatar_catalog.dart';
import 'package:proyecto_app_movil/data/mock_data.dart';
import 'package:proyecto_app_movil/models/models.dart';
import 'package:proyecto_app_movil/services/espn_api.dart';
import 'package:proyecto_app_movil/services/merch_api.dart';
import 'package:proyecto_app_movil/services/net.dart';
import 'package:proyecto_app_movil/services/news_images.dart';
import 'package:proyecto_app_movil/services/sports_api.dart';

/// Respuestas falsas con la misma forma que las de ESPN y TheSportsDB.
const _utf8 = {'content-type': 'application/json; charset=utf-8'};

http.Response _fake(http.Request r) {
  final u = r.url.toString();
  if (u.contains('/news')) {
    return http.Response(jsonEncode({
      'articles': [
        {
          'id': 1,
          'headline': 'El Madrid gana el clásico',
          'description': 'Crónica del partido.',
          'published': '2026-11-03T01:00:00Z',
          'byline': 'Redacción',
          'images': [{'url': 'https://a.espncdn.com/photo/real.jpg'}],
          'links': {'web': {'href': 'https://espn.com/nota'}},
        }
      ]
    }), 200, headers: _utf8);
  }
  if (u.contains('/teams?')) {
    return http.Response(jsonEncode({
      'sports': [
        {
          'leagues': [
            {
              'teams': [
                {'team': {'id': '9999', 'displayName': 'Club Nuevo FC', 'abbreviation': 'CNF', 'color': '112233', 'alternateColor': 'ffcc00', 'logos': [{'href': 'https://a.espncdn.com/logo.png'}]}},
                {'team': {'id': '86', 'displayName': 'Real Madrid', 'abbreviation': 'RMA', 'color': 'ffffff', 'logos': [{'href': 'https://a.espncdn.com/rma.png'}]}},
              ]
            }
          ]
        }
      ]
    }), 200, headers: _utf8);
  }
  if (u.contains('searchteams.php')) {
    return http.Response(jsonEncode({
      'teams': [
        {'idTeam': '133738', 'strTeam': 'Real Madrid', 'strSport': 'Soccer', 'strFanart1': 'https://r2.thesportsdb.com/fanart.jpg'}
      ]
    }), 200, headers: _utf8);
  }
  if (u.contains('lookupequipment.php')) {
    return http.Response(jsonEncode({
      'equipment': [
        {'strSeason': '2023-2024', 'strType': '2nd', 'strEquipment': 'https://r2.thesportsdb.com/kit_2023_away.png'},
        {'strSeason': '2024-2025', 'strType': '1st', 'strEquipment': 'https://r2.thesportsdb.com/kit_2024_home.png'},
      ]
    }), 200, headers: _utf8);
  }
  return http.Response('{}', 404);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Net.client = MockClient((r) async => _fake(r)));

  test('todas las prendas del catálogo tienen PNG y miniatura en disco', () {
    final ids = <String>{};
    for (final i in avatarCatalog) {
      expect(ids.add(i.id), isTrue, reason: 'id repetido: ${i.id}');
      expect(File(i.asset).existsSync(), isTrue, reason: i.asset);
      expect(File(i.thumb).existsSync(), isTrue, reason: i.thumb);
    }
  });

  test('no hay ids de equipos repetidos y hay muchos para elegir', () {
    final ids = allFollowables.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(allFollowables.where((t) => t.sport == Sport.basketball).length, 30); // las 30 de la NBA
    expect(allFollowables.where((t) => t.sport == Sport.ufc).length, greaterThan(30));
    expect(allFollowables.where((t) => t.sport == Sport.tennis).length, greaterThan(20));
    expect(teamLeague['x_nac'], 'Liga BetPlay');
  });

  test('noticias de ESPN: titular, foto y enlace', () async {
    final list = await NewsApi.load();
    final n = list.firstWhere((x) => x.source == 'ESPN');
    expect(n.title, 'El Madrid gana el clásico');
    expect(n.imageUrl, 'https://a.espncdn.com/photo/real.jpg');
    expect(n.url, 'https://espn.com/nota');
  });

  test('noticia sin foto: busca una imagen del equipo que menciona', () async {
    const item = NewsItem(id: 'g1', sport: Sport.football, title: 'Real Madrid prepara el partido', summary: '', tag: 'X', ago: '', body: '');
    expect(await NewsImages.forItem(item), 'https://r2.thesportsdb.com/fanart.jpg');
  });

  test('equipos de ESPN: agrega nuevos y le pone escudo oficial a los existentes', () async {
    await EspnApi.loadAllTeams();
    expect(allFollowables.any((t) => t.name == 'Club Nuevo FC'), isTrue);
    final rma = allFollowables.firstWhere((t) => t.id == 'rma');
    expect(rma.crestUrl, 'https://a.espncdn.com/rma.png'); // mismo id, escudo de ESPN
  });

  test('camisetas oficiales: de la más nueva a la más vieja', () async {
    final team = allFollowables.firstWhere((t) => t.id == 'rma');
    final kits = await MerchApi.officialKits(team);
    expect(kits.first.season, '2024-2025');
    expect(kits.first.typeLabel, 'Local');
    final ref = MerchApi.officialItem(team, kits.first);
    expect(MerchApi.byId(ref.id)!.imageUrl, kits.first.imageUrl);
    expect(MerchApi.isMerch(ref.id), isTrue);
  });
}
