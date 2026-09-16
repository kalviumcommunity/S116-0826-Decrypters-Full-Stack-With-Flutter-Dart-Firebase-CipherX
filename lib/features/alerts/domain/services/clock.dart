/// Clean clock abstraction to decouple time calculations from system wall clock.
///
/// Enables 100% deterministic testing of time-based threshold boundaries.
abstract interface class Clock {
  DateTime now();
}

/// Default system clock provider using [DateTime.now()].
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Controllable clock for unit and simulation tests.
class FakeClock implements Clock {
  DateTime _current;

  FakeClock(this._current);

  @override
  DateTime now() => _current;

  void setTime(DateTime time) {
    _current = time;
  }

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}
