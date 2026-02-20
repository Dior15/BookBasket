import 'package:flutter/material.dart';

/// Smooth route transition used across the app:
/// slide up + fade + slight scale
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) =>
        builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final offsetTween = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      );

      final scaleTween = Tween<double>(begin: 0.985, end: 1.0);

      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: offsetTween.animate(curve),
          child: ScaleTransition(
            scale: scaleTween.animate(curve),
            child: child,
          ),
        ),
      );
    },
  );
}