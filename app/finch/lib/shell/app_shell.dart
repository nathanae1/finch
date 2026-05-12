import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sync_provider.dart';
import '../theme/finch_theme.dart';
import '../widgets/tab_bar.dart';

class AppShell extends ConsumerWidget {
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

  Future<void> _kickSync(WidgetRef ref) async {
    try {
      await ref.read(syncControllerProvider.notifier).syncNow();
    } catch (_) {
      // Errors are surfaced through syncStatusProvider.
    }
  }

  void _onTap(BuildContext context, WidgetRef ref, FinchTab tab) {
    if (tab == FinchTab.post) {
      // "Post" is a modal action, not a tab. Push compose over whichever tab
      // the user was on; do not change the active tab index.
      context.push('/compose');
      return;
    }
    if (tab == FinchTab.feed) {
      // Tapping Feed always kicks a pull. syncNow() coalesces concurrent
      // calls so rapid taps are safe; errors surface via syncStatusProvider.
      unawaited(_kickSync(ref));
    }
    final targetIndex = _tabToBranch[tab]!;
    navigationShell.goBranch(
      targetIndex,
      initialLocation: targetIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: navigationShell,
      bottomNavigationBar: FinchBottomTabBar(
        current: _current,
        onTap: (t) => _onTap(context, ref, t),
      ),
    );
  }
}
