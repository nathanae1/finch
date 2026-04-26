import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/follow_provider.dart';
import '../../providers/follow_requests_provider.dart';
import '../../providers/follows_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/follow_service.dart';
import '../../services/types.dart';
import '../../theme/finch_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/avatar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/qr_invite_sheet.dart';
import '../../widgets/sheet.dart';
import '../../widgets/top_bar.dart';
import 'friend_actions_sheet.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final followsAsync = ref.watch(followsStreamProvider);
    final inboundAsync = ref.watch(inboundRequestsStreamProvider);
    final outboundAsync = ref.watch(outboundRequestsStreamProvider);

    final follows = followsAsync.valueOrNull ?? const <Follow>[];
    final inbound = inboundAsync.valueOrNull ?? const <FollowRequest>[];
    final outbound = outboundAsync.valueOrNull ?? const <FollowRequest>[];

    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FinchTopBar(
              title: 'Friends',
              right: FinchIconButton(
                onPressed: () => _showInvite(context),
                child: const Icon(PhosphorIconsRegular.plus, size: 20),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  ...inbound.map((r) => _InboundBanner(request: r)),
                  if (inbound.isNotEmpty) const SizedBox(height: 12),
                  _AddFriendCard(onTap: () => _showInvite(context)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '${follows.length} friend${follows.length == 1 ? '' : 's'}',
                      style: finch.typography.micro,
                    ),
                  ),
                  if (follows.isEmpty && outbound.isEmpty)
                    _EmptyHint()
                  else ...[
                    for (final follow in follows) _FriendRow(follow: follow),
                    for (final pending in outbound)
                      _OutboundPendingRow(request: pending),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvite(BuildContext context) {
    showFinchSheet(
      context: context,
      builder: (_) => const QrInviteSheet(),
    );
  }
}

class _InboundBanner extends ConsumerWidget {
  const _InboundBanner({required this.request});
  final FollowRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final shortPubkey = request.pubkey.length > 8
        ? request.pubkey.substring(0, 8)
        : request.pubkey;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: finch.colors.sageSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: finch.colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(name: shortPubkey, color: finch.colors.sage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shortPubkey, style: finch.typography.body),
                    Text('wants to follow you',
                        style: finch.typography.micro),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Reject',
                  onPressed: () => _reject(context, ref),
                  block: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Accept',
                  onPressed: () => _accept(context, ref),
                  block: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final delivery = await ref
          .read(followServiceProvider)
          .acceptFollowRequest(request.pubkey);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(
        content: Text(switch (delivery) {
          AcceptDelivery.delivered => 'Accepted',
          AcceptDelivery.queued => 'Accepted — queued for retry',
          AcceptDelivery.failed => 'Accept failed',
        }),
        duration: const Duration(seconds: 2),
      ));
    } on FollowFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Accept failed: ${e.message}')));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(followServiceProvider).rejectFollowRequest(request.pubkey);
  }
}

class _AddFriendCard extends StatelessWidget {
  const _AddFriendCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Material(
      color: finch.colors.linen,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: finch.colors.hairline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: finch.colors.sageSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  PhosphorIconsRegular.qrCode,
                  size: 22,
                  color: finch.colors.sageDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a friend', style: finch.typography.body),
                    const SizedBox(height: 2),
                    Text(
                      'Scan their QR, or share yours.',
                      style: finch.typography.micro,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PrimaryButton(label: 'Open', onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends ConsumerWidget {
  const _FriendRow({required this.follow});
  final Follow follow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final clock = ref.watch(clockProvider);
    final now = clock.nowUnixSeconds();
    final reachable = follow.lastSyncedAt > 0 &&
        now - follow.lastSyncedAt < 60;
    final statusText = reachable
        ? '● Reachable'
        : follow.lastSyncedAt > 0
            ? 'Last seen ${timeAgo(follow.lastSyncedAt, nowUnixSeconds: now)}'
            : 'Not yet synced';
    final statusColor =
        reachable ? finch.colors.success : finch.colors.stone;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: finch.colors.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Avatar(
            name: follow.displayName ?? follow.pubkey,
            size: AvatarSize.md,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  follow.displayName ??
                      (follow.pubkey.length > 8
                          ? follow.pubkey.substring(0, 8)
                          : follow.pubkey),
                  style: finch.typography.body,
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: finch.typography.micro.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          FinchIconButton(
            onPressed: () => showFinchSheet(
              context: context,
              builder: (_) => FriendActionsSheet(follow: follow),
            ),
            child: const Icon(PhosphorIconsRegular.dotsThree, size: 20),
          ),
        ],
      ),
    );
  }
}

class _OutboundPendingRow extends StatelessWidget {
  const _OutboundPendingRow({required this.request});
  final FollowRequest request;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final shortPubkey = request.pubkey.length > 8
        ? request.pubkey.substring(0, 8)
        : request.pubkey;
    final statusLabel = switch (request.status) {
      'pending' => 'Pending',
      'pending-send' => 'Pending — retrying',
      'send-failed' => 'Send failed',
      'accepted' => 'Sent',
      _ => request.status,
    };
    return Opacity(
      opacity: 0.65,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: finch.colors.hairline),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Avatar(name: shortPubkey, size: AvatarSize.md),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shortPubkey, style: finch.typography.body),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: finch.typography.micro
                        .copyWith(color: finch.colors.stone),
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

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            PhosphorIconsRegular.usersThree,
            size: 32,
            color: finch.colors.stone,
          ),
          const SizedBox(height: 8),
          Text(
            'No friends yet',
            style: finch.typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "Tap 'Add a friend' to scan a QR or share your own.",
            style: finch.typography.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
