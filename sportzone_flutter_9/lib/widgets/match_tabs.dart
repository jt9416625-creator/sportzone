import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart' show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/predict.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../services/chat_store.dart';
import '../services/espn_api.dart';
import 'common.dart';
import 'gamification.dart';

// ───────────────────────── piezas pequeñas ─────────────────────────

/// Barra de probabilidades: local / empate / visitante.
class ProbBar extends StatelessWidget {
  final MatchItem match;
  const ProbBar({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final h = m.probHome, a = m.probAway, d = m.probDraw ?? 0;
    if (h == null || a == null) {
      return Text('Todavía no hay datos suficientes para calcular probabilidades.', style: TextStyle(color: context.muted));
    }
    final hasDraw = d > 0;
    int flex(double v) => (v * 10).round().clamp(1, 1000).toInt();
    const homeColor = Color(0xFF4DA3FF);
    const awayColor = Color(0xFFFF8A1F);
    final drawColor = context.isDark ? Colors.white38 : Colors.black26;

    Widget label(String pct, String name, CrossAxisAlignment al) => Expanded(
          child: Column(
            crossAxisAlignment: al,
            children: [
              Text('${pct.split('.').first}%', style: display(30)),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.muted)),
            ],
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            label(h.toStringAsFixed(0), m.home.short, CrossAxisAlignment.start),
            if (hasDraw) label(d.toStringAsFixed(0), 'Empate', CrossAxisAlignment.center),
            label(a.toStringAsFixed(0), m.away.short, CrossAxisAlignment.end),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(flex: flex(h), child: Container(height: 12, color: homeColor)),
              if (hasDraw) Expanded(flex: flex(d), child: Container(height: 12, color: drawColor)),
              Expanded(flex: flex(a), child: Container(height: 12, color: awayColor)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          m.probSource.isEmpty ? '' : 'Fuente: ${m.probSource}',
          style: TextStyle(fontSize: 11, color: context.muted),
        ),
      ],
    );
  }
}

/// Racha: G (ganó), E (empató), P (perdió).
class FormChips extends StatelessWidget {
  final String form;
  const FormChips(this.form, {super.key});

  @override
  Widget build(BuildContext context) {
    if (form.isEmpty) return Text('Sin datos', style: TextStyle(fontSize: 12, color: context.muted));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in form.split(''))
          Container(
            margin: const EdgeInsets.only(right: 5),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (c) {
                'W' => const Color(0xFF1FBF6B),
                'D' => const Color(0xFF8A90A0),
                _ => const Color(0xFFE5484D),
              },
            ),
            child: Text(
              switch (c) { 'W' => 'G', 'D' => 'E', _ => 'P' },
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

Widget _sectionTitle(BuildContext context, String t) =>
    Padding(padding: const EdgeInsets.only(top: 6, bottom: 10), child: Text(t, style: display(22)));

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 46, color: context.muted),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
        ]),
      ),
    );
  }
}

// ───────────────────────── RESUMEN ─────────────────────────
class SummaryTab extends StatelessWidget {
  final MatchItem match;
  const SummaryTab({super.key, required this.match});

  String _sentence(MatchItem m) {
    final h = m.home.name, a = m.away.name;
    switch (m.status) {
      case MatchStatus.upcoming:
        return '$h recibe a $a${m.kickoff != null ? ' el ${m.clock}' : ''}${m.venue != null ? ' en ${m.venue}' : ''}.';
      case MatchStatus.live:
        if (m.homeScore == m.awayScore) return '$h y $a empatan ${m.homeScore}-${m.awayScore} (${m.clock}).';
        final lead = m.homeScore > m.awayScore ? h : a;
        return '$lead va ganando ${m.homeScore > m.awayScore ? m.homeScore : m.awayScore}-${m.homeScore > m.awayScore ? m.awayScore : m.homeScore} (${m.clock}).';
      case MatchStatus.finished:
        if (m.homeScore == m.awayScore) return '$h y $a empataron ${m.homeScore}-${m.awayScore}.';
        final homeWon = m.homeScore > m.awayScore;
        return '${homeWon ? h : a} venció ${homeWon ? m.homeScore : m.awayScore}-${homeWon ? m.awayScore : m.homeScore} a ${homeWon ? a : h}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = match;
    final key = m.events.where((e) => e.type == EventType.goal || e.type == EventType.red || e.type == EventType.basket).toList();
    final shown = key.length > 8 ? key.sublist(key.length - 8) : key;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESUMEN', style: display(20, color: context.accent)),
              const SizedBox(height: 6),
              Text(_sentence(m), style: const TextStyle(fontSize: 15.5, height: 1.4)),
              if (m.venue != null && m.status != MatchStatus.upcoming) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.stadium_outlined, size: 16, color: context.muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(m.venue!, style: TextStyle(fontSize: 12.5, color: context.muted))),
                ]),
              ],
            ],
          ),
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle(context, 'MOMENTOS CLAVE'),
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  SizedBox(width: 56, child: Text(e.minute, style: display(16, color: context.muted))),
                  eventIcon(e.type, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.text, style: const TextStyle(fontSize: 13.5))),
                ]),
              ),
            ),
        ],
        if (m.stats.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle(context, 'ESTADÍSTICAS CLAVE'),
          AppCard(
            child: Column(children: [
              for (final r in m.stats.take(3)) StatBar(row: r, homeColor: const Color(0xFF4DA3FF), awayColor: const Color(0xFFFF8A1F)),
            ]),
          ),
        ],
        if (shown.isEmpty && m.stats.isEmpty && m.status != MatchStatus.upcoming)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text('Todavía no hay más datos de este partido.', textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
          ),
      ],
    );
  }
}

// ───────────────────────── PREVIA ─────────────────────────
class PreviewTab extends StatelessWidget {
  final MatchItem match;
  final List<StandingRow> table;
  const PreviewTab({super.key, required this.match, required this.table});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final hr = rowFor(table, m.home), ar = rowFor(table, m.away);

    Widget team(Team t, StandingRow? r, String form) => Expanded(
          child: AppCard(
            child: Column(children: [
              TeamCrest(team: t, size: 42),
              const SizedBox(height: 8),
              Text(t.name, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              if (r != null) ...[
                Text('${r.rank}º', style: display(32, color: context.accent)),
                Text(m.sport == Sport.football ? '${r.points} pts · ${r.played} PJ' : '${r.wins}G - ${r.losses}P', style: TextStyle(fontSize: 12, color: context.muted)),
              ] else
                Text('Sin posición', style: TextStyle(fontSize: 12, color: context.muted)),
              const SizedBox(height: 10),
              FormChips(form),
            ]),
          ),
        );

    final notes = <String>[];
    if (hr != null && ar != null) {
      final diff = (hr.rank - ar.rank).abs();
      final better = hr.rank < ar.rank ? m.home.name : m.away.name;
      notes.add(diff == 0 ? 'Llegan igualados en la tabla.' : '$better está $diff puesto${diff == 1 ? '' : 's'} arriba en la tabla.');
    }
    if (m.homeForm.isNotEmpty) {
      final w = m.homeForm.split('').where((c) => c == 'W').length;
      notes.add('${m.home.name} ganó $w de sus últimos ${m.homeForm.length}.');
    }
    if (m.awayForm.isNotEmpty) {
      final w = m.awayForm.split('').where((c) => c == 'W').length;
      notes.add('${m.away.name} ganó $w de sus últimos ${m.awayForm.length}.');
    }
    final c = h2hCounts(m);
    if (c.home + c.draws + c.away > 0) {
      notes.add('En sus últimos ${c.home + c.draws + c.away} duelos: ${c.home} victorias de ${m.home.short}, ${c.draws} empates y ${c.away} de ${m.away.short}.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.event, size: 18, color: context.accent),
              const SizedBox(width: 8),
              Expanded(child: Text('${m.competition} · ${m.clock}', style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            if (m.venue != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.stadium_outlined, size: 18, color: context.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(m.venue!, style: TextStyle(color: context.muted))),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        _sectionTitle(context, 'CÓMO LLEGAN'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          team(m.home, hr, m.homeForm),
          const SizedBox(width: 10),
          team(m.away, ar, m.awayForm),
        ]),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle(context, 'CLAVES'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.check_circle, size: 16, color: context.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(n, style: const TextStyle(height: 1.35))),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── PREDICCIONES ─────────────────────────
class PredictionsTab extends StatelessWidget {
  final MatchItem match;
  const PredictionsTab({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final voted = appState.votes[m.id];
        final hasDraw = (m.probDraw ?? 0) > 0 || m.sport == Sport.football;
        final options = [
          ('home', m.home.short),
          if (hasDraw) ('draw', 'Empate'),
          ('away', m.away.short),
        ];
        final base = {'home': 480, 'draw': hasDraw ? 180 : 0, 'away': 340};
        final counts = {...base};
        if (voted != null) counts[voted] = counts[voted]! + 1;
        final total = counts.values.reduce((a, b) => a + b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PROBABILIDAD DE VICTORIA', style: display(20)),
                const SizedBox(height: 12),
                ProbBar(match: m),
              ]),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('¿QUIÉN GANA SEGÚN TÚ?', style: display(20)),
                const SizedBox(height: 12),
                if (m.status == MatchStatus.finished)
                  Text('El partido ya terminó. Las votaciones están cerradas.', style: TextStyle(color: context.muted))
                else if (voted == null) ...[
                  Row(children: [
                    for (final o in options)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            onPressed: () async {
                              final fresh = appState.vote(m.id, o.$1);
                              await showRewardDialog(
                                context,
                                title: '¡Predicción enviada!',
                                subtitle: 'Mira cómo votó el resto de fanáticos.',
                                icon: Icons.insights,
                                color: const Color(0xFF4DA3FF),
                                xp: 25,
                              );
                              if (context.mounted) await showNewBadges(context, fresh);
                            },
                            child: Text(o.$2),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text('+25 XP por votar', style: TextStyle(fontSize: 12, color: context.accent)),
                ] else
                  for (final o in options)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        SizedBox(width: 56, child: Text(o.$2, style: TextStyle(fontWeight: voted == o.$1 ? FontWeight.w800 : FontWeight.w500))),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: counts[o.$1]! / total),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: v,
                                minHeight: 12,
                                backgroundColor: context.isDark ? const Color(0xFF0E1117) : const Color(0xFFE3E6EE),
                                color: voted == o.$1 ? AppColors.green : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 52, child: Text('${(counts[o.$1]! / total * 100).round()}%', textAlign: TextAlign.right, style: display(18))),
                      ]),
                    ),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Los votos de otros fanáticos son de ejemplo hasta conectar la base de datos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: context.muted)),
          ],
        );
      },
    );
  }
}

// ───────────────────────── CHAT ─────────────────────────
class ChatPanel extends StatefulWidget {
  final String roomId;
  final String home, away;
  final bool live;
  const ChatPanel({super.key, required this.roomId, required this.home, required this.away, this.live = false});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (chatStore.room(widget.roomId).isEmpty) {
      for (var i = 0; i < 3; i++) {
        chatStore.fakeFan(widget.roomId, widget.home, widget.away, live: widget.live);
      }
    }
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      chatStore.fakeFan(widget.roomId, widget.home, widget.away, live: widget.live);
    });
    chatStore.addListener(_toBottom);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    chatStore.removeListener(_toBottom);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    if (appState.user.muted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Un moderador te silenció en los chats. Escribe a soporte si crees que es un error.')));
      return;
    }
    chatStore.send(widget.roomId, appState.username, t);
    _controller.clear();
  }

  String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.green.withValues(alpha: 0.10),
          child: Text('Chat de demostración: se conecta con otros usuarios cuando conectemos la base de datos.',
              style: TextStyle(fontSize: 11.5, color: context.muted)),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: chatStore,
            builder: (context, _) {
              final msgs = chatStore.room(widget.roomId);
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(14),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final x = msgs[i];
                  return Align(
                    alignment: x.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        color: x.mine ? AppColors.green.withValues(alpha: context.isDark ? 0.22 : 0.45) : context.cardColor2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(x.user, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: x.mine ? context.accent : x.color)),
                            const SizedBox(width: 8),
                            Text(_hm(x.time), style: TextStyle(fontSize: 10.5, color: context.muted)),
                          ]),
                          const SizedBox(height: 2),
                          Text(x.text),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Escribe lo que opinas del partido…',
                    filled: true,
                    fillColor: context.cardColor2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _send,
                style: IconButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.bg),
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── CLASIFICACIÓN ─────────────────────────
/// Tabla de posiciones. Con `match` resalta a los dos equipos del partido.
/// Sin `match` (tabla completa de la liga) puedes tocar un equipo para seguirlo.
class TableTab extends StatelessWidget {
  final MatchItem? match;
  final Sport sport;
  final String leagueName;
  final List<StandingRow> table;
  final bool loading;
  const TableTab({
    super.key,
    this.match,
    required this.sport,
    this.leagueName = '',
    required this.table,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView(padding: const EdgeInsets.all(16), children: [for (var i = 0; i < 8; i++) const Padding(padding: EdgeInsets.only(bottom: 8), child: SkeletonBox(height: 40))]);
    }
    if (table.isEmpty) return const _Info(Icons.leaderboard_outlined, 'No pudimos cargar la clasificación de esta liga.\nDesliza hacia abajo para reintentar.');
    final football = sport == Sport.football;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final rows = <Widget>[];
        String group = '\u0000';
        for (final r in table) {
          if (r.group != group) {
            group = r.group;
            if (group.isNotEmpty) {
              rows.add(Padding(padding: const EdgeInsets.fromLTRB(4, 14, 0, 6), child: Text(group.toUpperCase(), style: display(18, color: context.accent))));
            }
          }
          final mine = match != null && (sameTeam(r, match!.home) || sameTeam(r, match!.away));
          final team = teamFromStanding(r, sport, leagueName);
          final fav = appState.isFavorite(team.id);
          rows.add(GestureDetector(
            onTap: match != null
                ? null
                : () async {
                    if (!allFollowables.any((x) => x.id == team.id)) allFollowables.add(team);
                    final fresh = appState.toggleFavorite(team.id);
                    if (fresh.isNotEmpty) await showNewBadges(context, fresh);
                  },
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: mine ? AppColors.green.withValues(alpha: context.isDark ? 0.14 : 0.35) : context.cardColor2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mine ? context.accent : context.borderColor2),
              ),
              child: Row(children: [
                SizedBox(width: 24, child: Text('${r.rank}', style: display(17, color: context.muted))),
                if (r.logo != null)
                  CachedNetworkImage(imageUrl: r.logo!, imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage, width: 22, height: 22, errorWidget: (_, __, ___) => const SizedBox(width: 22))
                else
                  const SizedBox(width: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(r.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: mine || fav ? FontWeight.w800 : FontWeight.w600, fontSize: 13))),
                _cell('${r.played}', 28),
                if (football) ...[
                  _cell('${r.wins}', 24),
                  _cell('${r.draws}', 24),
                  _cell('${r.losses}', 24),
                  _cell('${r.gd > 0 ? '+' : ''}${r.gd}', 34),
                  SizedBox(width: 34, child: Text('${r.points}', textAlign: TextAlign.center, style: display(18))),
                ] else ...[
                  _cell('${r.wins}', 28),
                  _cell('${r.losses}', 28),
                ],
                if (match == null) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(fav ? Icons.star : Icons.star_border, size: 20, color: fav ? AppColors.gold : context.muted)),
              ]),
            ),
          ));
        }

        Widget head(String t, double w) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.muted)));

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
              child: Row(children: [
                const SizedBox(width: 24 + 22 + 8),
                Expanded(child: Text(match == null ? 'Equipo (toca para seguir)' : 'Equipo', style: TextStyle(fontSize: 11, color: context.muted))),
                head('PJ', 28),
                if (football) ...[head('G', 24), head('E', 24), head('P', 24), head('DG', 34), head('PTS', 34)] else ...[head('G', 28), head('P', 28)],
                if (match == null) const SizedBox(width: 24),
              ]),
            ),
            ...rows,
          ],
        );
      },
    );
  }

  Widget _cell(String t, double w) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)));
}

// ───────────────────────── CARA A CARA ─────────────────────────
class H2HTab extends StatelessWidget {
  final MatchItem match;
  const H2HTab({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final c = h2hCounts(m);
    final total = c.home + c.draws + c.away;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PROBABILIDAD', style: display(20)),
            const SizedBox(height: 10),
            ProbBar(match: m),
          ]),
        ),
        const SizedBox(height: 14),
        _sectionTitle(context, 'RACHAS'),
        AppCard(
          child: Column(children: [
            _formRow(context, m.home, m.homeForm),
            const Divider(height: 22),
            _formRow(context, m.away, m.awayForm),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const FormChips('W'), Text('ganó   ', style: TextStyle(fontSize: 12, color: context.muted)),
              const FormChips('D'), Text('empató   ', style: TextStyle(fontSize: 12, color: context.muted)),
              const FormChips('L'), Text('perdió', style: TextStyle(fontSize: 12, color: context.muted)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        _sectionTitle(context, 'HISTORIAL DE ENFRENTAMIENTOS'),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('No encontramos enfrentamientos anteriores.', textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
          )
        else ...[
          AppCard(
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _count(context, '${c.home}', 'Victorias ${m.home.short}'),
                _count(context, '${c.draws}', 'Empates'),
                _count(context, '${c.away}', 'Victorias ${m.away.short}'),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          for (final g in m.h2h)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  SizedBox(width: 78, child: Text(g.date, style: TextStyle(fontSize: 11.5, color: context.muted))),
                  Expanded(child: Text(g.homeName, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${g.homeScore} - ${g.awayScore}', style: display(20))),
                  Expanded(child: Text(g.awayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
        ],
      ],
    );
  }

  Widget _formRow(BuildContext context, Team t, String form) {
    return Row(children: [
      TeamCrest(team: t, size: 30),
      const SizedBox(width: 10),
      Expanded(child: Text(t.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
      FormChips(form),
    ]);
  }

  Widget _count(BuildContext context, String n, String label) => Column(children: [
        Text(n, style: display(34, color: context.accent)),
        Text(label, style: TextStyle(fontSize: 11.5, color: context.muted)),
      ]);
}
