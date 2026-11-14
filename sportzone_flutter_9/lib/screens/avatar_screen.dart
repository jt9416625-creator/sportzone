import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../data/avatar_catalog.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/user_models.dart';
import '../models/album_models.dart';
import '../services/album_service.dart';
import '../services/espn_api.dart';
import '../services/local_backend.dart';
import '../services/merch_api.dart';
import '../widgets/avatar_view.dart';
import '../widgets/common.dart';

/// Vestidor: arriba el avatar (Stack de capas), abajo el catálogo.
/// Pestañas: Oficial (merch de tu club) · Base · Fútbol · NBA · Tenis · UFC.
class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: AvatarCategory.values.length + 1,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(title: Text('MI AVATAR', style: display(26))),
        body: ListenableBuilder(
          listenable: backend,
          builder: (context, _) {
            final user = appState.user;
            return Column(
              children: [
                Expanded(flex: 5, child: _Preview(user: user)),
                Material(
                  color: context.cardColor2,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: context.accent,
                    indicatorColor: context.accent,
                    unselectedLabelColor: context.muted,
                    tabs: [
                      const Tab(icon: Icon(Icons.verified, size: 20), text: 'Oficial', height: 58),
                      for (final c in AvatarCategory.values) Tab(icon: Icon(c.icon, size: 20), text: c.label, height: 58),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: TabBarView(
                    children: [
                      _OfficialTab(user: user),
                      for (final c in AvatarCategory.values) _CatalogGrid(category: c, user: user),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _itemName(String? id) => MerchApi.byId(id)?.name ?? avatarItemById(id)?.name ?? '';

class _Preview extends StatelessWidget {
  final AppUser user;
  const _Preview({required this.user});

  @override
  Widget build(BuildContext context) {
    final worn = AvatarSlot.values.where((s) => s.removable && user.equipped[s] != null).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDark ? [const Color(0xFF1F2A3A), AppColors.bg] : [const Color(0xFFDCE8F5), AppColors.lightBg],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(child: Hero(tag: 'my-avatar', child: AvatarView(equipped: user.equipped))),
          Text(user.handle, style: display(22, color: context.accent)),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                if (worn.isEmpty) Center(child: Text('Toca una prenda de abajo para ponértela', style: TextStyle(fontSize: 12, color: context.muted))),
                for (final s in worn)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      avatar: MerchApi.isMerch(user.equipped[s]) ? const Icon(Icons.verified, size: 16) : null,
                      label: Text(_itemName(user.equipped[s])),
                      labelStyle: const TextStyle(fontSize: 11.5),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => backend.unequip(user, s),
                      deleteButtonTooltipMessage: 'Quitar',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════ CATÁLOGO NORMAL ═════════════════════════

class _CatalogGrid extends StatelessWidget {
  final AvatarCategory category;
  final AppUser user;
  const _CatalogGrid({required this.category, required this.user});

  @override
  Widget build(BuildContext context) {
    final items = avatarCatalog.where((i) => i.category == category).toList()..sort((a, b) => a.slot.index.compareTo(b.slot.index));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _ItemTile(item: items[i], user: user),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final AvatarItem item;
  final AppUser user;
  const _ItemTile({required this.item, required this.user});

  void _tap(BuildContext context) {
    final why = backend.whyLocked(user, item);
    if (why != null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('🔒 ${item.name}: $why')));
      return;
    }
    HapticFeedback.selectionClick();
    final on = user.equipped[item.slot] == item.id;
    if (on && item.slot.removable) {
      backend.unequip(user, item.slot);
    } else {
      backend.equip(user, item);
      album.track(MissionEvent.avatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = user.equipped[item.slot] == item.id;
    final locked = backend.whyLocked(user, item) != null;
    return _Tile(
      selected: on,
      locked: locked,
      star: item.exclusive,
      title: item.name,
      subtitle: item.slot.label,
      image: Opacity(
        opacity: locked ? 0.35 : 1,
        child: Image.asset(item.thumb, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.checkroom)),
      ),
      onTap: () => _tap(context),
    );
  }
}

class _Tile extends StatelessWidget {
  final bool selected, locked, star;
  final String title, subtitle;
  final Widget image;
  final VoidCallback onTap;

  const _Tile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
    this.locked = false,
    this.star = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? context.accent : context.borderColor2, width: selected ? 2.5 : 1),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: image),
                  const SizedBox(height: 4),
                  Text(title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: context.muted)),
                ],
              ),
              if (star) const Positioned(left: 0, top: 0, child: Icon(Icons.star, size: 16, color: AppColors.gold)),
              if (locked) Positioned(right: 0, top: 0, child: Icon(Icons.lock, size: 16, color: context.muted)),
              if (selected) Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, size: 18, color: context.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ MERCH OFICIAL ═════════════════════════

/// Equipos que tienen ropa de club (fútbol y NBA).
List<Team> _merchTeams() {
  final fav = appState.favorites;
  final list = allFollowables.where((t) => t.sport == Sport.football || t.sport == Sport.basketball).toList()
    ..sort((a, b) {
      final fa = fav.contains(a.id) ? 0 : 1, fb = fav.contains(b.id) ? 0 : 1;
      return fa != fb ? fa.compareTo(fb) : a.name.compareTo(b.name);
    });
  return list;
}

class _OfficialTab extends StatefulWidget {
  final AppUser user;
  const _OfficialTab({required this.user});

  @override
  State<_OfficialTab> createState() => _OfficialTabState();
}

class _OfficialTabState extends State<_OfficialTab> {
  Team? _team;

  @override
  void initState() {
    super.initState();
    final teams = _merchTeams();
    if (teams.isNotEmpty) _team = teams.first;
  }

  Future<void> _pickTeam() async {
    final t = await showModalBottomSheet<Team>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TeamPicker(),
    );
    if (t != null) setState(() => _team = t);
  }

  void _wear(MerchRef ref) {
    HapticFeedback.selectionClick();
    final u = widget.user;
    if (u.equipped[ref.slot] == ref.id) {
      backend.unequip(u, ref.slot);
    } else {
      backend.equipMerch(u, ref.slot, ref.id);
      album.track(MissionEvent.avatar);
    }
  }

  /// Vista previa: el cuerpo del usuario con solo esa prenda.
  Widget _preview(MerchRef ref) => AvatarView(equipped: {
        AvatarSlot.body: widget.user.equipped[AvatarSlot.body] ?? 'body_medium',
        if (widget.user.equipped[AvatarSlot.hair] != null) AvatarSlot.hair: widget.user.equipped[AvatarSlot.hair]!,
        ref.slot: ref.id,
      });

  @override
  Widget build(BuildContext context) {
    final team = _team;
    if (team == null) return const Center(child: Text('Cargando equipos…'));
    final u = widget.user;
    final club = [for (final k in [MerchKind.kit, MerchKind.scarf, MerchKind.cap]) MerchApi.clubItem(team, k)];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: AppCard(
              onTap: _pickTeam,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                TeamCrest(team: team, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(team.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(teamLeague[team.id] ?? team.sport.label, style: TextStyle(fontSize: 12, color: context.muted)),
                  ]),
                ),
                TextButton.icon(onPressed: _pickTeam, icon: const Icon(Icons.swap_horiz), label: const Text('Cambiar')),
              ]),
            ),
          ),
        ),
        _header(context, 'DISEÑOS DEL CLUB', 'Con los colores y el escudo oficial del equipo'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: [
              for (final ref in club)
                _Tile(
                  selected: u.equipped[ref.slot] == ref.id,
                  title: ref.kind.label,
                  subtitle: ref.slot.label,
                  image: _preview(ref),
                  onTap: () => _wear(ref),
                ),
            ],
          ),
        ),
        _header(context, 'CAMISETAS OFICIALES', 'Fotos reales por temporada · fuente: TheSportsDB'),
        FutureBuilder<List<OfficialKit>>(
          key: ValueKey(team.id),
          future: MerchApi.officialKits(team),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                  children: [for (var i = 0; i < 3; i++) const SkeletonBox(height: 150, radius: 16)],
                ),
              );
            }
            final kits = snap.data ?? const [];
            if (kits.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Icon(Icons.cloud_off, color: context.muted),
                    const SizedBox(height: 6),
                    Text(
                      'No encontramos camisetas oficiales de ${team.name} (o no hay conexión).\nMientras tanto puedes usar los diseños del club.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.muted, fontSize: 12.5),
                    ),
                    TextButton(onPressed: () => setState(() {}), child: const Text('Reintentar')),
                  ]),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
                children: [
                  for (final k in kits)
                    () {
                      final ref = MerchApi.officialItem(team, k);
                      return _Tile(
                        selected: u.equipped[ref.slot] == ref.id,
                        star: true,
                        title: k.typeLabel,
                        subtitle: k.season,
                        image: CachedNetworkImage(
                          imageUrl: k.imageUrl,
                          imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                        ),
                        onTap: () => _wear(ref),
                      );
                    }(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _header(BuildContext context, String title, String sub) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: display(18)),
            Text(sub, style: TextStyle(fontSize: 11.5, color: context.muted)),
          ]),
        ),
      );
}

/// Buscador de equipos para la ropa oficial.
class _TeamPicker extends StatefulWidget {
  const _TeamPicker();

  @override
  State<_TeamPicker> createState() => _TeamPickerState();
}

class _TeamPickerState extends State<_TeamPicker> {
  String _q = '';
  Sport _sport = Sport.football;

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final teams = _merchTeams().where((t) => t.sport == _sport && (q.isEmpty || t.name.toLowerCase().contains(q))).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Text('ELIGE TU EQUIPO', style: display(20)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar club o franquicia', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            SegmentedButton<Sport>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Sport.football, label: Text('Fútbol'), icon: Icon(Icons.sports_soccer)),
                ButtonSegment(value: Sport.basketball, label: Text('NBA'), icon: Icon(Icons.sports_basketball)),
              ],
              selected: {_sport},
              onSelectionChanged: (s) => setState(() => _sport = s.first),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, i) {
                  final t = teams[i];
                  return ListTile(
                    leading: TeamCrest(team: t, size: 36),
                    title: Text(t.name),
                    subtitle: Text(teamLeague[t.id] ?? t.country),
                    trailing: appState.isFavorite(t.id) ? const Icon(Icons.star, color: AppColors.gold) : null,
                    onTap: () => Navigator.pop(context, t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
