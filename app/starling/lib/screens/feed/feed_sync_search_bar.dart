import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/search_provider.dart';
import '../../providers/sync_status_provider.dart';
import '../../theme/starling_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/starling_icon.dart';
import '../../widgets/sync_dot.dart';

/// Single-row top-of-feed widget. Two modes:
///   - default: SyncDot + status text + magnifier
///   - search: magnifier + autofocused TextField + Cancel
class FeedSyncSearchBar extends ConsumerStatefulWidget {
  const FeedSyncSearchBar({super.key});

  @override
  ConsumerState<FeedSyncSearchBar> createState() => _FeedSyncSearchBarState();
}

class _FeedSyncSearchBarState extends ConsumerState<FeedSyncSearchBar> {
  bool _searching = false;
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _enterSearch() {
    setState(() => _searching = true);
    // Autofocus on next frame so the TextField is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _exitSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() => _searching = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final starling = StarlingTheme.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: starling.colors.paper,
        border: Border(bottom: BorderSide(color: starling.colors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _searching ? _buildSearchRow(starling) : _buildSyncRow(starling),
    );
  }

  Widget _buildSyncRow(StarlingTheme starling) {
    final status = ref.watch(syncStatusProvider);
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SyncDot(state: status.state),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _statusLabel(status),
            style: starling.typography.small.copyWith(color: starling.colors.graphite),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        StarlingIconButton(
          onPressed: _enterSearch,
          child: const Icon(LucideIcons.search, size: 18),
        ),
      ],
    );
  }

  Widget _buildSearchRow(StarlingTheme starling) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: StarlingIcon(
            LucideIcons.search,
            size: 18,
            color: starling.colors.graphite,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).set(value),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Search posts and friends',
              hintStyle:
                  starling.typography.small.copyWith(color: starling.colors.stone),
            ),
            style: starling.typography.body,
            cursorColor: starling.colors.sage,
          ),
        ),
        GhostButton(label: 'Cancel', onPressed: _exitSearch),
      ],
    );
  }

  String _statusLabel(SyncStatus status) {
    switch (status.state) {
      case SyncState.synced:
        if (status.lastSyncedAtSeconds == null) {
          return status.reachableFriends > 0
              ? '${status.reachableFriends} friends reachable'
              : 'Up to date';
        }
        return 'Last synced just now';
      case SyncState.syncing:
        return 'Syncing…';
      case SyncState.waiting:
        final name = status.waitingForName ?? 'a friend';
        return "Waiting for $name's device…";
      case SyncState.offline:
        return 'Offline — posts will sync when online.';
    }
  }
}
