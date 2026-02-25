import 'dart:math' as math;
import 'package:flutter/material.dart';

class PageFlipView extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ValueChanged<int>? onPageChanged;

  const PageFlipView({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PageView.builder(
          controller: controller,
          clipBehavior: Clip.none, // Prevents clipping of the outward swinging page
          itemCount: itemCount,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                double pageValue = currentPage.toDouble();
                if (controller.hasClients && controller.position.haveDimensions) {
                  pageValue = controller.page!;
                }

                double delta = (index - pageValue);

                if (delta <= -1.0 || delta >= 1.0) return const SizedBox.shrink();

                if (delta < 0) {
                  // We explicitly render the NEXT page underneath the current folding page
                  final double translationX = -delta * constraints.maxWidth;

                  return Transform(
                    transform: Matrix4.identity()..translate(translationX),
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        // 1. The Next Page (Laying flat beneath the turning page)
                        if (index + 1 < itemCount)
                          itemBuilder(context, index + 1),

                        // 2. The Current Page (Lifting and folding right-to-left)
                        Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0003) // Preserves proper 3D perspective
                            ..rotateY(-delta * math.pi), // 180 deg fold off the left screen
                          alignment: Alignment.centerLeft, // Locked to the left spine
                          child: itemBuilder(context, index),
                        ),
                      ],
                    ),
                  );
                } else if (delta > 0) {
                  // Hide the default top-level next page since we manually rendered it above
                  return const SizedBox.shrink();
                } else {
                  // Delta is exactly 0 (Stationary)
                  return itemBuilder(context, index);
                }
              },
            );
          },
        );
      },
    );
  }
}