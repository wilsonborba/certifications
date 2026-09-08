import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class LiquidMetalBackground extends StatefulWidget {
  const LiquidMetalBackground({
    super.key,
    this.blobCount = 12,
    this.minRadius = 80,
    this.maxRadius = 180,
    this.speed = 24, // pixels/second baseline
    this.blurSigma = 20, // Gaussian blur strength
    this.centerFocusRadius = .45, // 0..1 of min(width,height)
  });

  final int blobCount;
  final double minRadius;
  final double maxRadius;
  final double speed;
  final double blurSigma;
  final double centerFocusRadius;

  @override
  State<LiquidMetalBackground> createState() => _LiquidMetalBackgroundState();
}

class _LiquidMetalBackgroundState extends State<LiquidMetalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();
  final List<_Blob> _blobs = [];

  // Animation timing to compute delta-time physics.
  late DateTime _lastTick;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    // Use a normal controller and repeat over finite range (0..1)
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_onFrame);
    _ctrl.repeat(); // no min/max -> safe finite values
    _lastTick = DateTime.now();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onFrame);
    _ctrl.dispose();
    super.dispose();
  }

  void _onFrame() {
    if (_size == Size.zero) return;
    final now = DateTime.now();
    final dt = (now.difference(_lastTick).inMicroseconds / 1e6).clamp(
      0.0,
      0.05,
    );
    _lastTick = now;
    _step(dt);
    setState(() {});
  }

  void _ensureBlobs(Size size) {
    if (_blobs.isNotEmpty || size.isEmpty) return;
    for (var i = 0; i < widget.blobCount; i++) {
      final r =
          _rng.nextDouble() * (widget.maxRadius - widget.minRadius) +
          widget.minRadius;

      final pos = Offset(
        _rng.nextDouble() * math.max(1, size.width),
        _rng.nextDouble() * math.max(1, size.height),
      );

      // Random direction, normalized; speed scaled a bit by radius so big blobs drift slower.
      final theta = _rng.nextDouble() * math.pi * 2;
      final baseSpeed = widget.speed * (0.7 + 0.6 * _rng.nextDouble());
      final vel =
          Offset(math.cos(theta), math.sin(theta)) *
          (baseSpeed * (120 / (r + 40)));

      final hue = _rng.nextDouble() * 360.0;
      final hueSpeed =
          (_rng.nextDouble() * 24 + 10) * (_rng.nextBool() ? 1 : -1);

      _blobs.add(
        _Blob(
          position: pos,
          velocity: vel,
          radius: r,
          baseHue: hue,
          hueSpeed: hueSpeed,
          phase: _rng.nextDouble() * 1000,
        ),
      );
    }
  }

  void _step(double dt) {
    for (final b in _blobs) {
      var p = b.position + b.velocity * dt;

      // Bounce at edges
      if (p.dx - b.radius < 0) {
        p = Offset(b.radius, p.dy);
        b.velocity = Offset(b.velocity.dx.abs(), b.velocity.dy);
      } else if (p.dx + b.radius > _size.width) {
        p = Offset(_size.width - b.radius, p.dy);
        b.velocity = Offset(-b.velocity.dx.abs(), b.velocity.dy);
      }
      if (p.dy - b.radius < 0) {
        p = Offset(p.dx, b.radius);
        b.velocity = Offset(b.velocity.dx, b.velocity.dy.abs());
      } else if (p.dy + b.radius > _size.height) {
        p = Offset(p.dx, _size.height - b.radius);
        b.velocity = Offset(b.velocity.dx, -b.velocity.dy.abs());
      }
      b.position = p;
      b.hueOffset += b.hueSpeed * dt;

      // Gentle breathing radius to feel liquid
      b.radiusPulse =
          1.0 +
          0.05 *
              math.sin(
                (b.phase +
                        (_ctrl.lastElapsedDuration ?? Duration.zero)
                                .inMilliseconds /
                            1000.0) *
                    0.9,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        if (size != Size.zero) {
          _size = size;
          _ensureBlobs(size);
        }

        // One painter instance reused for both passes (same blob state).
        final painter = _BlobsPainter(blobs: _blobs);

        if (kIsWeb) {
          return RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: CustomPaint(
                painter: painter,
                isComplex: true,
                willChange: true,
              ),
            ),
          );
        }

        return RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Pass 1: soft & dreamy (heavily blurred)
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: widget.blurSigma,
                  sigmaY: widget.blurSigma,
                ),
                child: CustomPaint(
                  painter: painter,
                  isComplex: true,
                  willChange: true,
                ),
              ),

              // Pass 2: crisp center reveal (keeps foreground readable).
              ShaderMask(
                shaderCallback: (rect) {
                  final radius =
                      widget.centerFocusRadius *
                      math.min(rect.width, rect.height);
                  return RadialGradient(
                    center: Alignment.center,
                    radius: (radius / (math.min(rect.width, rect.height)))
                        .clamp(0.0, 0.95),
                    colors: const [Colors.white, Colors.transparent],
                    stops: const [0.0, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: painter,
                  isComplex: true,
                  willChange: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Blob {
  _Blob({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.baseHue,
    required this.hueSpeed,
    required this.phase,
  });

  Offset position;
  Offset velocity;
  double radius;
  final double baseHue;
  final double hueSpeed;
  final double phase;

  // animated modifiers
  double hueOffset = 0.0;
  double radiusPulse = 1.0;
}

/// Draws additive, radial-gradient blobs (Gaussian-ish falloff).
class _BlobsPainter extends CustomPainter {
  _BlobsPainter({required this.blobs});

  final List<_Blob> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || blobs.isEmpty) return;

    // Use additive blending so separate blobs “merge” smoothly (metaball feel).
    final paint = Paint()..blendMode = BlendMode.plus;

    for (final b in blobs) {
      final r = b.radius * b.radiusPulse;

      // Smooth, colorful fill built in HSV then converted to RGB.
      final hue = (b.baseHue + b.hueOffset) % 360;
      final col = HSVColor.fromAHSV(0.85, hue, 0.75, 1.0).toColor();

      // Radial falloff → soft “energy” field
      paint.shader = ui.Gradient.radial(
        b.position,
        r,
        [col, col.withValues(alpha: 0.0)],
        const [0.0, 1.0],
      );

      canvas.drawCircle(b.position, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter oldDelegate) => true;
}
