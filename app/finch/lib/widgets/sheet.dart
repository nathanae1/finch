import 'package:flutter/material.dart';

import '../theme/finch_theme.dart';

Future<T?> showFinchSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  final finch = FinchTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: finch.colors.shadowInk.withValues(alpha: 0.35),
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 280),
    ),
    builder: (ctx) => FinchSheet(child: Builder(builder: builder)),
  );
}

class FinchSheet extends StatelessWidget {
  const FinchSheet({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.85,
  });

  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(top: media.padding.top),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: media.size.height * maxHeightFactor,
        ),
        decoration: BoxDecoration(
          color: finch.colors.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: finch.colors.shadowInk.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              decoration: BoxDecoration(
                color: finch.colors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: SingleChildScrollView(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
