import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_models.dart';

/// Mesa de ayuda: tickets de soporte entre usuarios y administradores.
///
/// Es "en tiempo real" dentro de la app: es un ChangeNotifier, así que en
/// cuanto el admin responde, la pantalla del usuario se redibuja sola.
/// TODO(firebase): colección `tickets/{id}` con subcolección `messages`
/// y `snapshots()` para escuchar en tiempo real entre dispositivos.
class SupportStore extends ChangeNotifier {
  SupportStore._() {
    _seed();
  }
  static final SupportStore instance = SupportStore._();

  static const botName = 'Soporte SportZone';

  final List<SupportTicket> _tickets = [];
  int _next = 1;

  /// ids de tickets donde "soporte está escribiendo..."
  final Set<String> typing = {};

  List<SupportTicket> get all => List.unmodifiable(_tickets..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));

  List<SupportTicket> byStatus(TicketStatus? s) => all.where((t) => s == null || t.status == s).toList();

  int get unreadForAdmin => _tickets.where((t) => t.unreadByAdmin).length;

  SupportTicket? byId(String id) => _tickets.where((t) => t.id == id).firstOrNull;

  /// El ticket abierto del usuario (o el último si todos están resueltos).
  SupportTicket? currentFor(String uid) {
    final mine = _tickets.where((t) => t.userId == uid).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return mine.where((t) => t.status == TicketStatus.open).firstOrNull ?? mine.firstOrNull;
  }

  bool hasUnreadForUser(String uid) => _tickets.any((t) => t.userId == uid && t.unreadByUser);

  String _id() => 't${_next++}';

  // ─────────────────────────── USUARIO ───────────────────────────

  /// El usuario escribe. Si no tiene ticket abierto, se crea uno nuevo.
  SupportTicket sendFromUser(AppUser user, String text) {
    var t = currentFor(user.uid);
    final isNew = t == null || t.status == TicketStatus.resolved;
    if (isNew) {
      t = SupportTicket(id: _id(), userId: user.uid, username: user.username);
      _tickets.add(t);
    }
    t.messages.add(TicketMessage(id: '${t.id}_${t.messages.length}', text: text, fromSupport: false, author: user.username));
    t.updatedAt = DateTime.now();
    t.unreadByAdmin = true;
    notifyListeners();
    if (isNew) _autoReply(t, user);
    return t;
  }

  /// Respuesta automática al abrir un ticket (con "escribiendo...").
  void _autoReply(SupportTicket t, AppUser user) {
    typing.add(t.id);
    notifyListeners();
    Timer(const Duration(milliseconds: 1600), () {
      typing.remove(t.id);
      _addSupport(t, '¡Hola ${user.handle}! 👋 Recibimos tu mensaje (ticket #${t.id.substring(1)}). '
          'Un agente te responderá por aquí mismo en breve.', botName);
    });
  }

  void markReadByUser(String ticketId) {
    final t = byId(ticketId);
    if (t == null || !t.unreadByUser) return;
    t.unreadByUser = false;
    t.seenByUserAt = DateTime.now();
    notifyListeners();
  }

  // ─────────────────────────── ADMIN ───────────────────────────

  void replyFromAdmin(String ticketId, AppUser admin, String text) {
    final t = byId(ticketId);
    if (t == null) return;
    if (t.status == TicketStatus.resolved) t.status = TicketStatus.open;
    _addSupport(t, text, admin.username);
  }

  void _addSupport(SupportTicket t, String text, String author) {
    t.messages.add(TicketMessage(id: '${t.id}_${t.messages.length}', text: text, fromSupport: true, author: author));
    t.updatedAt = DateTime.now();
    t.unreadByUser = true;
    notifyListeners();
  }

  void markReadByAdmin(String ticketId) {
    final t = byId(ticketId);
    if (t == null) return;
    t.seenByAdminAt = DateTime.now();
    if (t.unreadByAdmin) {
      t.unreadByAdmin = false;
      notifyListeners();
    }
  }

  void setStatus(String ticketId, TicketStatus status, AppUser admin) {
    final t = byId(ticketId);
    if (t == null || t.status == status) return;
    t.status = status;
    _addSupport(
      t,
      status == TicketStatus.resolved
          ? '✅ Marcamos este caso como resuelto. Si necesitas algo más, escríbenos y abrimos uno nuevo.'
          : '🔄 Reabrimos tu caso.',
      admin.username,
    );
  }

  // ─────────────────────────── EJEMPLOS ───────────────────────────

  void _seed() {
    final now = DateTime.now();
    final t1 = SupportTicket(id: _id(), userId: 'u_camilo', username: 'Camilo_10', createdAt: now.subtract(const Duration(hours: 3)), unreadByAdmin: true)
      ..messages.addAll([
        TicketMessage(id: 'a', text: 'Hola, ayer la app se cerró sola justo cuando iba a reclamar la racha 😭', fromSupport: false, author: 'Camilo_10', time: now.subtract(const Duration(hours: 3))),
        TicketMessage(id: 'b', text: '¡Hola @Camilo_10! 👋 Recibimos tu mensaje (ticket #1). Un agente te responderá por aquí mismo en breve.', fromSupport: true, author: botName, time: now.subtract(const Duration(hours: 3))),
        TicketMessage(id: 'c', text: 'Tenía 23 días seguidos y ahora me sale 1. ¿Me la pueden devolver?', fromSupport: false, author: 'Camilo_10', time: now.subtract(const Duration(hours: 2, minutes: 55))),
      ]);
    t1.updatedAt = now.subtract(const Duration(hours: 2, minutes: 55));

    final t2 = SupportTicket(id: _id(), userId: 'u_sofi', username: 'Sofi.Futbol', createdAt: now.subtract(const Duration(days: 1)), status: TicketStatus.resolved)
      ..messages.addAll([
        TicketMessage(id: 'a', text: 'No me cargan las noticias, sale "Sin conexión".', fromSupport: false, author: 'Sofi.Futbol', time: now.subtract(const Duration(days: 1))),
        TicketMessage(id: 'b', text: 'Hola Sofi, fue una caída del proveedor de noticias. Ya volvió, desliza hacia abajo para recargar.', fromSupport: true, author: 'admin', time: now.subtract(const Duration(hours: 23))),
        TicketMessage(id: 'c', text: '¡Listo, ya me salen! Gracias 🙌', fromSupport: false, author: 'Sofi.Futbol', time: now.subtract(const Duration(hours: 22))),
      ]);
    t2.updatedAt = now.subtract(const Duration(hours: 22));
    t2.seenByAdminAt = t2.updatedAt;

    _tickets.addAll([t1, t2]);
  }
}

final supportStore = SupportStore.instance;
