import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_provider.dart';
import '../../theme/starling_theme.dart';
import '../../widgets/buttons.dart';

class RecoveryPhraseScreen extends ConsumerStatefulWidget {
  const RecoveryPhraseScreen({super.key});

  @override
  ConsumerState<RecoveryPhraseScreen> createState() =>
      _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends ConsumerState<RecoveryPhraseScreen> {
  bool _copied = false;

  Future<void> _copy(String joined) async {
    await Clipboard.setData(ClipboardData(text: joined));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final starling = StarlingTheme.of(context);
    final session = ref.watch(onboardingControllerProvider);
    final phrase = session.recoveryPhrase ?? const <String>[];

    if (phrase.isEmpty) {
      // Shouldn't happen — recovery phrase is set when createIdentity runs.
      // If we landed here with no phrase, bounce back to welcome.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/onboarding/welcome');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: starling.colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your recovery phrase',
                style: starling.typography.h1.copyWith(fontSize: 28, height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(
                "Write this down. It's the only way to recover your account — "
                'there is no server that knows who you are.',
                style: starling.typography.small,
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: starling.colors.linen,
                  border: Border.all(color: starling.colors.hairline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: phrase.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 20,
                    mainAxisExtent: 22,
                  ),
                  itemBuilder: (context, i) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.right,
                            style: starling.typography.monoSmall
                                .copyWith(color: starling.colors.stone),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          phrase[i],
                          style: starling.typography.mono
                              .copyWith(color: starling.colors.ink),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Don't screenshot. Don't type it into anything connected to the "
                'internet. A piece of paper in a drawer is safer than any app.',
                style: starling.typography.caption.copyWith(color: starling.colors.stone),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => _copy(phrase.join(' ')),
                style: TextButton.styleFrom(
                  foregroundColor: starling.colors.sageDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  _copied ? 'Copied' : 'Copy to clipboard',
                  style: starling.typography.caption.copyWith(
                    color: starling.colors.sageDeep,
                    decoration: TextDecoration.underline,
                    decorationColor: starling.colors.sageDeep,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'I wrote it down',
                block: true,
                onPressed: () {
                  ref
                      .read(onboardingControllerProvider.notifier)
                      .clearRecoveryPhrase();
                  context.go('/feed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
