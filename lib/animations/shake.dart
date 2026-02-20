import 'package:flutter/material.dart';

/// Shake animation for “wrong password”, etc.
class Shake extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final double distance;

  const Shake({
    super.key,
    required this.child,
    required this.trigger,
    this.distance = 10,
  });

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  bool _lastTrigger = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _a = CurvedAnimation(parent: _c, curve: Curves.elasticIn).drive(
      Tween(begin: 0.0, end: 1.0),
    );
  }

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_lastTrigger) {
      _c.forward(from: 0);
    }
    _lastTrigger = widget.trigger;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) {
        final t = _a.value;
        final dx = (1 - t) * widget.distance * (t < 0.5 ? -1 : 1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}