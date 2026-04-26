import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/search_provider.dart';
import '../../providers/sync_status_provider.dart';
import '../../theme/finch_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/finch_icon.dart';
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
    final finch = FinchTheme.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: finch.colors.paper,
        border: Border(bottom: BorderSide(color: finch.colors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _searching ? _buildSearchRow(finch) : _buildSyncRow(finch),
    );
  }

  Widget _buildSyncRow(FinchTheme finch) {
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
            style: finch.typography.small.copyWith(color: finch.colors.graphite),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        FinchIconButton(
          onPressed: _enterSearch,
          child: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
        ),
      ],
    );
  }

  Widget _buildSearchRow(FinchTheme finch) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FinchIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 18,
            color: finch.colors.graphite,
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
                  finch.typography.small.copyWith(color: finch.colors.stone),
            ),
            style: finch.typography.body,
            cursorColor: finch.colors.sage,
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
