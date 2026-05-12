import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/foreground_service_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/sync_provider.dart';
import '../../providers/sync_status_provider.dart';
import '../../theme/finch_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/sync_dot.dart';

/// Plan 14 Phase E — single screen that aggregates the four moving parts of
/// "how is Finch reachable right now": sync state, Tor onion + circuits,
/// LAN peers via mDNS, and the local HTTP server port. Plus the Android-only
/// foreground-service toggle and an informational note for iOS.
///
/// Consumes existing providers — no new state plumbing needed. Per-peer
/// detail lives in `connection_settings_screen.dart`; this screen links to
/// it rather than duplicating the per-friend transport breakdown.
class NetworkSettingsScreen extends ConsumerWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final syncStatus = ref.watch(syncStatusProvider);
    final engineState = ref.watch(syncControllerProvider);
    final tor = ref.watch(torServiceProvider);
    final onion = ref.watch(onionAddressProvider);
    final port = ref.watch(httpServerControllerProvider).value;

    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onRefresh: () =>
                  ref.read(syncControllerProvider.notifier).syncNow(),
              syncing: engineState.phase == SyncRunPhase.syncing,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  _SyncCard(
                    state: syncStatus.state,
                    lastSyncedAtSeconds: syncStatus.lastSyncedAtSeconds,
                    reachableFriends: syncStatus.reachableFriends,
                    lastError: engineState.lastError,
                  ),
                  const SizedBox(height: 12),
                  _TorCard(
                    bootstrapPercent: tor.getStatus().bootstrapPercent,
                    circuitCount: tor.getStatus().circuitCount,
                    isReady: tor.getStatus().isReady,
                    onionAddress: onion,
                  ),
                  const SizedBox(height: 12),
                  _LanCard(reachableFriends: syncStatus.reachableFriends),
                  const SizedBox(height: 12),
                  _ServerCard(port: port),
                  const SizedBox(height: 12),
                  if (Platform.isAndroid)
                    const _AndroidBackgroundCard()
                  else
                    const _IosBackgroundCard(),
                  const SizedBox(height: 12),
                  _PerPeerLink(
                    onTap: () => context.push('/settings/connection'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, required this.syncing});

  final VoidCallback onRefresh;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: finch.colors.hairline)),
      ),
      child: Row(
        children: [
          FinchIconButton(
            onPressed: () => context.pop(),
            child: const Icon(LucideIcons.arrowLeft, size: 20),
          ),
          Expanded(
            child: Text(
              'Network',
              style: finch.typography.h3.copyWith(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FinchIconButton(
            onPressed: syncing ? null : onRefresh,
            child: Icon(
              LucideIcons.refreshCw,
              size: 20,
              color: syncing ? finch.colors.stone : finch.colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: finch.colors.paper,
        border: Border.all(color: finch.colors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: finch.colors.graphite),
              const SizedBox(width: 8),
              Text(
                title,
                style: finch.typography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: finch.colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value, this.valueWidget});

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: finch.typography.small.copyWith(color: finch.colors.graphite),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value,
                  style: finch.typography.small.copyWith(color: finch.colors.ink),
                ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.state,
    required this.lastSyncedAtSeconds,
    required this.reachableFriends,
    required this.lastError,
  });

  final SyncState state;
  final int? lastSyncedAtSeconds;
  final int reachableFriends;
  final String? lastError;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return _SectionCard(
      title: 'Sync',
      icon: LucideIcons.refreshCw,
      children: [
        _KeyValue(
          label: 'Status',
          value: '',
          valueWidget: Row(
            children: [
              SyncDot(state: state),
              const SizedBox(width: 8),
              Text(_syncLabel(state), style: finch.typography.small),
            ],
          ),
        ),
        _KeyValue(
          label: 'Last sync',
          value: _formatTimestamp(lastSyncedAtSeconds),
        ),
        _KeyValue(
          label: 'Reachable',
          value: '$reachableFriends friend${reachableFriends == 1 ? '' : 's'}',
        ),
        if (lastError != null)
          _KeyValue(
            label: 'Last error',
            value: '',
            valueWidget: Text(
              lastError!,
              style: finch.typography.small.copyWith(color: finch.colors.danger),
            ),
          ),
      ],
    );
  }

  static String _syncLabel(SyncState s) => switch (s) {
        SyncState.synced => 'Up to date',
        SyncState.syncing => 'Syncing…',
        SyncState.waiting => 'Waiting',
        SyncState.offline => 'Offline',
      };
}

class _TorCard extends StatelessWidget {
  const _TorCard({
    required this.bootstrapPercent,
    required this.circuitCount,
    required this.isReady,
    required this.onionAddress,
  });

  final int bootstrapPercent;
  final int circuitCount;
  final bool isReady;
  final String? onionAddress;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return _SectionCard(
      title: 'Tor',
      icon: LucideIcons.shield,
      children: [
        _KeyValue(
          label: 'Bootstrap',
          value: isReady ? '100% (ready)' : '$bootstrapPercent%',
        ),
        _KeyValue(label: 'Circuits', value: '$circuitCount'),
        _KeyValue(
          label: 'Onion',
          value: '',
          valueWidget: onionAddress == null
              ? Text(
                  'Not published yet',
                  style:
                      finch.typography.small.copyWith(color: finch.colors.stone),
                )
              : InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: onionAddress!));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Onion address copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          onionAddress!,
                          style: finch.typography.small.copyWith(
                            fontFamily: 'IBMPlexMono',
                            color: finch.colors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.copy,
                          size: 14, color: finch.colors.graphite),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LanCard extends StatelessWidget {
  const _LanCard({required this.reachableFriends});

  final int reachableFriends;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Local Wi-Fi',
      icon: LucideIcons.wifi,
      children: [
        _KeyValue(
          label: 'Reachable',
          value: '$reachableFriends friend${reachableFriends == 1 ? '' : 's'} on this network',
        ),
        const _KeyValue(label: 'Service', value: '_finch._tcp (mDNS/Bonjour)'),
      ],
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.port});

  final int? port;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Local server',
      icon: LucideIcons.server,
      children: [
        _KeyValue(
          label: 'Port',
          value: port == null ? 'Not bound' : '$port',
        ),
        const _KeyValue(label: 'Binding', value: '0.0.0.0 (LAN + Tor onion)'),
      ],
    );
  }
}

class _AndroidBackgroundCard extends ConsumerWidget {
  const _AndroidBackgroundCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final runningAsync = ref.watch(foregroundServiceStateProvider);
    final running = runningAsync.value ?? false;
    return _SectionCard(
      title: 'Background mode',
      icon: LucideIcons.batteryCharging,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep Finch running',
                    style: finch.typography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: finch.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your phone stays reachable to friends in the background. '
                    'Uses more battery.',
                    style: finch.typography.small
                        .copyWith(color: finch.colors.graphite),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: running,
              onChanged: runningAsync.isLoading
                  ? null
                  : (v) async {
                      final notifier =
                          ref.read(foregroundServiceStateProvider.notifier);
                      final ok = await notifier.setEnabled(v);
                      if (!context.mounted) return;
                      if (v && !ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notification permission required for background mode.',
                            ),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          running
              ? 'Background sync also runs every 15 min via WorkManager.'
              : 'Background sync runs every 15 min via WorkManager when possible.',
          style: finch.typography.micro
              .copyWith(color: FinchTheme.of(context).colors.stone),
        ),
      ],
    );
  }
}

class _IosBackgroundCard extends StatelessWidget {
  const _IosBackgroundCard();

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return _SectionCard(
      title: 'Background mode',
      icon: LucideIcons.batteryCharging,
      children: [
        Text(
          'iOS controls background sync timing. Finch checks when iOS '
          'grants permission, usually less often than once per hour. '
          'When your phone is plugged in and idle, longer background '
          'sessions can use Tor.',
          style: finch.typography.small.copyWith(color: finch.colors.graphite),
        ),
      ],
    );
  }
}

class _PerPeerLink extends StatelessWidget {
  const _PerPeerLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: finch.colors.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.users, size: 18, color: finch.colors.graphite),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Per-friend reachability',
                    style: finch.typography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: finch.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'See LAN/Tor status and key freshness for each friend',
                    style: finch.typography.micro,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: finch.colors.stone),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(int? unixSeconds) {
  if (unixSeconds == null || unixSeconds == 0) return 'Never';
  final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}
