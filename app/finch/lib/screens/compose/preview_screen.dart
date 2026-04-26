import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/compose_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/post_provider.dart';
import '../../theme/finch_theme.dart';
import '../../widgets/buttons.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _isPublishing = false;
  String? _error;

  Future<void> _publish() async {
    final state = ref.read(composeControllerProvider);
    final bytes = state.photoBytes;
    if (bytes == null) return;
    setState(() {
      _isPublishing = true;
      _error = null;
    });
    ref.read(composeControllerProvider.notifier).markPublishing();
    try {
      await ref.read(postServiceProvider).createPost(
            photoBytes: bytes,
            caption: state.caption,
          );
      ref.invalidate(ownEventsProvider);
      ref.invalidate(feedProvider);
      ref.invalidate(ownPostsProvider);
      if (!mounted) return;
      // Pop preview + compose first, then invalidate the compose provider
      // after the modal is torn down. Invalidating while both screens are
      // still mounted causes a markNeedsBuild-during-build storm because
      // both subscribe to the same provider.
      context.pop();
      if (context.canPop()) context.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(composeControllerProvider);
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _error = "Couldn't publish. Try again.";
      });
      ref.read(composeControllerProvider.notifier).markPublishFailed('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final state = ref.watch(composeControllerProvider);
    final bytes = state.photoBytes;

    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    ),
                  if (state.caption.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(state.caption, style: finch.typography.body),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: finch.typography.small
                          .copyWith(color: finch.colors.danger),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StickyBar(
              isPublishing: _isPublishing,
              onBack: _isPublishing ? null : () => context.pop(),
              onPost: _isPublishing ? null : _publish,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.isPublishing,
    required this.onBack,
    required this.onPost,
  });

  final bool isPublishing;
  final VoidCallback? onBack;
  final Future<void> Function()? onPost;

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              GhostButton(label: 'Back to edit', onPressed: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: isPublishing ? 'Posting…' : 'Post',
                  block: true,
                  onPressed: onPost == null ? null : () => onPost!(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
