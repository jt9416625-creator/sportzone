import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/espn_api.dart';
import '../services/sports_api.dart';
import '../widgets/common.dart';
import '../widgets/gamification.dart';

/// Buscador para encontrar equipos y marcarlos como favoritos.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Sport? _filter;
  League? _league;
  String _query = '';
  Timer? _debounce;
  List<Team> _remote = [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Espera a que dejes de escribir y busca en internet.
  void _onChanged(String v) {
    final q = v.trim();
    setState(() => _query = q.toLowerCase());
    _debounce?.cancel();
    if (q.length < 3) {
      setState(() {
        _remote = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final found = await SearchApi.search(q);
      if (!mounted || _controller.text.trim() != q) return;
      setState(() {
        _remote = found;
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Busca cualquier equipo, jugador o peleador',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                filled: true,
                fillColor: context.cardColor2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          SportChips(selected: _filter, onChanged: (s) => setState(() {
            _filter = s;
            _league = null;
          })),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final l in leagues)
                  if (_filter == null || l.sport == _filter)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _league?.key == l.key,
                        showCheckmark: false,
                        label: Text('${l.flag}  ${l.name}'),
                        labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _league?.key == l.key ? AppColors.bg : null),
                        selectedColor: AppColors.green,
                        backgroundColor: context.cardColor2,
                        side: BorderSide(color: context.borderColor2),
                        onSelected: (on) => setState(() => _league = on ? l : null),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListenableBuilder(
              listenable: appState,
              builder: (context, _) {
                final local = allFollowables.where((t) {
                  final okSport = _filter == null || t.sport == _filter;
                  final okText = _query.isEmpty || t.name.toLowerCase().contains(_query);
                  final okLeague = _league == null || teamLeague[t.id] == _league!.name;
                  return okSport && okText && okLeague;
                }).toList();
                // Resultados de internet que todavía no están en la lista local.
                final names = local.map((t) => t.name.toLowerCase()).toSet();
                final online = _league != null
                    ? <Team>[]
                    : _remote.where((t) {
                        final okSport = _filter == null || t.sport == _filter;
                        return okSport && !names.contains(t.name.toLowerCase());
                      }).toList();
                final found = [...local, ...online]
                  ..sort((a, b) {
                    final fa = appState.isFavorite(a.id) ? 0 : 1;
                    final fb = appState.isFavorite(b.id) ? 0 : 1;
                    return fa.compareTo(fb);
                  });

                if (found.isEmpty) {
                  return Center(
                    child: Text(
                      _searching ? 'Buscando en internet…' : 'No encontramos resultados',
                      style: TextStyle(color: context.muted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: found.length + (_searching ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == found.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    return _tile(context, found[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Team t) {
    final fav = appState.isFavorite(t.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            TeamCrest(team: t, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${t.sport.label} · ${teamLeague[t.id] ?? t.country}', style: TextStyle(fontSize: 12, color: context.muted)),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                if (!allFollowables.any((x) => x.id == t.id)) allFollowables.add(t);
                final fresh = appState.toggleFavorite(t.id);
                if (fresh.isNotEmpty) await showNewBadges(context, fresh);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(
                  fav ? Icons.star : Icons.star_border,
                  key: ValueKey(fav),
                  color: fav ? AppColors.gold : context.muted,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
