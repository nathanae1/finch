import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/onboarding_provider.dart';
import '../../theme/finch_theme.dart';
import '../../widgets/buttons.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _controller = TextEditingController();
  bool _restoring = false;
  String? _error;

  List<String> get _words => _controller.text
      .split(RegExp(r'\s+'))
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.isNotEmpty)
      .toList();

  bool get _canRestore => _words.length == 24 && !_restoring;

  Future<void> _onRestore() async {
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .restoreIdentity(_words);
      if (!mounted) return;
      context.go('/feed');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('unknown word')) {
      return "That doesn't look like a valid recovery phrase. One of the words isn't in the word list.";
    }
    if (msg.contains('checksum')) {
      return "That phrase doesn't match — check for typos or a missing word.";
    }
    if (msg.contains('24 words')) {
      return 'Your recovery phrase is 24 words. You\'ve entered ${_words.length}.';
    }
    return 'Could not restore: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinchIconButton(
                onPressed: () => context.go('/onboarding/welcome'),
                child: const Icon(LucideIcons.arrowLeft, size: 20),
              ),
              const SizedBox(height: 18),
              Text(
                'Restore from\nrecovery phrase',
                style: finch.typography.h1.copyWith(fontSize: 28, height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(
                'Paste or type your 24 words, separated by spaces. Your friends '
                "and posts won't come back — there's nothing to restore from "
                'the network — but your account will.',
                style: finch.typography.small,
              ),
              const SizedBox(height: 22),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  style: finch.typography.mono,
                  cursorColor: finch.colors.sage,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: finch.colors.linen,
                    hintText:
                        'river candle slow paper linen finch morning kettle ...',
                    hintStyle: finch.typography.mono
                        .copyWith(color: finch.colors.stone),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: finch.colors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: finch.colors.sage, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: finch.colors.hairline),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: finch.typography.small.copyWith(color: finch.colors.danger),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  '${_words.length} / 24 words',
                  style: finch.typography.caption.copyWith(color: finch.colors.stone),
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: _restoring ? 'Restoring…' : 'Restore',
                block: true,
                onPressed: _canRestore ? _onRestore : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
