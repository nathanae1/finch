import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/follow_provider.dart';
import '../../services/types.dart';
import '../../theme/finch_theme.dart';

class FriendActionsSheet extends ConsumerWidget {
  const FriendActionsSheet({super.key, required this.follow});

  final Follow follow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finch = FinchTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            follow.displayName ??
                (follow.pubkey.length > 8
                    ? follow.pubkey.substring(0, 8)
                    : follow.pubkey),
            style: finch.typography.h3,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: PhosphorIconsRegular.user,
          label: 'View profile',
          onTap: () {
            Navigator.of(context).pop();
            context.push('/friends/profile/${follow.pubkey}');
          },
        ),
        _ActionRow(
          icon: PhosphorIconsRegular.userMinus,
          label: 'Unfollow',
          destructive: true,
          onTap: () => _confirmUnfollow(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmUnfollow(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Unfollow?'),
          content: Text(
            'You will stop receiving posts from '
            '${follow.displayName ?? "this friend"}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Unfollow'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    await ref.read(followServiceProvider).unfollow(follow.pubkey);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final color = destructive ? finch.colors.danger : finch.colors.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: finch.typography.body.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
