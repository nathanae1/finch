import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum FinchIconWeight { regular, bold, fill, light, thin, duotone }

class FinchIcon extends StatelessWidget {
  const FinchIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.weight = FinchIconWeight.regular,
  });

  final PhosphorIconData icon;
  final double size;
  final Color? color;
  final FinchIconWeight weight;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
