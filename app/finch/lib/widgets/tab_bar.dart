import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/finch_theme.dart';

enum FinchTab { feed, friends, post, you }

class FinchBottomTabBar extends StatelessWidget {
  const FinchBottomTabBar({
    super.key,
    required this.current,
    required this.onTap,
  });

  final FinchTab current;
  final ValueChanged<FinchTab> onTap;

  static const _tabs = <_TabDef>[
    _TabDef(FinchTab.feed, 'Feed'),
    _TabDef(FinchTab.friends, 'Friends'),
    _TabDef(FinchTab.post, 'Post'),
    _TabDef(FinchTab.you, 'You'),
  ];

  IconData _iconFor(FinchTab tab, bool active) {
    switch (tab) {
      case FinchTab.feed:
        return active ? LucideIcons.house : LucideIcons.house;
      case FinchTab.friends:
        return active
            ? LucideIcons.users
            : LucideIcons.users;
      case FinchTab.post:
        return active
            ? LucideIcons.circlePlus
            : LucideIcons.circlePlus;
      case FinchTab.you:
        return active ? LucideIcons.user : LucideIcons.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: finch.colors.paper,
        border: Border(top: BorderSide(color: finch.colors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        10,
        8,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: _TabButton(
                label: tab.label,
                icon: _iconFor(tab.id, tab.id == current),
                active: tab.id == current,
                onTap: () => onTap(tab.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.id, this.label);
  final FinchTab id;
  final String label;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final color = active ? finch.colors.sage : finch.colors.stone;
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 10.5,
                letterSpacing: 0.1,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
