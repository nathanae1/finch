import 'package:flutter/widgets.dart';

class FinchIcon extends StatelessWidget {
  const FinchIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
