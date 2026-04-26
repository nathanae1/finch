import 'package:flutter/animation.dart';

class FinchMotion {
  const FinchMotion();

  final Curve ease = const Cubic(0.25, 0.1, 0.25, 1);
  final Duration fast = const Duration(milliseconds: 150);
  final Duration standard = const Duration(milliseconds: 250);
  final Duration slow = const Duration(milliseconds: 400);
}
