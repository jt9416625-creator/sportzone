import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/album_models.dart';
import '../services/album_service.dart';
import '../services/emergency_store.dart';
import '../services/live_sim.dart';
import '../services/news_images.dart';
import '../services/sports_api.dart';
import '../widgets/common.dart';
import 'match_detail_screen.dart';

/// Inicio: feed de noticias con slivers.
class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  bool _loading = true;
  Sport? _filter;

  @override
  void initState() {
    super.initState();
    _load();
    emergencyStore.addListener(_onManualContent);
  }

  void _onManualContent() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    emergencyStore.removeListener(_onManualContent);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      await Future.wait([
        DataRepo.loadNews(), // noticias reales (Google Noticias)
        DataRepo.loadMatches(), // partidos reales (ESPN)
        Future.delayed(const Duration(milliseconds: 700)),
      ]).timeout(const Duration(seconds: 25)); // tope total: nunca se queda cargando
    } catch (_) {
      // Sin red o muy lenta: se muestran las noticias manuales / de ejemplo.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Primero las noticias publicadas por un admin (contingencia), luego las de la API.
    final source = [
      ...emergencyStore.feedItems,
      if (!emergencyStore.active || emergencyStore.news.isEmpty) ...(DataRepo.liveNews.isNotEmpty ? DataRepo.liveNews : news),
    ];
    final items = source.where((n) => _filter == null || n.sport == _filter).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: SportChips(selected: _filter, onChanged: (s) => setState(() => _filter = s)),
            ),
          ),
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SkeletonBox(height: 220, radius: 18),
                ),
                childCount: 3,
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _liveStrip(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Text('NOTICIAS', style: display(22)),
                    const Spacer(),
                    Icon(emergencyStore.active && emergencyStore.news.isNotEmpty ? Icons.verified : (DataRepo.newsOk ? Icons.wifi : Icons.wifi_off), size: 14, color: context.muted),
                    const SizedBox(width: 4),
                    Text(
                      emergencyStore.active && emergencyStore.news.isNotEmpty
                          ? 'Verificadas por SportZone'
                          : (DataRepo.newsOk ? 'En tiempo real · ESPN' : 'Sin conexión: ejemplos'),
                      style: TextStyle(fontSize: 12, color: context.muted),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _NewsCard(item: items[i])
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (60 * (i > 5 ? 5 : i)).ms)
                      .slideY(begin: 0.08, end: 0),
                ),
                childCount: items.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _liveStrip(BuildContext context) {
    return ListenableBuilder(
      listenable: liveSim,
      builder: (context, _) {
        final live = matches
            .where((m) => m.status == MatchStatus.live && (_filter == null || m.sport == _filter))
            .toList();
        if (live.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                const PulsingDot(),
                const SizedBox(width: 8),
                Text('AHORA EN VIVO', style: display(22)),
              ]),
            ),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: live.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _MiniLive(match: live[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniLive extends StatelessWidget {
  final MatchItem match;
  const _MiniLive({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    return SizedBox(
      width: 230,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        borderColor: AppColors.live.withValues(alpha: 0.6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.id))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiveBadge(clock: m.clock),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TeamCrest(team: m.home, size: 34),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  BouncyScore(value: m.homeScore, size: 30),
                  Text(' - ', style: display(28, color: context.muted)),
                  BouncyScore(value: m.awayScore, size: 30),
                ]),
                TeamCrest(team: m.away, size: 34),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: 'news-${item.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: _NewsArt(item: item, height: 150),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(item.tag, style: display(14, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: display(24)),
                const SizedBox(height: 6),
                Text(item.summary, style: TextStyle(color: context.muted, fontSize: 13.5)),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(item.sport.icon, size: 14, color: item.sport.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [item.sport.label, if (item.ago.isNotEmpty) item.ago, if (item.source.isNotEmpty) item.source].join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.muted),
                    ),
                  ),
                  if (item.source == 'ESPN') const Icon(Icons.verified, size: 14, color: Color(0xFF4DA3FF)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Arte de la noticia: la foto de la nota (ESPN) o, si no trae, una imagen
/// referente buscada por NewsImages (equipo, deportista o liga).
class _NewsArt extends StatelessWidget {
  final NewsItem item;
  final double height;
  const _NewsArt({required this.item, required this.height});

  @override
  Widget build(BuildContext context) {
    final sport = item.sport;
    final fallback = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sport.color, sport.color.withValues(alpha: 0.25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(sport.icon, size: height * 0.5, color: Colors.white.withValues(alpha: 0.35))),
    );
    Widget photo(String url) => SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: url,
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
            fit: BoxFit.cover,
            placeholder: (_, _) => SkeletonBox(height: height, radius: 0),
            errorWidget: (_, _, _) => fallback,
          ),
        );
    if (item.imageUrl != null) return photo(item.imageUrl!);
    return FutureBuilder<String?>(
      future: NewsImages.forItem(item),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return SkeletonBox(height: height, radius: 0);
        final url = snap.data;
        return url == null ? fallback : photo(url);
      },
    );
  }
}

class NewsDetailScreen extends StatefulWidget {
  final NewsItem item;
  const NewsDetailScreen({super.key, required this.item});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  Timer? _timer;

  NewsItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    // La noticia cuenta para la misión solo si la lees unos segundos.
    _timer = Timer(const Duration(seconds: AlbumService.newsSecondsToCount), () {
      album.track(MissionEvent.readNews, uniqueKey: item.id);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(tag: 'news-${item.id}', child: _NewsArt(item: item, height: 240)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.tag, style: display(16, color: context.accent)),
                  const SizedBox(height: 6),
                  Text(item.title, style: display(36)),
                  const SizedBox(height: 8),
                  Text('${item.sport.label} · ${item.ago}', style: TextStyle(color: context.muted)),
                  const SizedBox(height: 20),
                  Text(item.summary, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4)),
                  const SizedBox(height: 14),
                  Text(item.body, style: const TextStyle(fontSize: 15.5, height: 1.55)),
                  if (item.url != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => launchUrl(Uri.parse(item.url!), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('LEER NOTA COMPLETA', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.bg,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
