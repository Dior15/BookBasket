import 'dart:math' as math;
import 'package:flutter/material.dart';

class Shake extends StatefulWidget {
  final Widget child;

  /// Increment this number to trigger a shake every time.
  final int shakeKey;

  final double amplitude; // pixels
  final Duration duration;

  const Shake({
    super.key,
    required this.child,
    required this.shakeKey,
    this.amplitude = 12,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Shake every time the key changes
    if (widget.shakeKey != oldWidget.shakeKey) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // Damped sine wave shake
        final damping = (1 - t);
        final dx = math.sin(t * math.pi * 10) * widget.amplitude * damping;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}