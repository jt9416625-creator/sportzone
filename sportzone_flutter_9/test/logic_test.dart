import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_app_movil/core/app_state.dart';
import 'package:proyecto_app_movil/core/validators.dart';
import 'package:proyecto_app_movil/data/avatar_catalog.dart';
import 'package:proyecto_app_movil/models/models.dart';
import 'package:proyecto_app_movil/models/user_models.dart';
import 'package:proyecto_app_movil/services/auth_service.dart';
import 'package:proyecto_app_movil/services/emergency_store.dart';
import 'package:proyecto_app_movil/services/espn_api.dart';
import 'package:proyecto_app_movil/services/local_backend.dart';
import 'package:proyecto_app_movil/services/net.dart';
import 'package:proyecto_app_movil/services/support_store.dart';

void main() {
  // En pruebas, toda petición HTTP responde 400: simula que las APIs están caídas.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Validadores (regex)', () {
    test('detecta correo vs usuario', () {
      expect(Validators.kindOf('juan@correo.com'), IdentifierKind.email);
      expect(Validators.kindOf('Juan_10'), IdentifierKind.username);
      expect(Validators.kindOf('juan@correo'), IdentifierKind.invalid);
      expect(Validators.kindOf('1juan'), IdentifierKind.invalid);
      expect(Validators.kindOf('ab'), IdentifierKind.invalid);
      expect(Validators.kindOf('   '), IdentifierKind.empty);
    });
  });

  group('Autenticación dual', () {
    tearDown(() => AuthService().logout());

    test('entra con usuario y con correo a la misma cuenta', () async {
      final a = await AuthService().login('hincha', '123456');
      await AuthService().logout();
      final b = await AuthService().login('HINCHA@sportzone.app', '123456');
      expect(a.uid, b.uid);
      expect(appState.username, 'hincha');
    });

    test('clave mala y cuenta suspendida fallan', () async {
      expect(() => AuthService().login('hincha', 'malaclave'), throwsA(isA<BackendException>()));
      expect(() => AuthService().login('GolDeLeyenda', '123456'), throwsA(isA<BackendException>()));
    });

    test('registro con correo exige usuario; con usuario no pide correo', () async {
      final u = await AuthService().register(identifier: 'nuevo@correo.com', username: 'nuevo_fan', password: 'secreta');
      expect(u.email, 'nuevo@correo.com');
      expect(u.username, 'nuevo_fan');
      await AuthService().logout();
      final v = await AuthService().register(identifier: 'SoloUsuario', password: 'secreta');
      expect(v.email, isNull);
      expect(() => AuthService().register(identifier: 'soloUSUARIO', password: 'secreta'), throwsA(isA<BackendException>()));
    });
  });

  group('Rachas y admin', () {
    test('perder la racha la guarda y el admin la restaura', () async {
      final u = await AuthService().login('hincha', '123456');
      u.streak = 9;
      u.lastCheckIn = DateTime.now().subtract(const Duration(days: 3));
      appState.checkIn();
      expect(u.streak, 1);
      expect(u.lostStreak, 9);
      final admin = backend.userById('u_admin')!;
      backend.restoreLostStreak(admin, u);
      expect(u.streak, 10);
      expect(u.lostStreak, 0);
      expect(backend.log.first.action, contains('Racha'));
      await AuthService().logout();
    });

    test('un usuario normal no puede usar funciones de admin', () {
      final user = backend.userById('u_hincha')!;
      expect(() => backend.setStreak(user, user, 99), throwsA(isA<BackendException>()));
    });
  });

  group('Avatar e inventario', () {
    test('exclusivas: bloqueadas hasta que el admin las regala', () {
      final admin = backend.userById('u_admin')!;
      final u = backend.userById('u_hincha')!;
      final gold = avatarItemById('top_fb_gold')!;
      expect(backend.whyLocked(u, gold), isNotNull);
      backend.giftItem(admin, u, gold.id);
      backend.equip(u, gold);
      expect(u.equipped[AvatarSlot.top], gold.id);
      backend.setItemEnabled(admin, gold.id, false); // bloqueo global
      expect(u.equipped[AvatarSlot.top], isNull);
      expect(() => backend.equip(u, gold), throwsA(isA<BackendException>()));
      backend.setItemEnabled(admin, gold.id, true);
    });

    test('todas las prendas del catálogo tienen su PNG', () {
      for (final i in avatarCatalog) {
        expect(i.asset, startsWith('assets/avatar/'));
      }
    });
  });

  group('Soporte', () {
    test('ticket: usuario escribe, admin responde y resuelve', () async {
      final u = backend.userById('u_dani')!;
      final admin = backend.userById('u_admin')!;
      final t = supportStore.sendFromUser(u, 'No me carga nada');
      expect(t.unreadByAdmin, isTrue);
      supportStore.replyFromAdmin(t.id, admin, 'Ya lo revisamos');
      expect(t.unreadByUser, isTrue);
      supportStore.setStatus(t.id, TicketStatus.resolved, admin);
      expect(supportStore.currentFor(u.uid)!.status, TicketStatus.resolved);
      // Escribir otra vez abre un ticket nuevo.
      final t2 = supportStore.sendFromUser(u, 'Otra cosa');
      expect(t2.id, isNot(t.id));
      await Future.delayed(const Duration(seconds: 2)); // respuesta automática
      expect(t2.messages.last.fromSupport, isTrue);
    });
  });

  group('Red y contingencia', () {
    test('si la API falla, Net devuelve null (no lanza) y la tabla manual entra', () async {
      final r = await Net.get('https://site.api.espn.com/no-existe');
      expect(r, isNull);
      expect(Net.lastError, isNotEmpty);

      final laLiga = leagueByKey('esp.1')!;
      expect(await EspnApi.standings(laLiga, force: true), isEmpty);
      final admin = backend.userById('u_admin')!;
      emergencyStore.saveTable('esp.1', const [
        StandingRow(rank: 0, teamId: 'a', name: 'Equipo A', points: 10),
        StandingRow(rank: 0, teamId: 'b', name: 'Equipo B', points: 20),
      ], admin);
      final rows = await EspnApi.standings(laLiga, force: true);
      expect(rows.first.name, 'Equipo B'); // ordenada por puntos
      expect(rows.first.rank, 1);
    });

    test('ESPN no borra los partidos publicados a mano', () async {
      final laLiga = leagueByKey('esp.1')!;
      final m = emergencyStore.publishMatch(
        league: laLiga,
        home: allTeamsForTest.first,
        away: allTeamsForTest.last,
        homeScore: 2,
        awayScore: 0,
        status: MatchStatus.finished,
        clock: 'FINAL',
      );
      await EspnApi.loadLeague(laLiga); // falla (sin red) pero no debe tocar lo manual
      expect(emergencyStore.manualMatches.map((x) => x.id), contains(m.id));
    });
  });
}

const allTeamsForTest = [
  Team(id: 'x1', name: 'Local FC', short: 'LOC', sport: Sport.football, color: Color(0xFF000000)),
  Team(id: 'x2', name: 'Visitante FC', short: 'VIS', sport: Sport.football, color: Color(0xFFFFFFFF)),
];
