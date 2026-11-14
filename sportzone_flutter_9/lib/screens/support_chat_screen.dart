import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../models/user_models.dart';
import '../services/support_store.dart';
import '../widgets/messenger.dart';

/// Chat de soporte técnico del usuario (estilo Messenger 2015).
class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key});

  static const _quick = [
    'Perdí mi racha 🔥',
    'No cargan los resultados',
    'Problema con mi avatar',
    'Quiero reportar a alguien',
  ];

  @override
  Widget build(BuildContext context) {
    final user = appState.user;
    return Theme(
      data: messengerTheme(context),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: const MessengerTitle(
            title: SupportStore.botName,
            subtitle: 'Activo ahora · Responde en minutos',
            avatar: SupportAvatar(size: 36),
          ),
          actions: [
            IconButton(
              tooltip: 'Información',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Soporte SportZone'),
                  content: const Text(
                    'Un administrador lee y responde tus mensajes desde el panel de la mesa de ayuda.\n\n'
                    'Por ahora el chat vive dentro de la app (sin base de datos): si cierras la app, se borra.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
                ),
              ),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: supportStore,
          builder: (context, _) {
            final t = supportStore.currentFor(user.uid);
            if (t != null && t.unreadByUser) {
              WidgetsBinding.instance.addPostFrameCallback((_) => supportStore.markReadByUser(t.id));
            }
            final resolved = t?.status == TicketStatus.resolved;
            return Column(
              children: [
                Expanded(
                  child: t == null
                      ? const _Welcome()
                      : MessengerList(
                          messages: t.messages,
                          viewerIsSupport: false,
                          typing: supportStore.typing.contains(t.id),
                          seenAt: t.seenByAdminAt,
                          otherAvatar: const SupportAvatar(),
                          header: _TicketHeader(ticket: t),
                        ),
                ),
                if (resolved)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFEAF6EA),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text('Este caso fue resuelto. Si escribes, se abre un caso nuevo.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32))),
                  ),
                MessengerComposer(
                  quickReplies: t == null || resolved ? _quick : const [],
                  onSend: (text) => supportStore.sendFromUser(user, text),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SupportAvatar(size: 84),
            const SizedBox(height: 14),
            const Text(SupportStore.botName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Normalmente responde en unos minutos', style: TextStyle(color: Mx.meta)),
            const SizedBox(height: 18),
            Text(
              '¡Hola ${appState.handle}! ¿En qué te podemos ayudar?\nEscríbenos o elige una opción de abajo.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketHeader({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        children: [
          const SupportAvatar(size: 56),
          const SizedBox(height: 8),
          const Text(SupportStore.botName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text('Caso #${ticket.id.substring(1)} · ${ticket.status == TicketStatus.open ? 'Abierto' : 'Resuelto'}',
              style: const TextStyle(fontSize: 12, color: Mx.meta)),
        ],
      ),
    );
  }
}
