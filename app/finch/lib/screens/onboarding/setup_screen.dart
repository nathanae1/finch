import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/onboarding_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/finch_theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/inputs.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _controller = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      ref
          .read(onboardingProfileControllerProvider.notifier)
          .setDisplayName(_controller.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canContinue => _controller.text.trim().isNotEmpty && !_creating;

  Future<void> _onContinue() async {
    setState(() => _creating = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).createIdentity();
      if (!mounted) return;
      context.go('/onboarding/recovery');
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create identity: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final name = _controller.text.trim();

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
                child: const Icon(PhosphorIconsRegular.arrowLeft, size: 20),
              ),
              const SizedBox(height: 18),
              Text('Pick a name and photo',
                  style: finch.typography.h1.copyWith(fontSize: 28, height: 1.15)),
              const SizedBox(height: 6),
              Text(
                'Just for your friends. You can change it anytime.',
                style: finch.typography.small,
              ),
              const SizedBox(height: 36),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Avatar(
                      name: name.isEmpty ? 'Sam' : name,
                      color: finch.colors.clay,
                      size: AvatarSize.lg,
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: finch.colors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(color: finch.colors.hairline),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          PhosphorIconsRegular.camera,
                          size: 16,
                          color: finch.colors.graphite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const FinchFieldLabel('Display name'),
              const SizedBox(height: 6),
              FinchInput(
                controller: _controller,
                placeholder: 'Sam',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_canContinue) _onContinue();
                },
              ),
              const Spacer(),
              PrimaryButton(
                label: _creating ? 'Creating…' : 'Continue',
                block: true,
                onPressed: _canContinue ? _onContinue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
