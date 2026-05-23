import 'dart:async';

import 'follow_service.dart';

/// Periodic timer that drains queued /follow-accept payloads when the app is
/// in the foreground. Stays small on purpose — Plan 08's only requirement is
/// "if the responder was offline when accept was attempted, eventually deliver
/// it". Backoff lives inside [FollowService.retryQueuedAccepts].
class FollowRetryPump {
  FollowRetryPump({
    required this.followService,
    this.interval = const Duration(seconds: 30),
    this.maxRetries = 10,
  });

  final FollowService followService;
  final Duration interval;
  final int maxRetries;

  Timer? _timer;
  bool _running = false;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => _tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      await followService.retryQueuedAccepts(maxRetries: maxRetries);
    } catch (_) {
      // Errors are logged inside FollowService; the pump itself never fails.
    } finally {
      _running = false;
    }
  }
}
