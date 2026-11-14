import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../models/user_models.dart';
import '../../services/local_backend.dart';
import '../../services/support_store.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/messenger.dart';
import 'admin_panel_screen.dart';
import 'admin_users.dart';

/// Mesa de ayuda: bandeja de tickets en tiempo real.
class AdminSupportTab extends StatefulWidget {
  const AdminSupportTab({super.key});

  @override
  State<AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends State<AdminSupportTab> {
  TicketStatus? _filter = TicketStatus.open;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: supportStore,
      builder: (context, _) {
        final list = supportStore.byStatus(_filter);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: SegmentedButton<TicketStatus?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: TicketStatus.open, label: Text('Abiertos'), icon: Icon(Icons.mark_chat_unread_outlined)),
                  ButtonSegment(value: TicketStatus.resolved, label: Text('Resueltos'), icon: Icon(Icons.task_alt)),
                  ButtonSegment(value: null, label: Text('Todos')),
                ],
                selected: {_filter},
                onSelectionChanged: (v) => setState(() => _filter = v.first),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No hay tickets aquí. 🎉', style: TextStyle(color: context.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(height: 1, indent: 76, color: context.borderColor2),
                      itemBuilder: (context, i) => _TicketTile(ticket: list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'ahora';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  return '${d.inDays} d';
}

class _TicketTile extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final u = backend.userById(t.userId);
    final last = t.last;
    final unread = t.unreadByAdmin;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: u == null ? const CircleAvatar(child: Icon(Icons.person)) : AvatarBubble(equipped: u.equipped, size: 48),
      title: Row(children: [
        Expanded(child: Text('@${t.username}', style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600))),
        Text(timeAgo(t.updatedAt), style: TextStyle(fontSize: 12, color: unread ? const Color(0xFF4DA3FF) : context.muted)),
      ]),
      subtitle: Row(children: [
        Expanded(
          child: Text(
            last == null ? '' : '${last.fromSupport ? 'Tú: ' : ''}${last.text}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: unread ? null : context.muted, fontWeight: unread ? FontWeight.w600 : null),
          ),
        ),
        const SizedBox(width: 8),
        if (unread)
          const CircleAvatar(radius: 5, backgroundColor: Color(0xFF4DA3FF))
        else if (t.status == TicketStatus.resolved)
          const Icon(Icons.task_alt, size: 16, color: AppColors.green),
      ]),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTicketScreen(ticketId: t.id))),
    );
  }
}

/// Conversación de un ticket vista por el admin (sus mensajes a la derecha).
class AdminTicketScreen extends StatelessWidget {
  final String ticketId;
  const AdminTicketScreen({super.key, required this.ticketId});

  static const _quick = [
    'Hola, ya estamos revisando tu caso 👀',
    'Listo, restauramos tu racha ✅',
    '¿Me envías una captura del error?',
    'Ya está solucionado. ¡Gracias por avisar!',
  ];

  @override
  Widget build(BuildContext context) {
    final admin = appState.user;
    return Theme(
      data: messengerTheme(context),
      child: ListenableBuilder(
        listenable: Listenable.merge([supportStore, backend]),
        builder: (context, _) {
          final t = supportStore.byId(ticketId);
          if (t == null) return const Scaffold(body: Center(child: Text('Ticket no encontrado')));
          if (t.unreadByAdmin || t.seenByAdminAt == null || t.seenByAdminAt!.isBefore(t.updatedAt)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => supportStore.markReadByAdmin(t.id));
          }
          final u = backend.userById(t.userId);
          final resolved = t.status == TicketStatus.resolved;
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: MessengerTitle(
                title: '@${t.username}',
                subtitle: 'Caso #${t.id.substring(1)} · ${resolved ? 'Resuelto' : 'Abierto'}',
                avatar: u == null ? const CircleAvatar(radius: 18) : AvatarBubble(equipped: u.equipped, size: 36, background: Colors.white),
                online: false,
              ),
              actions: [
                if (u != null)
                  IconButton(
                    tooltip: 'Ver perfil',
                    icon: const Icon(Icons.manage_accounts),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(uid: u.uid))),
                  ),
                IconButton(
                  tooltip: resolved ? 'Reabrir' : 'Marcar como resuelto',
                  icon: Icon(resolved ? Icons.replay : Icons.task_alt),
                  onPressed: () {
                    supportStore.setStatus(t.id, resolved ? TicketStatus.open : TicketStatus.resolved, admin);
                    adminToast(context, resolved ? 'Ticket reabierto' : 'Ticket marcado como resuelto ✅');
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                if (u != null) _UserStrip(user: u),
                Expanded(
                  child: MessengerList(
                    messages: t.messages,
                    viewerIsSupport: true,
                    seenAt: t.seenByUserAt,
                    otherAvatar: u == null ? const CircleAvatar() : AvatarBubble(equipped: u.equipped, size: 30),
                  ),
                ),
                MessengerComposer(
                  hint: 'Responder como soporte...',
                  quickReplies: _quick,
                  onSend: (text) => supportStore.replyFromAdmin(t.id, admin, text),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Datos rápidos del usuario dentro del chat (para resolver sin salir).
class _UserStrip extends StatelessWidget {
  final AppUser user;
  const _UserStrip({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F7F9),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, size: 18, color: AppColors.fire),
          const SizedBox(width: 4),
          Text('Racha: ${user.streak}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          if (user.lostStreak > 0) Text('  ·  Perdió: ${user.lostStreak}', style: const TextStyle(fontSize: 12.5, color: AppColors.fire)),
          if (user.suspended) const Text('  ·  SUSPENDIDO', style: TextStyle(fontSize: 12.5, color: AppColors.live, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (user.lostStreak > 0)
            TextButton.icon(
              onPressed: () {
                backend.restoreLostStreak(appState.user, user);
                adminToast(context, 'Racha de @${user.username} restaurada: ${user.streak} días');
              },
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restaurar racha'),
            ),
        ],
      ),
    );
  }
}
