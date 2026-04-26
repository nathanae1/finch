import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/follow_provider.dart';
import '../theme/finch_theme.dart';
import '../utils/connection_card_parser.dart';
import 'buttons.dart';
import 'qr_code.dart';

class QrInviteSheet extends ConsumerStatefulWidget {
  const QrInviteSheet({super.key});

  @override
  ConsumerState<QrInviteSheet> createState() => _QrInviteSheetState();
}

class _QrInviteSheetState extends ConsumerState<QrInviteSheet> {
  bool _justCopied = false;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final cardAsync = ref.watch(ownConnectionCardProvider);

    return cardAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text('Couldn\'t load your invite: $e',
              style: finch.typography.small),
        ),
      ),
      data: (card) {
        if (card == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Finish onboarding before sharing your invite.',
                style: finch.typography.small,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final url = inviteUrlFor(card);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Scan to add me as a friend',
              style: finch.typography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Share this with people you trust. There's no way for "
              'strangers to find you.',
              style: finch.typography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FinchQRCode(data: url),
            const SizedBox(height: 16),
            Text(
              url,
              style: finch.typography.monoSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: _justCopied ? 'Copied' : 'Copy link',
                    onPressed: () => _onCopy(url),
                    block: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                    block: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GhostButton(
              label: "Scan a friend's QR instead",
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/friends/scan');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onCopy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }
}
