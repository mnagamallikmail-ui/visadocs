import 'dart:math' as math;
import 'package:flutter/material.dart';

/// BoomerangHeroBackground — Premium animated canvas background using
/// the "boomerang" (ping-pong) playback technique.
///
/// Three [AnimationController]s with `repeat(reverse: true)` drive
/// geometric orbs, grid dots, accent lines, and floating particles
/// on a deep navy gradient. The continuous forward→backward cycle
/// creates a mesmerizing, organic motion — the boomerang effect.
///
/// Designed to fill its parent via [CustomPaint] with [Size.infinite].
/// Wrap in a [SizedBox] or constrained parent.
class BoomerangHeroBackground extends StatefulWidget {
  const BoomerangHeroBackground({super.key});

  @override
  State<BoomerangHeroBackground> createState() =>
      _BoomerangHeroBackgroundState();
}

class _BoomerangHeroBackgroundState extends State<BoomerangHeroBackground>
    with TickerProviderStateMixin {
  late final AnimationController _boomerang;
  late final AnimationController _wave;
  late final AnimationController _glow;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Primary boomerang: drives geometric shapes forward→backward
    _boomerang = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Wave: secondary rhythm for grid elements
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    // Glow: soft pulse for accent orbs
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    // Pre-compute particle positions with fixed seed for consistency
    final rng = math.Random(42);
    _particles = List.generate(
      20,
      (_) => _Particle(
        nx: rng.nextDouble(),
        ny: rng.nextDouble(),
        r: rng.nextDouble() * 2.0 + 0.5,
        speed: rng.nextDouble() * 0.12 + 0.04,
        phase: rng.nextDouble() * math.pi * 2,
        alpha: rng.nextDouble() * 0.3 + 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _boomerang.dispose();
    _wave.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_boomerang, _wave, _glow]),
        builder: (context, _) => CustomPaint(
          painter: _HeroPainter(
            boomerangT: _boomerang.value,
            waveT: _wave.value,
            glowT: _glow.value,
            particles: _particles,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Particle {
  final double nx, ny, r, speed, phase, alpha;
  const _Particle({
    required this.nx,
    required this.ny,
    required this.r,
    required this.speed,
    required this.phase,
    required this.alpha,
  });
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _HeroPainter extends CustomPainter {
  final double boomerangT;
  final double waveT;
  final double glowT;
  final List<_Particle> particles;

  const _HeroPainter({
    required this.boomerangT,
    required this.waveT,
    required this.glowT,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _paintBase(canvas, size);
    _paintOrbs(canvas, size);
    _paintGrid(canvas, size);
    _paintAccentLines(canvas, size);
    _paintParticles(canvas, size);
  }

  /// Deep navy gradient base with subtle hue shift driven by boomerang
  void _paintBase(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final t = boomerangT;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-0.8 + t * 0.3, -1.0),
          end: Alignment(0.8 - t * 0.2, 1.0),
          colors: const [
            Color(0xFF060E1F),
            Color(0xFF0B1A3A),
            Color(0xFF0E2148),
            Color(0xFF070F23),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(rect),
    );
  }

  /// Large, soft radial-gradient orbs that drift with the boomerang animation.
  /// Each orb is a translucent circle with a radial gradient fading to
  /// transparent, creating an atmospheric "glow" effect.
  void _paintOrbs(Canvas canvas, Size size) {
    final maxDim = math.max(size.width, size.height);
    final bt = Curves.easeInOut.transform(boomerangT);
    final gt = Curves.easeInOut.transform(glowT);

    // (baseX, baseY, radius, driftX, driftY, argbHex)
    const orbs = [
      (0.15, 0.25, 0.45, 0.12, 0.08, 0x183730A3), // Deep indigo
      (0.72, 0.45, 0.38, -0.10, 0.12, 0x142563EB), // Brand blue
      (0.45, 0.78, 0.32, 0.08, -0.10, 0x100891B2), // Cyan
      (0.88, 0.12, 0.22, -0.06, 0.06, 0x0C6366F1), // Violet
    ];

    for (final (bx, by, r, dx, dy, hex) in orbs) {
      final cx = (bx + bt * dx) * size.width;
      final cy = (by + gt * dy) * size.height;
      final radius = r * maxDim;
      final color = Color(hex);
      final transparent = Color.fromARGB(0, color.red, color.green, color.blue);

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, transparent],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          ),
      );
    }
  }

  /// Subtle dot grid that drifts with wave animation — digital/blueprint feel
  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..style = PaintingStyle.fill;

    const spacing = 48.0;
    final wt = Curves.easeInOut.transform(waveT);
    final ox = wt * 10.0;
    final oy = wt * 6.0;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x + ox, y + oy), 0.7, paint);
      }
    }
  }

  /// Thin geometric accent lines for architectural depth
  void _paintAccentLines(Canvas canvas, Size size) {
    final bt = Curves.easeInOut.transform(boomerangT);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0x0DFFFFFF);

    // Diagonal accent line 1
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * (0.25 + bt * 0.1)),
      Offset(size.width * 0.35, size.height * (0.08 - bt * 0.04)),
      paint,
    );

    // Diagonal accent line 2
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * (0.82 - bt * 0.1)),
      Offset(size.width * 0.95, size.height * (0.48 + bt * 0.08)),
      paint,
    );

    // Subtle rectangle outlines — abstract architectural shapes
    paint.color = const Color(0x08FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.76,
          size.height * (0.18 + bt * 0.05),
          size.width * 0.14,
          size.height * 0.38,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.04,
          size.height * (0.52 - bt * 0.06),
          size.width * 0.10,
          size.height * 0.30,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  /// Floating particles that drift organically with the boomerang
  void _paintParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final bt = boomerangT;

    for (final p in particles) {
      final drift = math.sin(bt * math.pi * 2 + p.phase) * p.speed;
      final x = (p.nx + drift) * size.width;
      final y = (p.ny + drift * 0.6) * size.height;
      paint.color = Color.fromRGBO(255, 255, 255, p.alpha);
      canvas.drawCircle(Offset(x, y), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.boomerangT != boomerangT ||
      old.waveT != waveT ||
      old.glowT != glowT;
}
