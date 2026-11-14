import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../models/user_models.dart';
import '../../services/emergency_store.dart';
import '../../services/local_backend.dart';
import '../../services/support_store.dart';
import 'admin_emergency.dart';
import 'admin_inventory.dart';
import 'admin_support.dart';
import 'admin_users.dart';

/// Panel exclusivo para usuarios con rol `admin`.
/// Pestañas: Mesa de ayuda · Usuarios · Inventario · Emergencia.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Doble seguridad: aunque alguien llegue aquí, sin rol admin no ve nada.
    if (!appState.isAdmin) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock, size: 48, color: context.muted),
            const SizedBox(height: 10),
            const Text('Acceso solo para administradores.'),
          ]),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.gold),
            const SizedBox(width: 8),
            Text('PANEL ADMIN', style: display(24)),
          ]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(122),
            child: Column(
              children: [
                const _Summary(),
                ListenableBuilder(
                  listenable: supportStore,
                  builder: (context, _) => TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: context.accent,
                    indicatorColor: context.accent,
                    unselectedLabelColor: context.muted,
                    tabs: [
                      Tab(
                        icon: Badge(
                          isLabelVisible: supportStore.unreadForAdmin > 0,
                          label: Text('${supportStore.unreadForAdmin}'),
                          child: const Icon(Icons.support_agent),
                        ),
                        text: 'Mesa de ayuda',
                      ),
                      const Tab(icon: Icon(Icons.manage_accounts), text: 'Usuarios'),
                      const Tab(icon: Icon(Icons.checkroom), text: 'Inventario'),
                      const Tab(icon: Icon(Icons.emergency_share), text: 'Emergencia'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            AdminSupportTab(),
            AdminUsersTab(),
            AdminInventoryTab(),
            AdminEmergencyTab(),
          ],
        ),
      ),
    );
  }
}

/// Cifras rápidas arriba del panel.
class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([supportStore, backend, emergencyStore]),
      builder: (context, _) {
        final open = supportStore.byStatus(TicketStatus.open).length;
        final users = backend.allUsers;
        final suspended = users.where((u) => u.suspended).length;
        Widget stat(String value, String label, Color color) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Text(value, style: display(22, color: color)),
                  Text(label, style: TextStyle(fontSize: 10.5, color: context.muted)),
                ]),
              ),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(children: [
            stat('$open', 'Tickets abiertos', const Color(0xFF4DA3FF)),
            stat('${users.length}', 'Usuarios', AppColors.green),
            stat('$suspended', 'Suspendidos', AppColors.live),
            stat(emergencyStore.active ? 'ON' : 'OFF', 'Emergencia', emergencyStore.active ? AppColors.fire : Colors.grey),
          ]),
        );
      },
    );
  }
}

/// Encabezado de sección reutilizable en las pestañas del admin.
class AdminSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const AdminSection(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: display(20)),
              if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 12, color: context.muted)),
            ]),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

void adminToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}
