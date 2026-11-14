import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/espn_api.dart';
import '../services/live_sim.dart';
import '../widgets/common.dart';

/// Después del registro: elegir equipos, tenistas y peleadores favoritos.
/// Muestra todos los equipos de cada liga (con internet, la lista completa
/// de ESPN), agrupados por liga y con buscador.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Sport _sport = Sport.football;
  String _q = '';

  @override
  void initState() {
    super.initState();
    EspnApi.loadAllTeams(); // trae todos los equipos de las ligas (si hay internet)
  }

  /// Orden de las ligas: el de la lista `leagues`, luego el resto.
  int _leagueOrder(String name) {
    final i = leagues.indexWhere((l) => l.name == name);
    return i < 0 ? 999 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([appState, liveSim]),
          builder: (context, _) {
            final n = appState.favorites.length;
            final q = _q.toLowerCase();
            final teams = allFollowables.where((t) => t.sport == _sport && (q.isEmpty || t.name.toLowerCase().contains(q))).toList();
            final groups = <String, List<Team>>{};
            for (final t in teams) {
              groups.putIfAbsent(teamLeague[t.id] ?? 'Otros', () => []).add(t);
            }
            final keys = groups.keys.toList()..sort((a, b) => _leagueOrder(a).compareTo(_leagueOrder(b)));
            for (final k in keys) {
              groups[k]!.sort((a, b) => a.name.compareTo(b.name));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ELIGE TUS FAVORITOS', style: display(34)),
                      const SizedBox(height: 4),
                      Text('Equipos, tenistas y peleadores. Así te mostramos lo que más te importa.', style: TextStyle(color: context.muted)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar en ${_sport.label.toLowerCase()}…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: context.cardColor2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      for (final s in Sport.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: _sport == s,
                            showCheckmark: false,
                            avatar: Icon(s.icon, size: 18, color: _sport == s ? AppColors.bg : s.color),
                            label: Text('${s.label} (${allFollowables.where((t) => t.sport == s).length})'),
                            labelStyle: TextStyle(fontWeight: FontWeight.w600, color: _sport == s ? AppColors.bg : null),
                            selectedColor: AppColors.green,
                            backgroundColor: context.cardColor2,
                            side: BorderSide(color: context.borderColor2),
                            onSelected: (_) => setState(() => _sport = s),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: teams.isEmpty
                      ? Center(child: Text('No encontramos "$_q".', style: TextStyle(color: context.muted)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: keys.length,
                          itemBuilder: (context, i) {
                            final k = keys[i];
                            final league = leagues.where((l) => l.name == k).firstOrNull;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
                                  child: Text('${league?.flag ?? '•'}  $k  (${groups[k]!.length})', style: display(20)),
                                ),
                                Wrap(spacing: 10, runSpacing: 10, children: [for (final t in groups[k]!) _pick(context, t)]),
                              ],
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: appState.finishOnboarding,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(n == 0 ? 'OMITIR POR AHORA' : 'CONTINUAR ($n)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pick(BuildContext context, Team t) {
    final on = appState.isFavorite(t.id);
    return GestureDetector(
      onTap: () => appState.toggleFavorite(t.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.green.withValues(alpha: 0.15) : context.cardColor2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? context.accent : context.borderColor2, width: on ? 2 : 1),
        ),
        child: Column(
          children: [
            TeamCrest(team: t, size: 44),
            const SizedBox(height: 6),
            Text(t.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            if (t.sport == Sport.ufc || t.sport == Sport.tennis)
              Text(t.country, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: context.muted)),
          ],
        ),
      ).animate(target: on ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 180.ms),
    );
  }
}
