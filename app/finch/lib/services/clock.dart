/// Injectable time source. Every timestamp in crypto, sync, and event
/// creation goes through this. Prevents clock-skew bugs and enables
/// deterministic testing.
abstract class Clock {
  int nowUnixSeconds();
}

/// Production implementation: system clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowUnixSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
