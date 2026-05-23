import '../clock.dart';

/// Controllable clock for deterministic tests.
class MockClock implements Clock {
  MockClock([this._now = 1000]);

  int _now;

  @override
  int nowUnixSeconds() => _now;

  void advance(int seconds) => _now += seconds;

  // ignore: use_setters_to_change_properties
  void set(int unixSeconds) => _now = unixSeconds;
}
