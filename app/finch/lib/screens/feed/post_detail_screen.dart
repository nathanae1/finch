import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/models.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_profile_provider.dart';
import '../../providers/service_providers.dart';
import '../../theme/finch_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/avatar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/encrypted_image.dart';
import '../../widgets/finch_icon.dart';

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
                  const SizedBox(height: 24),
                  _CommentsPlaceholder(),
                ],
              ),
            ),
          ),
          const _DisabledComposerBar(),
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
    final savedAsync = ref.watch(eventSavedProvider(eventId));
    final isSaved = savedAsync.maybeWhen(data: (v) => v, orElse: () => false);

    return Row(
      children: [
        FinchIcon(
          PhosphorIconsRegular.heart,
          size: 24,
          color: finch.colors.graphite,
        ),
        const SizedBox(width: 18),
        FinchIcon(
          PhosphorIconsRegular.chatCircle,
          size: 24,
          color: finch.colors.graphite,
        ),
        const Spacer(),
        FinchIconButton(
          onPressed: () =>
              ref.read(bookmarkControllerProvider(eventId).notifier).toggle(),
          child: Icon(
            isSaved
                ? PhosphorIconsFill.bookmarkSimple
                : PhosphorIconsRegular.bookmarkSimple,
            size: 22,
            color:
                isSaved ? finch.colors.sageDeep : finch.colors.graphite,
          ),
        ),
      ],
    );
  }
}

class _CommentsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Text(
          'No comments yet.',
          style: finch.typography.small.copyWith(color: finch.colors.stone),
        ),
      ),
    );
  }
}

/// Layout slot for Plan 10's comment composer. Disabled here so the visual
/// chrome lands now and Plan 10 just enables it.
class _DisabledComposerBar extends StatelessWidget {
  const _DisabledComposerBar();

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: finch.colors.paper,
        border: Border(top: BorderSide(color: finch.colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              const Avatar(name: 'You', size: AvatarSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: finch.colors.hairline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Comments come in Plan 10',
                    style: finch.typography.small
                        .copyWith(color: finch.colors.stone),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FinchIconButton(
                onPressed: null,
                child: Icon(
                  PhosphorIconsRegular.paperPlaneTilt,
                  size: 20,
                  color: finch.colors.stone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
