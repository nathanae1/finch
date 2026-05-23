import 'dart:async';

/// Single-shared-instance mutex serializing feed-key rotations against post
/// publication (Plan 13).
///
/// Both [KeyRotationService.rotate] and the publish path (PostService /
/// CommentService / ReactionService) acquire the same instance. Without it,
/// a post in flight can read the cache mid-rotation, encrypt with a stale
/// key, and end up undecryptable for followers who already have the new
/// key.
///
/// FIFO: each `synchronized` returns a Future that resolves once all prior
/// callers have finished. A thrown body propagates to its caller but does
/// not block subsequent waiters.
class PublishLock {
  Future<void> _tail = Future.value();

  Future<T> synchronized<T>(Future<T> Function() body) {
    final completer = Completer<void>();
    final previous = _tail;
    _tail = completer.future;
    return previous
        .then((_) => body())
        .whenComplete(() => completer.complete());
  }
}
