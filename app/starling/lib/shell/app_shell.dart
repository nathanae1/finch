import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sync_provider.dart';
import '../theme/starling_theme.dart';
import '../widgets/tab_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // The shell has three branches (feed, friends, you); "post" is modal.
  static const _branchToTab = [StarlingTab.feed, StarlingTab.friends, StarlingTab.you];
  static const _tabToBranch = {
    StarlingTab.feed: 0,
    StarlingTab.friends: 1,
    StarlingTab.you: 2,
  };

  StarlingTab get _current => _branchToTab[navigationShell.currentIndex];

  Future<void> _kickSync(WidgetRef ref) async {
    try {
      await ref.read(syncControllerProvider.notifier).syncNow();
    } catch (_) {
      // Errors are surfaced through syncStatusProvider.
    }
  }

  void _onTap(BuildContext context, WidgetRef ref, StarlingTab tab) {
    if (tab == StarlingTab.post) {
      // "Post" is a modal action, not a tab. Push compose over whichever tab
      // the user was on; do not change the active tab index.
      context.push('/compose');
      return;
    }
    if (tab == StarlingTab.feed) {
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
    final starling = StarlingTheme.of(context);
    return Scaffold(
      backgroundColor: starling.colors.paper,
      body: navigationShell,
      bottomNavigationBar: StarlingBottomTabBar(
        current: _current,
        onTap: (t) => _onTap(context, ref, t),
      ),
    );
  }
}
