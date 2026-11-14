import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../data/album_data.dart';
import '../../models/album_models.dart';
import '../../models/models.dart';
import '../../services/album_service.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/sticker_card.dart';
import 'missions_screen.dart';
import 'pack_opening_screen.dart';

/// Álbum SportZone: portada + 9 páginas que se pasan como un libro.
class AlbumScreen extends StatefulWidget {
  final int initialPage;
  const AlbumScreen({super.key, this.initialPage = 0});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late final PageController _pc = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int i) => _pc.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  Future<void> _openPack() async {
    final page = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const PackOpeningScreen()));
    if (page != null && mounted) _go(page);
  }

  void _exchange() {
    final ok = album.exchangeDuplicates();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok
            ? '¡Canjeaste ${AlbumService.duplicatesPerPack} repetidas por 1 sobre!'
            : 'Necesitas ${AlbumService.duplicatesPerPack} repetidas para canjear un sobre.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ÁLBUM SPORTZONE', style: display(24)),
        actions: [
          ListenableBuilder(
            listenable: album,
            builder: (context, _) => IconButton(
              tooltip: 'Misiones',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsScreen())),
              icon: Badge(isLabelVisible: album.claimable > 0, label: Text('${album.claimable}'), child: const Icon(Icons.task_alt)),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: album,
        builder: (context, _) {
          final s = album.state;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${album.ownedCount} / ${albumStickers.length} láminas', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: album.completion, minHeight: 8, color: AppColors.green, backgroundColor: context.borderColor2),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _exchange,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text('Repetidas: ${s.duplicates}'),
                  ),
                ]),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: albumPages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: i == 0 ? const _Cover() : _AlbumPageView(page: albumPages[i]),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  itemCount: albumPages.length,
                  itemBuilder: (context, i) {
                    final p = albumPages[i];
                    final done = i > 0 && album.ownedInPage(i) == stickersOfPage(i).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: _page == i,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        avatar: done ? const Icon(Icons.check_circle, size: 16, color: AppColors.green) : null,
                        label: Text(i == 0 ? 'Portada' : '$i'),
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: _page == i ? AppColors.bg : null),
                        selectedColor: p.color,
                        onSelected: (_) => _go(i),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: s.packs > 0 ? _openPack : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsScreen())),
                      style: FilledButton.styleFrom(
                        backgroundColor: s.packs > 0 ? AppColors.green : context.cardColor2,
                        foregroundColor: s.packs > 0 ? AppColors.bg : null,
                        padding: const EdgeInsets.all(15),
                      ),
                      icon: Icon(s.packs > 0 ? Icons.mail : Icons.task_alt),
                      label: Text(
                        s.packs > 0 ? 'ABRIR SOBRE (${s.packs})' : 'SIN SOBRES · COMPLETA MISIONES',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Portada con la marca SportZone.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF16202E), Color(0xFF0B0E14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppColors.green, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            const Positioned.fill(child: SzWatermark(opacity: 0.07, fontSize: 26)),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.sports_soccer, color: AppColors.green, size: 56),
                    Text('ÁLBUM', style: display(26, color: Colors.white70)),
                    Text('SPORTZONE', style: display(52, color: AppColors.green)),
                    Text('EDICIÓN MULTIDEPORTE ${DateTime.now().year}', style: const TextStyle(color: Colors.white70, letterSpacing: 3, fontSize: 12)),
                    const SizedBox(height: 18),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (final s in Sport.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(children: [
                            Icon(s.icon, color: s.color, size: 30),
                            Text(s.label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(fit: StackFit.expand, children: [
                        CircularProgressIndicator(value: album.completion, strokeWidth: 10, color: AppColors.green, backgroundColor: Colors.white12),
                        Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${(album.completion * 100).round()}%', style: display(38, color: Colors.white)),
                            Text('${album.ownedCount}/${albumStickers.length}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AvatarBubble(equipped: u.equipped, size: 44, border: AppColors.green),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('COLECCIONISTA', style: TextStyle(color: Colors.white54, fontSize: 10.5, letterSpacing: 2)),
                        Text(u.handle, style: display(22, color: Colors.white)),
                      ]),
                    ]),
                    const SizedBox(height: 18),
                    const Text(
                      '62 láminas · 9 páginas · fútbol, NBA, tenis y UFC\nDesliza para pasar de página →',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una página del álbum con sus casillas.
class _AlbumPageView extends StatelessWidget {
  final AlbumPage page;
  const _AlbumPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final list = stickersOfPage(page.index);
    final s = album.state;
    final have = album.ownedInPage(page.index);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF7F4EC), // papel
        border: Border.all(color: page.color, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(child: SzWatermark(color: page.color, opacity: 0.09, fontSize: 20)),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  color: page.color,
                  child: Row(children: [
                    Icon(page.sport?.icon ?? Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(page.title.toUpperCase(), style: display(22, color: Colors.white)),
                        Text(page.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                      ]),
                    ),
                    Text('$have/${list.length}', style: display(22, color: Colors.white)),
                  ]),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: StickerCard.ratio,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final st = list[i];
                      return StickerCard(
                        sticker: st,
                        owned: s.has(st.id),
                        count: s.countOf(st.id),
                        fresh: s.fresh.contains(st.id),
                        onTap: s.has(st.id) ? () => showStickerDetail(context, st) : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Álbum SportZone · página ${page.index}', style: TextStyle(fontSize: 10.5, color: Colors.black.withValues(alpha: 0.4))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lámina en grande.
Future<void> showStickerDetail(BuildContext context, Sticker st) {
  album.markSeen(st.id);
  final count = album.state.countOf(st.id);
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 240, child: StickerCard(sticker: st, owned: true, count: count)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: st.rarity.color, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${st.rarity.label.toUpperCase()} · Nº ${st.number}${count > 1 ? ' · ${count - 1} repetida${count > 2 ? 's' : ''}' : ''}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: Colors.white))),
        ],
      ),
    ),
  );
}
