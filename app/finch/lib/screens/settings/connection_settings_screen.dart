import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/follow_profile_provider.dart';
import '../../providers/follows_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/sync_provider.dart';
import '../../services/types.dart';
import '../../sync/peer_reachability_monitor.dart';
import '../../sync/peer_reachability_provider.dart';
import '../../theme/finch_theme.dart';
import '../../utils/finch_address.dart';
import '../../widgets/buttons.dart';

/// Surfaces the per-peer reachability state maintained by
/// [PeerReachabilityMonitor]. Used for connection troubleshooting:
/// shows LAN/Tor status, last error, last-change timestamp, and the
/// validated endpoint when reachable. The user can force a re-probe.
class ConnectionSettingsScreen extends ConsumerWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final followsAsync = ref.watch(followsStreamProvider);
    final stateAsync = ref.watch(peerReachabilityStateProvider);

    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: followsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(message: '$e'),
                data: (follows) {
                  if (follows.isEmpty) {
                    return const _EmptyView();
                  }
                  final state = stateAsync.maybeWhen(
                    data: (s) => s,
                    orElse: () =>
                        const <String, PeerReachability>{},
                  );
                  return RefreshIndicator(
                    onRefresh: () => _refreshAll(ref, follows),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: follows.length,
                      itemBuilder: (_, i) {
                        final follow = follows[i];
                        return _PeerTile(
                          follow: follow,
                          reachability: state[follow.pubkey],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: finch.colors.hairline)),
      ),
      child: Row(
        children: [
          FinchIconButton(
            onPressed: () => context.pop(),
            child: const Icon(LucideIcons.arrowLeft, size: 20),
          ),
          Expanded(
            child: Text(
              'Connection',
              style: finch.typography.h3.copyWith(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FinchIconButton(
            onPressed: () async {
              final follows = await ref.read(storageServiceProvider).getFollows();
              await _refreshAll(ref, follows);
            },
            child: const Icon(LucideIcons.refreshCw, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Triggers transport probes AND a per-peer sync for every follow. The
/// transport probes refresh LAN/Tor reachability; the per-peer sync
/// pulls any pending feed-key rotation inline via the manifest, which
/// is what keeps the "Key" status row accurate.
Future<void> _refreshAll(WidgetRef ref, List<Follow> follows) async {
  final monitor = ref.read(peerReachabilityMonitorProvider);
  final engine = ref.read(syncEngineProvider);
  await Future.wait([
    monitor.refreshNow(),
    ...follows.map((f) async {
      try {
        await engine.syncOnePeerByPubkey(f.pubkey);
      } catch (_) {
        // syncOnePeer already logs; swallow per-peer failures so the
        // refresh as a whole always completes.
      }
    }),
  ]);
}

class _PeerTile extends ConsumerWidget {
  const _PeerTile({required this.follow, required this.reachability});

  final Follow follow;
  final PeerReachability? reachability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final profileAsync = ref.watch(followProfileProvider(follow.pubkey));
    final name = profileAsync.maybeWhen(
      data: (p) => p.displayName,
      orElse: () =>
          follow.displayName?.trim().isNotEmpty == true
              ? follow.displayName!.trim()
              : shortFinchAddress(follow.pubkey),
    );

    final lan = reachability?.transports[PeerTransport.lan];
    final tor = reachability?.transports[PeerTransport.tor];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: finch.colors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: finch.typography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: finch.colors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                shortFinchAddress(follow.pubkey),
                style: finch.typography.micro.copyWith(
                  color: finch.colors.stone,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TransportRow(label: 'LAN', status: lan),
          const SizedBox(height: 4),
          _TransportRow(label: 'Tor', status: tor),
          const SizedBox(height: 4),
          _KeyHealthRow(follow: follow),
        ],
      ),
    );
  }
}

enum _KeyHealth { unknown, ok, stale }

class _KeyHealthRow extends StatelessWidget {
  const _KeyHealthRow({required this.follow});

  final Follow follow;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final health = _classify(follow);
    final (label, fg, bg) = switch (health) {
      _KeyHealth.ok => (
          'Fresh',
          finch.colors.sageDeep,
          finch.colors.sageSoft,
        ),
      _KeyHealth.stale => (
          'Stale',
          finch.colors.danger,
          finch.colors.linen,
        ),
      _KeyHealth.unknown => (
          'Unknown',
          finch.colors.stone,
          finch.colors.linen,
        ),
    };
    final detail = _detail(follow, health);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            'Key',
            style: finch.typography.small.copyWith(
              color: finch.colors.graphite,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: finch.typography.micro.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: detail == null
              ? const SizedBox.shrink()
              : Text(
                  detail,
                  style: finch.typography.micro.copyWith(
                    color: finch.colors.stone,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }

  static _KeyHealth _classify(Follow follow) {
    if (follow.lastDecryptFailureAt != null) return _KeyHealth.stale;
    if (follow.lastSyncedAt > 0) return _KeyHealth.ok;
    return _KeyHealth.unknown;
  }

  static String? _detail(Follow follow, _KeyHealth health) {
    if (health == _KeyHealth.stale && follow.lastDecryptFailureAt != null) {
      final t = DateTime.fromMillisecondsSinceEpoch(
        follow.lastDecryptFailureAt! * 1000,
      );
      return 'decrypt failed ${_relativeTime(t)} — re-pair if not recovered';
    }
    if (health == _KeyHealth.ok && follow.lastSyncedAt > 0) {
      final t = DateTime.fromMillisecondsSinceEpoch(
        follow.lastSyncedAt * 1000,
      );
      return 'verified ${_relativeTime(t)}';
    }
    return null;
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.label, required this.status});

  final String label;
  final TransportStatus? status;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final state = status?.state ?? TransportState.unknown;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: finch.typography.small.copyWith(
              color: finch.colors.graphite,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StatusChip(state: state),
        const SizedBox(width: 8),
        Expanded(child: _TransportDetails(status: status)),
      ],
    );
  }
}

class _TransportDetails extends StatelessWidget {
  const _TransportDetails({required this.status});

  final TransportStatus? status;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final s = status;
    if (s == null) {
      return Text(
        '—',
        style: finch.typography.micro.copyWith(color: finch.colors.stone),
      );
    }
    final lines = <String>[];
    if (s.endpointHint != null) {
      lines.add(s.endpointHint!);
    }
    if (s.state == TransportState.unreachable && s.lastError != null) {
      lines.add(s.lastError!);
      if (s.consecutiveFailures > 1) {
        lines.add('${s.consecutiveFailures} consecutive failures');
      }
    }
    if (s.lastChange != null) {
      lines.add('updated ${_relativeTime(s.lastChange!)}');
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              line,
              style: finch.typography.micro.copyWith(
                color: finch.colors.stone,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});

  final TransportState state;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final (label, fg, bg) = switch (state) {
      TransportState.reachable => (
          'Reachable',
          finch.colors.sageDeep,
          finch.colors.sageSoft,
        ),
      TransportState.probing => (
          'Probing…',
          finch.colors.graphite,
          finch.colors.linen,
        ),
      TransportState.unreachable => (
          'Unreachable',
          finch.colors.danger,
          finch.colors.linen,
        ),
      TransportState.unknown => (
          'Unknown',
          finch.colors.stone,
          finch.colors.linen,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: finch.typography.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Add friends to see their connection status here.',
          textAlign: TextAlign.center,
          style: finch.typography.small.copyWith(color: finch.colors.graphite),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style:
              finch.typography.small.copyWith(color: finch.colors.danger),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final delta = DateTime.now().difference(t);
  if (delta.inSeconds < 5) return 'just now';
  if (delta.inSeconds < 60) return '${delta.inSeconds}s ago';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  return '${delta.inDays}d ago';
}
