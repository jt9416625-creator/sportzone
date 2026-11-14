import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../services/emergency_store.dart';
import '../../services/espn_api.dart';
import '../../widgets/common.dart';
import 'admin_panel_screen.dart';

/// Contingencia de datos: publicar a mano resultados, tablas y noticias
/// para que la app tenga contenido aunque las APIs externas se caigan.
class AdminEmergencyTab extends StatelessWidget {
  const AdminEmergencyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: emergencyStore,
      // SingleChildScrollView + Column: los formularios no pierden lo escrito al hacer scroll.
      builder: (context, _) => const SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeCard(),
            AdminSection('RESULTADO DE PARTIDO', subtitle: 'Sale en Resultados, En vivo e Inicio con la etiqueta "Verificado"'),
            _MatchForm(),
            _ManualMatches(),
            AdminSection('TABLA DE CLASIFICACIÓN', subtitle: 'Se usa si la API de tablas falla o si el modo emergencia está activo'),
            _TableEditor(),
            AdminSection('NOTICIA DESTACADA', subtitle: 'Aparece fijada arriba en Inicio'),
            _NewsForm(),
            _ManualNewsList(),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════ MODO EMERGENCIA ═════════════════════════

class _ModeCard extends StatefulWidget {
  const _ModeCard();

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  late final _text = TextEditingController(text: emergencyStore.bannerText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = emergencyStore.active;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: AppCard(
        borderColor: on ? AppColors.fire : null,
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.emergency_share, color: on ? AppColors.fire : context.muted, size: 32),
              title: Text('MODO EMERGENCIA', style: display(20, color: on ? AppColors.fire : null)),
              subtitle: const Text('Muestra un aviso a todos y prioriza el contenido publicado a mano.'),
              value: on,
              onChanged: (v) {
                emergencyStore.setActive(v, text: _text.text);
                adminToast(context, v ? 'Modo emergencia ACTIVADO' : 'Modo emergencia desactivado');
              },
            ),
            TextField(
              controller: _text,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Texto del aviso',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Actualizar aviso',
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    emergencyStore.setActive(emergencyStore.active, text: _text.text);
                    adminToast(context, 'Aviso actualizado');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════ PARTIDOS ═════════════════════════

/// Ligas donde se pueden cargar resultados a mano (no UFC: tiene su propio formato).
List<League> get _matchLeagues => leagues.where((l) => l.sport != Sport.ufc).toList();
List<League> get _tableLeagues => leagues.where((l) => l.sport == Sport.football || l.sport == Sport.basketball).toList();

/// Busca el equipo por nombre (para usar su escudo) o crea uno nuevo.
Team _teamFor(String name, Sport sport) {
  final n = name.trim();
  for (final t in allFollowables) {
    if (t.sport == sport && t.name.toLowerCase() == n.toLowerCase()) return t;
  }
  final words = n.split(' ').where((w) => w.isNotEmpty).toList();
  final short = words.length >= 2 ? words.take(3).map((w) => w[0]).join().toUpperCase() : n.substring(0, n.length.clamp(0, 3)).toUpperCase();
  return Team(
    id: 'manual_t_${n.toLowerCase().hashCode}',
    name: n,
    short: short,
    sport: sport,
    color: HSLColor.fromAHSL(1, (n.hashCode.abs() % 360).toDouble(), 0.5, 0.42).toColor(),
  );
}

class _MatchForm extends StatefulWidget {
  const _MatchForm();

  @override
  State<_MatchForm> createState() => _MatchFormState();
}

class _MatchFormState extends State<_MatchForm> {
  final _formKey = GlobalKey<FormState>();
  League _league = _matchLeagues.first;
  String _home = '', _away = '';
  int _hs = 0, _as = 0;
  MatchStatus _status = MatchStatus.finished;
  final _clock = TextEditingController(text: 'FINAL');
  final _note = TextEditingController();
  int _formVersion = 0; // para limpiar los Autocomplete

  @override
  void dispose() {
    _clock.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setStatus(MatchStatus s) {
    setState(() {
      _status = s;
      _clock.text = switch (s) {
        MatchStatus.finished => 'FINAL',
        MatchStatus.live => _league.sport == Sport.basketball ? 'Q1 12:00' : "1'",
        MatchStatus.upcoming => 'Hoy 20:00',
      };
    });
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    final m = emergencyStore.publishMatch(
      league: _league,
      home: _teamFor(_home, _league.sport),
      away: _teamFor(_away, _league.sport),
      homeScore: _status == MatchStatus.upcoming ? 0 : _hs,
      awayScore: _status == MatchStatus.upcoming ? 0 : _as,
      status: _status,
      clock: _clock.text.trim().isEmpty ? 'FINAL' : _clock.text.trim(),
      note: _note.text,
    );
    adminToast(context, 'Publicado: ${m.home.name} ${m.homeScore}-${m.awayScore} ${m.away.name}');
    setState(() {
      _home = '';
      _away = '';
      _hs = 0;
      _as = 0;
      _note.clear();
      _formVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final teams = allFollowables.where((t) => t.sport == _league.sport).toList();
    Widget teamField(String label, ValueChanged<String> onChanged) => Autocomplete<Team>(
      key: ValueKey('$label-$_formVersion-${_league.key}'),
      displayStringForOption: (t) => t.name,
      optionsBuilder: (v) => v.text.length < 2 ? const Iterable<Team>.empty() : teams.where((t) => t.name.toLowerCase().contains(v.text.toLowerCase())).take(8),
      onSelected: (t) => onChanged(t.name),
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
        controller: controller,
        focusNode: focus,
        onChanged: onChanged,
        validator: (v) => (v ?? '').trim().length < 2 ? 'Escribe el equipo' : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );

    Widget score(int value, ValueChanged<int> set) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(visualDensity: VisualDensity.compact, onPressed: value > 0 ? () => set(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
        SizedBox(
          width: 34,
          child: Text('$value', textAlign: TextAlign.center, style: display(28)),
        ),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => set(value + 1), icon: const Icon(Icons.add_circle_outline)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<League>(
                initialValue: _league,
                decoration: const InputDecoration(labelText: 'Liga', border: OutlineInputBorder(), isDense: true),
                items: [for (final l in _matchLeagues) DropdownMenuItem(value: l, child: Text('${l.flag}  ${l.name}'))],
                onChanged: (l) => setState(() {
                  _league = l!;
                  _formVersion++;
                }),
              ),
              const SizedBox(height: 10),
              teamField('Local', (v) => _home = v),
              const SizedBox(height: 8),
              teamField('Visitante', (v) => _away = v),
              const SizedBox(height: 10),
              SegmentedButton<MatchStatus>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: MatchStatus.upcoming, label: Text('Próximo')),
                  ButtonSegment(value: MatchStatus.live, label: Text('En vivo')),
                  ButtonSegment(value: MatchStatus.finished, label: Text('Final')),
                ],
                selected: {_status},
                onSelectionChanged: (s) => _setStatus(s.first),
              ),
              if (_status != MatchStatus.upcoming)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      score(_hs, (v) => setState(() => _hs = v)),
                      Text('-', style: display(28, color: context.muted)),
                      score(_as, (v) => setState(() => _as = v)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clock,
                      decoration: const InputDecoration(
                        labelText: 'Reloj / estado',
                        hintText: "FINAL · 67' · Q3 5:42",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'Detalle (opcional)',
                        hintText: 'Tenis: 6-4 3-6 7-5',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _publish, icon: const Icon(Icons.publish), label: const Text('PUBLICAR RESULTADO')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualMatches extends StatelessWidget {
  const _ManualMatches();

  @override
  Widget build(BuildContext context) {
    final list = emergencyStore.manualMatches;
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicados (${list.length})',
            style: TextStyle(fontWeight: FontWeight.w700, color: context.muted),
          ),
          for (final m in list)
            Card(
              margin: const EdgeInsets.only(top: 6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.home.name} ${m.homeScore} - ${m.awayScore} ${m.away.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${m.competition} · ${m.clock}', style: TextStyle(fontSize: 12, color: context.muted)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Editar',
                      onSelected: (v) => switch (v) {
                        'h+' => emergencyStore.updateMatch(m, homeScore: m.homeScore + 1),
                        'a+' => emergencyStore.updateMatch(m, awayScore: m.awayScore + 1),
                        'live' => emergencyStore.updateMatch(m, status: MatchStatus.live, clock: m.clock == 'FINAL' ? "1'" : m.clock),
                        'final' => emergencyStore.updateMatch(m, status: MatchStatus.finished, clock: 'FINAL'),
                        'del' => emergencyStore.removeMatch(m),
                        _ => null,
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'h+', child: Text('+1 ${m.home.short}')),
                        PopupMenuItem(value: 'a+', child: Text('+1 ${m.away.short}')),
                        const PopupMenuItem(value: 'live', child: Text('Marcar EN VIVO')),
                        const PopupMenuItem(value: 'final', child: Text('Marcar FINAL')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'del',
                          child: Text('Eliminar', style: TextStyle(color: AppColors.live)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════ TABLAS ═════════════════════════

class _TableEditor extends StatefulWidget {
  const _TableEditor();

  @override
  State<_TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends State<_TableEditor> {
  League _league = _tableLeagues.first;
  List<StandingRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  void _loadRows() {
    _rows = [...?emergencyStore.tableFor(_league.key)];
  }

  void _copyFromApi() {
    final api = EspnApi.cachedStandings(_league.key);
    if (api == null || api.isEmpty) {
      adminToast(context, 'No hay tabla de la API guardada para ${_league.name}. Ábrela una vez en Resultados o escríbela a mano.');
      return;
    }
    setState(() => _rows = [...api]);
    adminToast(context, 'Se copiaron ${api.length} filas. Edítalas y guarda.');
  }

  Future<void> _editRow([int? index]) async {
    final r = index == null ? null : _rows[index];
    final row = await showDialog<StandingRow>(
      context: context,
      builder: (_) => _RowDialog(row: r, basketball: _league.sport == Sport.basketball),
    );
    if (row == null) return;
    setState(() {
      if (index == null) {
        _rows.add(row);
      } else {
        _rows[index] = row;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = emergencyStore.tables[_league.key];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<League>(
              initialValue: _league,
              decoration: const InputDecoration(labelText: 'Liga', border: OutlineInputBorder(), isDense: true),
              items: [for (final l in _tableLeagues) DropdownMenuItem(value: l, child: Text('${l.flag}  ${l.name}'))],
              onChanged: (l) => setState(() {
                _league = l!;
                _loadRows();
              }),
            ),
            if (saved != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tabla manual publicada por @${saved.author} · ${saved.rows.length} equipos',
                  style: const TextStyle(fontSize: 12, color: AppColors.green),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(onPressed: _copyFromApi, icon: const Icon(Icons.copy_all, size: 18), label: const Text('Copiar de la API')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(onPressed: () => _editRow(), icon: const Icon(Icons.add, size: 18), label: const Text('Agregar fila')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Sin filas. Agrega equipos o copia la tabla de la API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: DefaultTextStyle(
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.muted),
                  child: const Row(
                    children: [
                      Expanded(child: Text('EQUIPO')),
                      SizedBox(width: 28, child: Text('PJ', textAlign: TextAlign.center)),
                      SizedBox(width: 50, child: Text('G-E-P', textAlign: TextAlign.center)),
                      SizedBox(width: 34, child: Text('DG', textAlign: TextAlign.center)),
                      SizedBox(width: 34, child: Text('PTS', textAlign: TextAlign.center)),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < _rows.length; i++)
                InkWell(
                  onTap: () => _editRow(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(_rows[i].name, overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 28, child: Text('${_rows[i].played}', textAlign: TextAlign.center)),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${_rows[i].wins}-${_rows[i].draws}-${_rows[i].losses}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 34, child: Text('${_rows[i].gd}', textAlign: TextAlign.center)),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '${_rows[i].points}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _rows.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _rows.isEmpty
                  ? null
                  : () {
                      emergencyStore.saveTable(_league.key, _rows, appState.user);
                      setState(_loadRows); // queda ordenada por puntos
                      adminToast(context, 'Tabla de ${_league.name} publicada (${_rows.length} equipos)');
                    },
              icon: const Icon(Icons.publish),
              label: const Text('PUBLICAR TABLA'),
            ),
            if (saved != null)
              TextButton(
                onPressed: () {
                  emergencyStore.removeTable(_league.key);
                  setState(_loadRows);
                  adminToast(context, 'Tabla manual retirada: se vuelve a usar la de la API');
                },
                child: const Text('Retirar tabla manual', style: TextStyle(color: AppColors.live)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowDialog extends StatefulWidget {
  final StandingRow? row;
  final bool basketball;
  const _RowDialog({this.row, required this.basketball});

  @override
  State<_RowDialog> createState() => _RowDialogState();
}

class _RowDialogState extends State<_RowDialog> {
  late final _name = TextEditingController(text: widget.row?.name ?? '');
  late final Map<String, TextEditingController> _n = {
    'PJ': TextEditingController(text: '${widget.row?.played ?? 0}'),
    'G': TextEditingController(text: '${widget.row?.wins ?? 0}'),
    'E': TextEditingController(text: '${widget.row?.draws ?? 0}'),
    'P': TextEditingController(text: '${widget.row?.losses ?? 0}'),
    'GF': TextEditingController(text: '${widget.row?.gf ?? 0}'),
    'GC': TextEditingController(text: '${widget.row?.ga ?? 0}'),
    'PTS': TextEditingController(text: '${widget.row?.points ?? 0}'),
  };

  int _v(String k) => int.tryParse(_n[k]!.text) ?? 0;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _n.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.basketball ? {'GF': 'PF', 'GC': 'PC', 'E': 'E'} : const <String, String>{};
    return AlertDialog(
      title: Text(widget.row == null ? 'Nueva fila' : 'Editar fila'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Equipo'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in _n.keys)
                  SizedBox(
                    width: 62,
                    child: TextField(
                      controller: _n[k],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(labelText: labels[k] ?? k, isDense: true, border: const OutlineInputBorder()),
                    ),
                  ),
              ],
            ),
            if (!widget.basketball)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _n['PTS']!.text = '${_v('G') * 3 + _v('E')}'),
                  child: const Text('Calcular puntos (G×3 + E)'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              StandingRow(
                rank: widget.row?.rank ?? 0,
                teamId: widget.row?.teamId ?? 'manual_${name.toLowerCase().hashCode}',
                name: name,
                logo: widget.row?.logo,
                played: _v('PJ'),
                wins: _v('G'),
                draws: _v('E'),
                losses: _v('P'),
                gf: _v('GF'),
                ga: _v('GC'),
                points: _v('PTS'),
                group: widget.row?.group ?? '',
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ═════════════════════════ NOTICIAS ═════════════════════════

class _NewsForm extends StatefulWidget {
  const _NewsForm();

  @override
  State<_NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<_NewsForm> {
  final _formKey = GlobalKey<FormState>();
  Sport _sport = Sport.football;
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _body = TextEditingController();
  final _image = TextEditingController();
  final _link = TextEditingController();

  @override
  void dispose() {
    for (final c in [_title, _summary, _body, _image, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _url(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final u = Uri.tryParse(t);
    return u == null || !u.hasScheme || !t.startsWith('http') ? 'Debe empezar con http:// o https://' : null;
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    emergencyStore.publishNews(
      sport: _sport,
      title: _title.text,
      summary: _summary.text,
      body: _body.text,
      imageUrl: _image.text,
      url: _link.text,
      admin: appState.user,
    );
    for (final c in [_title, _summary, _body, _image, _link]) {
      c.clear();
    }
    adminToast(context, 'Noticia publicada y fijada en Inicio 📌');
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration d(String l, {String? h}) => InputDecoration(labelText: l, hintText: h, border: const OutlineInputBorder(), isDense: true);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Sport>(
                initialValue: _sport,
                decoration: d('Deporte'),
                items: [
                  for (final s in Sport.values)
                    DropdownMenuItem(
                      value: s,
                      child: Row(children: [Icon(s.icon, size: 18), const SizedBox(width: 8), Text(s.label)]),
                    ),
                ],
                onChanged: (s) => setState(() => _sport = s!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                decoration: d('Titular'),
                validator: (v) => (v ?? '').trim().length < 8 ? 'Escribe un titular (mínimo 8 caracteres)' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _summary, decoration: d('Resumen corto')),
              const SizedBox(height: 8),
              TextFormField(controller: _body, maxLines: 4, minLines: 2, decoration: d('Texto completo')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _image,
                validator: _url,
                decoration: d('URL de imagen (opcional)', h: 'https://...'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _link,
                validator: _url,
                decoration: d('Enlace a la nota (opcional)', h: 'https://...'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _publish, icon: const Icon(Icons.campaign), label: const Text('PUBLICAR NOTICIA')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualNewsList extends StatelessWidget {
  const _ManualNewsList();

  @override
  Widget build(BuildContext context) {
    final list = emergencyStore.news;
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicadas (${list.length})',
            style: TextStyle(fontWeight: FontWeight.w700, color: context.muted),
          ),
          for (final n in list)
            Card(
              margin: const EdgeInsets.only(top: 6),
              child: ListTile(
                leading: Icon(n.item.sport.icon, color: n.item.sport.color),
                title: Text(n.item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('por @${n.author}${n.pinned ? ' · fijada' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: n.pinned ? 'Desfijar' : 'Fijar arriba',
                      icon: Icon(n.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                      onPressed: () => emergencyStore.togglePin(n),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline, color: AppColors.live),
                      onPressed: () => emergencyStore.removeNews(n),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
