import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The moving colored bubbles of Certifications (Area25: keep the effect,
/// optimize how it is drawn; certifications#52).
///
/// The same soft, additive, slowly changing color blobs as before, drawn
/// more cheaply:
/// - one soft white blob is drawn once into an image with its blur baked
///   in; each frame only places tinted copies of it, so there is no
///   full-screen blur filter on every frame;
/// - a frame repaints the painter only, it does not rebuild widgets;
/// - the movement is updated [maxFps] times a second at most (ambient motion
///   needs no 60 updates), with the same speed in pixels per second;
/// - the ticker stops while the route is hidden (TickerMode) and with
///   reduced motion, which shows one still frame.
class LiquidMetalBackground extends StatefulWidget {
  const LiquidMetalBackground({
    super.key,
    this.blobCount = 12,
    this.minRadius = 80,
    this.maxRadius = 180,
    this.speed = 24, // pixels/second baseline
    this.blurSigma = 20, // Gaussian blur strength, baked into the blob
    this.centerFocusRadius = .45, // kept for callers; the web look has none
    this.maxFps = 30,
    this.seed,
  });

  final int blobCount;
  final double minRadius;
  final double maxRadius;
  final double speed;
  final double blurSigma;
  final double centerFocusRadius;

  /// Movement updates per second at most.
  final int maxFps;

  /// A fixed random seed (tests and measurements); null is random.
  final int? seed;

  @override
  State<LiquidMetalBackground> createState() => _LiquidMetalBackgroundState();
}

class _LiquidMetalBackgroundState extends State<LiquidMetalBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late final math.Random _rng = math.Random(widget.seed);
  final List<_Blob> _blobs = [];
  final _frame = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  Duration _lastPaint = Duration.zero;
  Duration _elapsed = Duration.zero;
  Size _size = Size.zero;
  ui.Image? _sprite;
  double _spriteSigma = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still && _ticker.isActive) {
      _ticker.stop();
    } else if (!still && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _sprite?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_size == Size.zero) return;
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _elapsed = elapsed;
    _step(dt);
    // Repaint at most maxFps times a second.
    final interval = Duration(microseconds: 1000000 ~/ widget.maxFps);
    if (elapsed - _lastPaint >= interval) {
      _lastPaint = elapsed;
      _frame.value++;
    }
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
      // Big blobs drift slower.
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
      // Gentle breathing radius.
      b.radiusPulse =
          1.0 +
          0.05 * math.sin((b.phase + _elapsed.inMilliseconds / 1000.0) * 0.9);
    }
  }

  /// One soft white blob of unit radius [_spriteRadius] with the blur baked
  /// in: a radial falloff, then the Gaussian blur, drawn once.
  static const double _spriteRadius = 128;

  ui.Image _spriteFor(double sigma) {
    if (_sprite != null && _spriteSigma == sigma) return _sprite!;
    _sprite?.dispose();
    // The blur of the old full-screen filter, relative to a blob of the
    // middle radius; the sprite scales with each blob.
    final mid = (widget.minRadius + widget.maxRadius) / 2;
    final s = sigma * _spriteRadius / mid;
    final pad = (s * 3).ceilToDouble();
    final side = (2 * (_spriteRadius + pad)).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(side / 2, side / 2);
    canvas.drawCircle(
      center,
      _spriteRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          _spriteRadius,
          const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          const [0.0, 1.0],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s),
    );
    final picture = recorder.endRecording();
    _sprite = picture.toImageSync(side, side);
    picture.dispose();
    _spriteSigma = sigma;
    return _sprite!;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = c.biggest;
      if (size != Size.zero) {
        _size = size;
        _ensureBlobs(size);
      }
      return RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: _BlobsPainter(
            blobs: _blobs,
            sprite: _spriteFor(widget.blurSigma),
            spriteRadius: _spriteRadius,
            repaint: _frame,
          ),
        ),
      );
    },
  );
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
  double hueOffset = 0.0;
  double radiusPulse = 1.0;
}

/// Places a tinted copy of the soft blob for each bubble, added together
/// (BlendMode.plus) so neighbors merge as before.
class _BlobsPainter extends CustomPainter {
  _BlobsPainter({
    required this.blobs,
    required this.sprite,
    required this.spriteRadius,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_Blob> blobs;
  final ui.Image sprite;
  final double spriteRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || blobs.isEmpty) return;
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final scaleUnit = sprite.width / (2 * spriteRadius);
    for (final b in blobs) {
      final r = b.radius * b.radiusPulse;
      final hue = (b.baseHue + b.hueOffset) % 360;
      final color = HSVColor.fromAHSV(0.85, hue, 0.75, 1.0).toColor();
      final half = r * scaleUnit;
      canvas.drawImageRect(
        sprite,
        src,
        Rect.fromCenter(center: b.position, width: 2 * half, height: 2 * half),
        Paint()
          ..blendMode = BlendMode.plus
          ..filterQuality = FilterQuality.low
          ..colorFilter = ColorFilter.mode(color, BlendMode.modulate),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter old) =>
      old.sprite != sprite || old.blobs != blobs;
}
