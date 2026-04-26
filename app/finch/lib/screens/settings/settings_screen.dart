import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/finch_theme.dart';
import '../../widgets/buttons.dart';

/// Placeholder settings screen. Real implementation arrives with Plan 15.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Scaffold(
      backgroundColor: finch.colors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: finch.colors.hairline)),
              ),
              child: Row(
                children: [
                  FinchIconButton(
                    onPressed: () => context.pop(),
                    child: const Icon(PhosphorIconsRegular.arrowLeft, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: finch.typography.h3.copyWith(
                        fontFamily: 'Fraunces',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Settings — Plan 15 fills this in.',
                    textAlign: TextAlign.center,
                    style: finch.typography.small.copyWith(color: finch.colors.stone),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
