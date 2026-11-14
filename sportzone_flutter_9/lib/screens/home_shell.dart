import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../services/emergency_store.dart';
import '../services/live_sim.dart';
import '../services/net.dart';
import '../services/sports_api.dart';
import '../services/support_store.dart';
import '../widgets/avatar_view.dart';
import '../widgets/common.dart';
import '../widgets/gamification.dart';
import '../services/album_service.dart';
import 'admin/admin_panel_screen.dart';
import 'album/album_screen.dart';
import 'avatar_screen.dart';
import 'hub_screen.dart';
import 'live_screen.dart';
import 'news_feed_screen.dart';
import 'results_screen.dart';
import 'search_screen.dart';
import 'support_chat_screen.dart';

/// Estructura principal: barra superior común + 5 secciones abajo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    NewsFeedScreen(),
    ResultsScreen(),
    LiveScreen(),
    SearchScreen(),
    HubScreen(),
  ];

  static const _titles = ['SPORTZONE', 'RESULTADOS', 'EN VIVO', 'BUSCAR', 'HUB DEL FANÁTICO'];

  @override
  void initState() {
    super.initState();
    liveSim.start(); // arranca el partido en vivo de ejemplo
    DataRepo.loadMatches(); // partidos reales (si hay internet)
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _title(context),
        actions: [
          _StreakChip(onTap: () => setState(() => _index = 4)),
          if (_index == 4) const Padding(padding: EdgeInsets.only(right: 4), child: ThemeSwitch()),
          ListenableBuilder(
            listenable: Listenable.merge([appState, supportStore, album]),
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (appState.isAdmin)
                  IconButton(
                    tooltip: 'Panel de administración',
                    onPressed: () => _open(const AdminPanelScreen()),
                    icon: Badge(
                      isLabelVisible: supportStore.unreadForAdmin > 0,
                      label: Text('${supportStore.unreadForAdmin}'),
                      child: const Icon(Icons.admin_panel_settings_outlined),
                    ),
                  ),
                IconButton(
                  tooltip: 'Álbum y misiones',
                  onPressed: () => _open(const AlbumScreen()),
                  icon: Badge(
                    isLabelVisible: album.state.packs + album.claimable > 0,
                    label: Text('${album.state.packs + album.claimable}'),
                    child: const Icon(Icons.collections_bookmark_outlined),
                  ),
                ),
                IconButton(
                  tooltip: 'Soporte técnico',
                  onPressed: () => _open(const SupportChatScreen()),
                  icon: Badge(
                    isLabelVisible: supportStore.hasUnreadForUser(appState.user.uid),
                    smallSize: 9,
                    child: const Icon(Icons.headset_mic_outlined),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 2),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _open(const AvatarScreen()),
                    child: Tooltip(
                      message: 'Mi avatar',
                      child: AvatarBubble(equipped: appState.user.equipped, size: 34, border: context.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _StatusBanner(),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.scoreboard_outlined), selectedIcon: Icon(Icons.scoreboard), label: 'Resultados'),
          NavigationDestination(icon: Icon(Icons.sensors, color: AppColors.live), selectedIcon: Icon(Icons.sensors, color: AppColors.live), label: 'En vivo'),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Hub'),
        ],
      ),
    );
  }

  Widget _title(BuildContext context) {
    final t = _titles[_index];
    if (_index == 0) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_soccer, color: context.accent),
        const SizedBox(width: 8),
        Flexible(child: Text(t, overflow: TextOverflow.fade, softWrap: false, style: display(26, color: context.accent))),
      ]);
    }
    if (_index == 2) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const PulsingDot(size: 11),
        const SizedBox(width: 10),
        Text(t, style: display(26)),
      ]);
    }
    return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(t, style: display(26)));
  }
}

class _StreakChip extends StatelessWidget {
  final VoidCallback onTap;
  const _StreakChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.fire.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const StreakFlame(size: 18),
            const SizedBox(width: 3),
            Text('${appState.streak}', style: display(19, color: AppColors.fire)),
          ]),
        ),
      ),
    );
  }
}

/// Avisos globales: modo emergencia (admin) o sin conexión con las APIs.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([emergencyStore, Net.online]),
      builder: (context, _) {
        Widget? banner;
        if (emergencyStore.active) {
          banner = _bar(Icons.campaign, emergencyStore.bannerText, AppColors.fire);
        } else if (!Net.online.value) {
          banner = _bar(Icons.wifi_off, 'Sin conexión con los proveedores de datos. Mostrando información guardada.', Colors.blueGrey);
        }
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: banner ?? const SizedBox(width: double.infinity),
        );
      },
    );
  }

  Widget _bar(IconData icon, String text, Color color) => Container(
        width: double.infinity,
        color: color.withValues(alpha: 0.16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}
