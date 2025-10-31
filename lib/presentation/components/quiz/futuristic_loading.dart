import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FuturisticLoading extends StatefulWidget {
  final List<String> messages;
  final bool isActive;
  final Duration switchInterval;
  final String? imageAsset; // optional logo

  const FuturisticLoading({
    super.key,
    required this.messages,
    this.isActive = true,
    this.switchInterval = const Duration(seconds: 4),
    this.imageAsset,
  });

  @override
  State<FuturisticLoading> createState() => _FuturisticLoadingState();
}

class _FuturisticLoadingState extends State<FuturisticLoading>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.switchInterval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.messages.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant FuturisticLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && _timer == null) _startTicker();
    if (!widget.isActive) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEDF1F7),
            Color(0xFFF9FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional: logo or animation
            if (widget.imageAsset != null) ...[
              Image.asset(widget.imageAsset!, height: 80, fit: BoxFit.contain),
              const SizedBox(height: 32),
            ],

            // Apple-style glow ring loader
            const _SoftPulseLoader(),

            const SizedBox(height: 40),

            // Animated message switcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              child: Text(
                widget.messages[_index],
                key: ValueKey(widget.messages[_index]),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPulseLoader extends StatefulWidget {
  const _SoftPulseLoader();

  @override
  State<_SoftPulseLoader> createState() => _SoftPulseLoaderState();
}

class _SoftPulseLoaderState extends State<_SoftPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final size = 80 + (_ctrl.value * 20);
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withAlpha(((0.2 + 0.3 * _ctrl.value) * 255).toInt()),
                blurRadius: 30 + 30 * _ctrl.value,
                spreadRadius: 4,
              ),
            ],
            gradient: RadialGradient(
              colors: [
                Colors.deepPurple.shade200.withAlpha(((0.7) * 255).toInt()),
                Colors.deepPurple.shade400,
              ],
            ),
          ),
        );
      },
    );
  }
}
