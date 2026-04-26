import 'package:flutter/animation.dart';

class FinchMotion {
  const FinchMotion();

  final Curve ease = const Cubic(0.25, 0.1, 0.25, 1);
  final Duration fast = const Duration(milliseconds: 150);
  final Duration standard = const Duration(milliseconds: 250);
  final Duration slow = const Duration(milliseconds: 400);

  /// One-shot scale beat used by the heart on tap (Plan 10).
  /// Scale 1 → 1.25 → 1 with [Curves.elasticOut] tail; warm but not bouncy.
  final Duration heartPop = const Duration(milliseconds: 320);
}
