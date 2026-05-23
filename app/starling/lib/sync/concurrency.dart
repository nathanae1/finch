import 'dart:async';
import 'dart:collection';

/// A bounded concurrency pool. Only [maxConcurrent] tasks run at once;
/// later submissions queue and run as earlier ones complete.
///
/// Used by the sync engine to cap how many peer connections are in flight
/// simultaneously (Plan 09 spec: max 5 peers).
class Pool {
  Pool(this.maxConcurrent) : assert(maxConcurrent > 0);

  final int maxConcurrent;
  int _running = 0;
  final Queue<Completer<void>> _waiting = Queue<Completer<void>>();

  /// Schedule [task] for execution. Resolves with the task's value (or
  /// error) once it has both acquired a slot and finished running.
  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= maxConcurrent) {
      final waiter = Completer<void>();
      _waiting.add(waiter);
      await waiter.future;
    }
    _running++;
    try {
      return await task();
    } finally {
      _running--;
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete();
      }
    }
  }
}
