import 'package:flutter/material.dart';

import '../theme/starling_theme.dart';

enum SyncState { synced, syncing, waiting, offline }

class SyncDot extends StatefulWidget {
  const SyncDot({super.key, required this.state});
  final SyncState state;

  @override
  State<SyncDot> createState() => _SyncDotState();
}

class _SyncDotState extends State<SyncDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _syncToState();
  }

  @override
  void didUpdateWidget(covariant SyncDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncToState();
    }
  }

  /// Only run the controller when the dot is actually pulsing. A
  /// permanently-repeating controller blocks `pumpAndSettle` in widget
  /// tests and burns frames in production for steady-state UIs.
  void _syncToState() {
    if (widget.state == SyncState.syncing) {
      if (!_ctrl.isAnimating) {
        _ctrl.repeat(reverse: true);
      }
    } else {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _colorFor(StarlingTheme starling) => switch (widget.state) {
        SyncState.synced => starling.colors.success,
        SyncState.syncing => starling.colors.sage,
        SyncState.waiting => starling.colors.clay,
        SyncState.offline => starling.colors.stone,
      };

  @override
  Widget build(BuildContext context) {
    final starling = StarlingTheme.of(context);
    final color = _colorFor(starling);
    final pulse = widget.state == SyncState.syncing;

    if (!pulse) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final opacity = 0.45 + (1.0 - 0.45) * (1 - (1 - 2 * t).abs());
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
