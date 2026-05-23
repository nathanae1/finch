import 'package:flutter/material.dart';

import '../theme/starling_theme.dart';

class StarlingTopBar extends StatelessWidget {
  const StarlingTopBar({
    super.key,
    this.title,
    this.left,
    this.right,
    this.subtitle,
    this.big = false,
  });

  final String? title;
  final Widget? left;
  final Widget? right;
  final String? subtitle;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final starling = StarlingTheme.of(context);
    final titleStyle = (big ? starling.typography.h1 : starling.typography.h2)
        .copyWith(fontWeight: FontWeight.w500);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        left ?? const SizedBox(width: 36),
        Expanded(
          child: title == null
              ? const SizedBox.shrink()
              : Text(
                  title!,
                  textAlign: (left == null && right == null)
                      ? TextAlign.center
                      : TextAlign.left,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        right ?? const SizedBox(width: 36),
      ],
    );

    return Container(
      color: starling.colors.paper,
      padding: EdgeInsets.fromLTRB(20, 12, 20, subtitle != null ? 8 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          row,
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(subtitle!, style: starling.typography.small),
            ),
          ],
        ],
      ),
    );
  }
}
