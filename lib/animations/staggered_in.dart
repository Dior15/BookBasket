import 'package:flutter/material.dart';

/// Simple “staggered entrance” for list/grid items.
/// Use: StaggeredIn(index: i, child: ...)
class StaggeredIn extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredIn({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  Widget build(BuildContext context) {
    final delay = baseDelay * index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        final effective = (t - (delay.inMilliseconds / 900)).clamp(0.0, 1.0);
        final dy = (1 - effective) * 10;

        return Opacity(
          opacity: effective,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: 0.98 + (0.02 * effective),
              child: child,
            ),
          ),
        );
      },
    );
  }
}