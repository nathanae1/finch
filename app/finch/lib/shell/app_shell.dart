import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/finch_theme.dart';
import '../widgets/tab_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // The shell has three branches (feed, friends, you); "post" is modal.
  static const _branchToTab = [FinchTab.feed, FinchTab.friends, FinchTab.you];
  static const _tabToBranch = {
    FinchTab.feed: 0,
    FinchTab.friends: 1,
    FinchTab.you: 2,
  };

  FinchTab get _current => _branchToTab[navigationShell.currentIndex];

  void _onTap(BuildContext context, FinchTab tab) {
    if (tab == FinchTab.post) {
      // "Post" is a modal action, not a tab. Push compose over whichever tab
      // the user was on; do not change the active tab index.
      context.push('/compose');
      return;
    }
    final targetIndex = _tabToBranch[tab]!;
    navigationShell.goBranch(
      targetIndex,
      initialLocation: targetIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: navigationShell,
      bottomNavigationBar: FinchBottomTabBar(
        current: _current,
        onTap: (t) => _onTap(context, t),
      ),
    );
  }
}
