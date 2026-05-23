import 'package:starling/services/mocks/mock_clock.dart';
import 'package:starling/sync/key_refresh_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first acquire succeeds; second within cooldown is denied', () {
    final clock = MockClock();
    final throttle = KeyRefreshThrottle(
      clock: clock,
      cooldown: const Duration(seconds: 60),
    );
    expect(throttle.tryAcquire('peer-a'), isTrue);
    expect(throttle.tryAcquire('peer-a'), isFalse);
  });

  test('cooldown expires after the configured window', () {
    final clock = MockClock();
    final throttle = KeyRefreshThrottle(
      clock: clock,
      cooldown: const Duration(seconds: 60),
    );
    expect(throttle.tryAcquire('peer-a'), isTrue);
    clock.advance(59);
    expect(throttle.tryAcquire('peer-a'), isFalse);
    clock.advance(2); // crosses 60s
    expect(throttle.tryAcquire('peer-a'), isTrue);
  });

  test('per-peer scoping — peer-b is not gated by peer-a', () {
    final clock = MockClock();
    final throttle = KeyRefreshThrottle(clock: clock);
    expect(throttle.tryAcquire('peer-a'), isTrue);
    expect(throttle.tryAcquire('peer-b'), isTrue);
  });

  test('resetForTesting clears all state', () {
    final clock = MockClock();
    final throttle = KeyRefreshThrottle(clock: clock);
    throttle.tryAcquire('peer-a');
    throttle.resetForTesting();
    expect(throttle.tryAcquire('peer-a'), isTrue);
  });
}
