import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/models.dart';
import '../../providers/follow_profile_provider.dart';
import '../../providers/service_providers.dart';
import '../../theme/finch_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/avatar.dart';
import '../../widgets/encrypted_image.dart';
import '../../widgets/finch_icon.dart';

/// A single post in the chronological feed. Plan 06 ships static heart and
/// comment counts (both 0); Plan 10 wires the real toggles.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final profile = ref.watch(followProfileProvider(event.pubkey));
    final clock = ref.watch(clockProvider);
    final caption = event.content.isEmpty
        ? ''
        : utf8.decode(event.content, allowMalformed: true);
    final mediaHash = event.media.isNotEmpty ? event.media.first.hash : null;

    final displayName = profile.maybeWhen(
      data: (p) => firstNameOf(p.displayName),
      orElse: () => 'Friend',
    );
    final avatarHash = profile.maybeWhen(
      data: (p) => p.avatarHash,
      orElse: () => null,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  _AuthorAvatar(
                    pubkey: event.pubkey,
                    name: displayName,
                    avatarHash: avatarHash,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayName,
                      style: finch.typography.small.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: finch.colors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeAgo(event.createdAt,
                        nowUnixSeconds: clock.nowUnixSeconds()),
                    style: finch.typography.micro,
                  ),
                ],
              ),
            ),
            // Photo: full-bleed 4:5 with hairline top/bottom; no radii.
            if (mediaHash != null)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: finch.colors.hairline),
                    bottom: BorderSide(color: finch.colors.hairline),
                  ),
                ),
                child: EncryptedImage(
                  hash: mediaHash,
                  pubkey: event.pubkey,
                  aspectRatio: 4 / 5,
                ),
              ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  caption,
                  style: finch.typography.body
                      .copyWith(fontSize: 15, height: 1.5),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  _ActionIcon(
                    icon: PhosphorIconsRegular.heart,
                    count: 0,
                  ),
                  SizedBox(width: 18),
                  _ActionIcon(
                    icon: PhosphorIconsRegular.chatCircle,
                    count: 0,
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

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.pubkey,
    required this.name,
    required this.avatarHash,
  });

  final String pubkey;
  final String name;
  final String? avatarHash;

  @override
  Widget build(BuildContext context) {
    // Hash-derived color when no avatar image is set, so each friend has a
    // stable, distinct circle. Pure helper; no collision protection.
    final colors = FinchTheme.of(context).colors;
    final palette = [
      colors.sage,
      colors.clay,
      colors.sageDeep,
      colors.clayDeep,
    ];
    final color = palette[pubkey.hashCode.abs() % palette.length];
    return Avatar(name: name, color: color, size: AvatarSize.sm);
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.count});

  final PhosphorIconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Row(
      children: [
        FinchIcon(icon, size: 22, color: finch.colors.graphite),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Text('$count', style: finch.typography.small),
        ],
      ],
    );
  }
}
