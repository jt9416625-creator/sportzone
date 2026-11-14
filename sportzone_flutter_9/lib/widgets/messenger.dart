import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_models.dart';

/// Colores del Messenger clásico (2015): barra azul, fondo blanco,
/// burbujas azules para mí y grises para la otra persona.
class Mx {
  static const primary = Color(0xFF0084FF);
  static const bubbleOther = Color(0xFFF1F0F0);
  static const textOther = Color(0xFF141823);
  static const meta = Color(0xFF9197A3);
  static const background = Colors.white;
  static const divider = Color(0xFFE5E5EA);
  static const online = Color(0xFF42B72A);
}

/// Tema propio para que el chat se vea igual en modo claro y oscuro.
ThemeData messengerTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Mx.background,
    colorScheme: ColorScheme.fromSeed(seedColor: Mx.primary, brightness: Brightness.light).copyWith(primary: Mx.primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: Mx.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: base.textTheme.apply(bodyColor: Mx.textOther, displayColor: Mx.textOther),
  );
}

/// Círculo azul con audífonos: la "foto" de Soporte.
class SupportAvatar extends StatelessWidget {
  final double size;
  const SupportAvatar({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF00C6FF), Mx.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(Icons.headset_mic, size: size * 0.56, color: Colors.white),
    );
  }
}

/// Encabezado del chat: foto, nombre y "Activo ahora".
class MessengerTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget avatar;
  final bool online;
  const MessengerTitle({super.key, required this.title, required this.subtitle, required this.avatar, this.online = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            avatar,
            if (online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(color: Mx.online, shape: BoxShape.circle, border: Border.all(color: Mx.primary, width: 2)),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lista de mensajes con ListView.builder.
/// [viewerIsSupport] = true cuando la ve un admin (sus mensajes van a la derecha).
class MessengerList extends StatefulWidget {
  final List<TicketMessage> messages;
  final bool viewerIsSupport;
  final bool typing;
  final DateTime? seenAt; // la otra persona vio hasta aquí
  final Widget otherAvatar;
  final Widget? header;

  const MessengerList({
    super.key,
    required this.messages,
    required this.viewerIsSupport,
    required this.otherAvatar,
    this.typing = false,
    this.seenAt,
    this.header,
  });

  @override
  State<MessengerList> createState() => _MessengerListState();
}

class _MessengerListState extends State<MessengerList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _toBottom(jump: true);
  }

  @override
  void didUpdateWidget(covariant MessengerList old) {
    super.didUpdateWidget(old);
    if (old.messages.length != widget.messages.length || old.typing != widget.typing) _toBottom();
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(max, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _mine(TicketMessage m) => m.fromSupport == widget.viewerIsSupport;

  @override
  Widget build(BuildContext context) {
    final msgs = widget.messages;
    final extra = (widget.header != null ? 1 : 0);
    final count = msgs.length + extra + (widget.typing ? 1 : 0);

    // Último mensaje mío: ahí va el "Enviado" / "Visto".
    final lastMine = msgs.lastIndexWhere(_mine);

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      itemCount: count,
      itemBuilder: (context, index) {
        if (widget.header != null && index == 0) return widget.header!;
        final i = index - extra;
        if (i >= msgs.length) {
          return _Row(mine: false, avatar: widget.otherAvatar, child: const _TypingBubble());
        }
        final m = msgs[i];
        final mine = _mine(m);
        final prev = i > 0 ? msgs[i - 1] : null;
        final next = i < msgs.length - 1 ? msgs[i + 1] : null;
        final newBlock = prev == null || m.time.difference(prev.time).inMinutes >= 10;
        final firstOfGroup = newBlock || _mine(prev) != mine || prev.author != m.author;
        final nextNewBlock = next == null || next.time.difference(m.time).inMinutes >= 10;
        final lastOfGroup = nextNewBlock || _mine(next) != mine || next.author != m.author;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (newBlock) _TimeDivider(time: m.time),
            if (!mine && firstOfGroup)
              Padding(
                padding: const EdgeInsets.only(left: 46, bottom: 2, top: 4),
                child: Text(m.author, style: const TextStyle(fontSize: 11.5, color: Mx.meta)),
              ),
            _Row(
              mine: mine,
              avatar: !mine && lastOfGroup ? widget.otherAvatar : null,
              child: _Bubble(text: m.text, mine: mine, first: firstOfGroup, last: lastOfGroup),
            ),
            if (i == lastMine && mine)
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.seenAt != null && !widget.seenAt!.isBefore(m.time)
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Visto ', style: TextStyle(fontSize: 11, color: Mx.meta)),
                          SizedBox(width: 14, height: 14, child: FittedBox(child: widget.otherAvatar)),
                        ])
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Enviado ', style: TextStyle(fontSize: 11, color: Mx.meta)),
                          Icon(Icons.check_circle_outline, size: 14, color: Mx.primary),
                        ]),
                ),
              ),
            SizedBox(height: lastOfGroup ? 8 : 2),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final bool mine;
  final Widget? avatar;
  final Widget child;
  const _Row({required this.mine, required this.child, this.avatar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          SizedBox(width: 30, height: 30, child: avatar),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Burbuja con las esquinas "pegadas" cuando hay varios mensajes seguidos.
class _Bubble extends StatelessWidget {
  final String text;
  final bool mine, first, last;
  const _Bubble({required this.text, required this.mine, required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    const big = Radius.circular(18);
    const small = Radius.circular(5);
    final onlyEmoji = text.runes.length <= 3 && !RegExp(r'[A-Za-z0-9]').hasMatch(text);
    if (onlyEmoji) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text, style: const TextStyle(fontSize: 38)),
      ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
      decoration: BoxDecoration(
        color: mine ? Mx.primary : Mx.bubbleOther,
        borderRadius: BorderRadius.only(
          topLeft: mine || first ? big : small,
          bottomLeft: mine || last ? big : small,
          topRight: !mine || first ? big : small,
          bottomRight: !mine || last ? big : small,
        ),
      ),
      child: Text(text, style: TextStyle(fontSize: 15, height: 1.3, color: mine ? Colors.white : Mx.textOther)),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.15, end: 0, duration: 180.ms);
  }
}

class _TimeDivider extends StatelessWidget {
  final DateTime time;
  const _TimeDivider({required this.time});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    const days = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    final sameDay = time.year == now.year && time.month == now.month && time.day == now.day;
    final label = sameDay ? 'HOY $hm' : '${days[time.weekday - 1]} ${time.day}/${time.month} $hm';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Mx.meta, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

/// "Escribiendo..." con los tres puntitos.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Mx.bubbleOther, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: Mx.meta, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 160).ms).fade(begin: 0.25, end: 1, duration: 420.ms),
        ],
      ),
    );
  }
}

/// Barra para escribir: si está vacía muestra el 👍 (como el Messenger de antes).
class MessengerComposer extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool enabled;
  final String hint;
  final List<String> quickReplies;

  const MessengerComposer({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hint = 'Escribe un mensaje...',
    this.quickReplies = const [],
  });

  @override
  State<MessengerComposer> createState() => _MessengerComposerState();
}

class _MessengerComposerState extends State<MessengerComposer> {
  final _c = TextEditingController();
  bool _hasText = false;

  void _send([String? forced]) {
    final t = (forced ?? _c.text).trim();
    if (t.isEmpty || !widget.enabled) return;
    widget.onSend(t);
    _c.clear();
    setState(() => _hasText = false);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.quickReplies.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  children: [
                    for (final q in widget.quickReplies)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: widget.enabled ? () => _send(q) : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Mx.primary,
                            side: const BorderSide(color: Mx.primary),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(q, style: const TextStyle(fontSize: 12.5)),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Mx.divider))),
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: Row(
                children: [
                  const IconButton(onPressed: null, icon: Icon(Icons.add_circle, color: Mx.primary), disabledColor: Mx.primary),
                  Expanded(
                    child: TextField(
                      controller: _c,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      // Enter envía (como Messenger). El texto largo igual hace salto automático.
                      textInputAction: TextInputAction.send,
                      onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: Mx.textOther, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: widget.enabled ? widget.hint : 'No puedes escribir en este chat',
                        hintStyle: const TextStyle(color: Mx.meta),
                        filled: true,
                        fillColor: const Color(0xFFF1F0F0),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _hasText ? 'Enviar' : 'Me gusta',
                    onPressed: widget.enabled ? () => _hasText ? _send() : _send('👍') : null,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(_hasText ? Icons.send : Icons.thumb_up, key: ValueKey(_hasText), color: Mx.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
