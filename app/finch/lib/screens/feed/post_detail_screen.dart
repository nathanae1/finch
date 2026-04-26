import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/models.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_profile_provider.dart';
import '../../providers/reactions_provider.dart';
import '../../providers/service_providers.dart';
import '../../theme/finch_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/avatar.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/buttons.dart';
import '../../widgets/comment_input.dart';
import '../../widgets/comment_list.dart';
import '../../widgets/encrypted_image.dart';
import '../../widgets/reaction_button.dart';

/// Full-screen post view. Plan 06 wires the bookmark toggle and stubs the
/// composer slot (Plan 10 enables it). Marking the post as last_viewed
/// happens once on mount so retention's grace period kicks in.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget; failure to update last_viewed is not user-visible.
    final storage = ref.read(storageServiceProvider);
    final clock = ref.read(clockProvider);
    storage.setEventLastViewed(widget.eventId, clock.nowUnixSeconds());
  }

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final eventAsync = ref.watch(eventByIdProvider(widget.eventId));

    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: eventAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e',
                style: finch.typography.small
                    .copyWith(color: finch.colors.danger)),
          ),
        ),
        data: (event) {
          if (event == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'This post is no longer available.',
                  textAlign: TextAlign.center,
                  style: finch.typography.small,
                ),
              ),
            );
          }
          return _PostDetailBody(event: event);
        },
      ),
    );
  }
}

class _PostDetailBody extends ConsumerWidget {
  const _PostDetailBody({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final clock = ref.watch(clockProvider);
    final caption = event.content.isEmpty
        ? ''
        : utf8.decode(event.content, allowMalformed: true);
    final mediaHash = event.media.isNotEmpty ? event.media.first.hash : null;
    final profile = ref.watch(followProfileProvider(event.pubkey));
    final displayName = profile.maybeWhen(
      data: (p) => firstNameOf(p.displayName),
      orElse: () => 'Friend',
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _DetailHeader(
            displayName: displayName,
            pubkey: event.pubkey,
            createdAt: event.createdAt,
            now: clock.nowUnixSeconds(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mediaHash != null)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        caption,
                        style: finch.typography.body.copyWith(height: 1.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ActionRow(eventId: event.id),
                  ),
                  const SizedBox(height: 16),
                  CommentList(postId: event.id),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          CommentInput(postId: event.id),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.displayName,
    required this.pubkey,
    required this.createdAt,
    required this.now,
  });

  final String displayName;
  final String pubkey;
  final int createdAt;
  final int now;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: finch.colors.paper,
        border: Border(bottom: BorderSide(color: finch.colors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: Row(
        children: [
          FinchIconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Icon(PhosphorIconsRegular.arrowLeft, size: 20),
          ),
          const SizedBox(width: 4),
          Avatar(name: displayName, size: AvatarSize.sm),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              style: finch.typography.small.copyWith(
                fontWeight: FontWeight.w600,
                color: finch.colors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeAgo(createdAt, nowUnixSeconds: now),
            style: finch.typography.micro,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    final reactionsAsync = ref.watch(reactionsProvider(eventId));
    final summary = reactionsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const ReactionSummary(count: 0, likedByMe: false),
    );

    return Row(
      children: [
        ReactionButton(
          liked: summary.likedByMe,
          count: summary.count,
          iconSize: 24,
          onTap: () =>
              ref.read(reactionControllerProvider(eventId).notifier).toggle(),
        ),
        const SizedBox(width: 18),
        // Chat icon is just a visual marker on detail (the comments list
        // is right below); tapping it focuses the composer would be a
        // future polish, not load-bearing now.
        Icon(
          PhosphorIconsRegular.chatCircle,
          size: 24,
          color: finch.colors.graphite,
        ),
        const Spacer(),
        BookmarkButton(eventId: eventId),
      ],
    );
  }
}
