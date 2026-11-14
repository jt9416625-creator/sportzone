import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_theme.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';
import '../../widgets/sticker_card.dart';

/// Abrir sobre: se rasga y las 5 láminas se voltean una por una.
/// Devuelve (al cerrar) la página del álbum de la última lámina nueva.
class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({super.key});

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

enum _Phase { sealed, tearing, reveal }

class _PackOpeningScreenState extends State<PackOpeningScreen> {
  _Phase _phase = _Phase.sealed;
  PackResult? _result;
  int _revealed = 0;
  Timer? _timer;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _open() {
    if (_phase != _Phase.sealed || album.state.packs <= 0) return;
    HapticFeedback.heavyImpact();
    final r = album.openPack();
    setState(() {
      _result = r;
      _phase = _Phase.tearing;
      _revealed = 0;
    });
    _timer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.reveal);
      _timer = Timer.periodic(const Duration(milliseconds: 550), (t) {
        if (!mounted) return;
        if (_revealed >= r.stickers.length) {
          t.cancel();
          _afterReveal(r);
          return;
        }
        final st = r.stickers[_revealed];
        if (st.rarity == StickerRarity.epic || st.rarity == StickerRarity.legendary) {
          HapticFeedback.heavyImpact();
          _confetti.play();
        } else {
          HapticFeedback.selectionClick();
        }
        setState(() => _revealed++);
      });
    });
  }

  void _afterReveal(PackResult r) {
    for (final msg in r.rewards) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
    }
  }

  void _again() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.sealed;
      _result = null;
      _revealed = 0;
    });
  }

  int? get _targetPage {
    final r = _result;
    if (r == null) return null;
    for (var i = r.stickers.length - 1; i >= 0; i--) {
      if (r.isNew[i]) return r.stickers[i].page;
    }
    return r.stickers.isEmpty ? null : r.stickers.last.page;
  }

  @override
  Widget build(BuildContext context) {
    final packs = album.state.packs;
    final done = _result != null && _revealed >= _result!.stickers.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('SOBRES: $packs', style: display(22, color: Colors.white)),
        leading: BackButton(onPressed: () => Navigator.pop(context, _targetPage)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: SzWatermark(opacity: 0.04, fontSize: 30)),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [AppColors.green, AppColors.gold, Color(0xFF7B2FF7), Colors.white],
            ),
          ),
          Center(
            child: switch (_phase) {
              _Phase.sealed => _sealed(packs),
              _Phase.tearing => const PackArt(width: 210)
                  .animate()
                  .shake(hz: 6, duration: 350.ms)
                  .then()
                  .scaleXY(end: 1.25, duration: 250.ms)
                  .fadeOut(duration: 250.ms),
              _Phase.reveal => _cards(),
            },
          ),
          if (done)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, _targetPage),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.all(14)),
                      child: const Text('VER EN EL ÁLBUM'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: packs > 0 ? _again : null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.bg, padding: const EdgeInsets.all(14)),
                      child: Text(packs > 0 ? 'ABRIR OTRO ($packs)' : 'SIN SOBRES', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _sealed(int packs) {
    if (packs <= 0) {
      return const Text('No tienes sobres.\nCompleta misiones para ganar más.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16));
    }
    return GestureDetector(
      onTap: _open,
      onVerticalDragEnd: (_) => _open(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PackArt(width: 210)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(height: 26),
          const Text('Toca el sobre para abrirlo', style: TextStyle(color: Colors.white70, fontSize: 16))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 1, duration: 900.ms),
        ],
      ),
    );
  }

  Widget _cards() {
    final r = _result!;
    final w = math.min(118.0, (MediaQuery.sizeOf(context).width - 60) / 3);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 14,
        children: [
          for (var i = 0; i < r.stickers.length; i++)
            SizedBox(
              width: w,
              child: Column(children: [
                _FlipCard(
                  flipped: i < _revealed,
                  back: _back(),
                  front: StickerCard(sticker: r.stickers[i], owned: true),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  opacity: i < _revealed ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.isNew[i] ? AppColors.green : Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.isNew[i] ? 'NUEVA · ${r.stickers[i].rarity.label}' : 'REPETIDA',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: r.isNew[i] ? AppColors.bg : Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _back() => AspectRatio(
        aspectRatio: StickerCard.ratio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: [Color(0xFF1E2A3A), Color(0xFF0B0E14)]),
            border: Border.all(color: AppColors.green, width: 2),
          ),
          child: Stack(children: [
            const Positioned.fill(child: SzWatermark(opacity: 0.1, fontSize: 9)),
            Center(child: Text('SZ', style: display(34, color: AppColors.green))),
          ]),
        ),
      );
}

/// Carta que gira en 3D (eje Y) de reverso a frente.
class _FlipCard extends StatelessWidget {
  final bool flipped;
  final Widget front, back;
  const _FlipCard({required this.flipped, required this.front, required this.back});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: flipped ? math.pi : 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      builder: (context, a, _) {
        final showFront = a > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(a),
          child: showFront ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: front) : back,
        );
      },
    );
  }
}
