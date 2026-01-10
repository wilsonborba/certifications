import 'package:flutter/material.dart';
import 'dart:math';

class GlowingButton extends StatefulWidget {
  final Icon icon;
  final Text? text; // not used
  final VoidCallback onPressed;

  const GlowingButton({
    super.key,
    required this.icon,
    this.text,
    required this.onPressed,
  });

  @override
  _GlowingButtonState createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _GlowingShadowPainter(animationValue: _controller.value),
              child: SizedBox(width: 190, height: 20),
            );
          },
        ),
        Tooltip(
          message: "Go to next step!",
          verticalOffset: 35,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: widget.onPressed,

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.icon,
                widget.text != null ? SizedBox(width: 10) : SizedBox.shrink(),
                widget.text ?? SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowingShadowPainter extends CustomPainter {
  final double animationValue;

  _GlowingShadowPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..shader =
          SweepGradient(
            colors: [
              const Color(0xFF7EE8D8), // soft mint glow
              const Color(0xFF4DD6B3), // green core
              const Color(0xFF7A7FF2), // blue bridge (VERY important)
              const Color(0xFFB58CFF), // soft purple
              const Color(0xFFD4B6FF), // lavender highlight
            ],
            stops: [0.0, 0.28, 0.55, 0.78, 1.0], // Evenly distribute colors
            transform: GradientRotation(2 * pi * animationValue),
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2,
            ),
          )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40),
        Radius.circular(15),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowingShadowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
