import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../utils/constants.dart';

enum TripPhase {
  /// Nothing running — the big button says "Start Journey".
  idle,

  /// Stream is open but no usable fix has landed yet.
  acquiring,

  /// Bus is moving, distance is climbing.
  running,

  /// No real movement for a while: the fare gets highlighted, tracking
  /// continues so the trip resumes by itself if the bus pulls away again.
  stopped,

  /// User ended the trip. Numbers are frozen.
  finished,
}

/// The meter. Turns a noisy stream of GPS fixes into a trustworthy distance.
///
/// The filtering here is the whole point: a phone sitting still at a traffic
/// light reports positions that wander several metres, and an unfiltered sum of
/// those would quietly invent a kilometre of fare over a long jam.
class TripState extends ChangeNotifier {
  TripState({required LocationService location}) : _location = location;

  final LocationService _location;

  StreamSubscription<Position>? _subscription;
  Timer? _ticker;

  /// Last position accepted as a real place — the origin of the next segment.
  Position? _anchor;
  DateTime? _lastMovementAt;

  TripPhase _phase = TripPhase.idle;
  double _distanceMeters = 0;
  double _speedMps = 0;
  double? _accuracyMeters;
  DateTime? _startedAt;
  DateTime? _endedAt;
  LocationReadiness? _blocker;

  // --------------------------------------------------------------- getters ---

  TripPhase get phase => _phase;
  double get distanceMeters => _distanceMeters;
  double get speedMps => _phase == TripPhase.running ? _speedMps : 0;
  double? get accuracyMeters => _accuracyMeters;
  LocationReadiness? get blocker => _blocker;

  bool get isActive => _phase == TripPhase.acquiring ||
      _phase == TripPhase.running ||
      _phase == TripPhase.stopped;

  /// Weak signal is worth telling the user about — it is the main reason a
  /// distance can drift.
  bool get weakSignal =>
      isActive && (_accuracyMeters ?? 0) > GpsTuning.weakSignalMeters;

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    final end = _endedAt ?? DateTime.now();
    final value = end.difference(_startedAt!);
    return value.isNegative ? Duration.zero : value;
  }

  // ------------------------------------------------------------- lifecycle ---

  /// Opens the GPS stream. [notificationTitle]/[notificationText] are the
  /// already-localised strings for the Android foreground-service notification
  /// that keeps the meter alive with the screen off.
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
  }) async {
    if (isActive) return;

    final readiness = await _location.ensureReady();
    if (readiness != LocationReadiness.ready) {
      _blocker = readiness;
      notifyListeners();
      return;
    }

    _blocker = null;
    _distanceMeters = 0;
    _speedMps = 0;
    _accuracyMeters = null;
    _anchor = null;
    _startedAt = DateTime.now();
    _endedAt = null;
    _lastMovementAt = _startedAt;
    _phase = TripPhase.acquiring;
    notifyListeners();

    _subscription = _location
        .positions(
          notificationTitle: notificationTitle,
          notificationText: notificationText,
        )
        .listen(_onPosition, onError: _onStreamError);

    // Drives the clock and the "have we stopped?" test once a second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> stop() async {
    if (!isActive) return;
    _endedAt = DateTime.now();
    _phase = TripPhase.finished;
    await _teardown();
    notifyListeners();
  }

  /// Back to a clean meter, ready for the next bus.
  Future<void> reset() async {
    await _teardown();
    _phase = TripPhase.idle;
    _distanceMeters = 0;
    _speedMps = 0;
    _accuracyMeters = null;
    _anchor = null;
    _startedAt = null;
    _endedAt = null;
    _lastMovementAt = null;
    _blocker = null;
    notifyListeners();
  }

  /// "Still moving" — the passenger overrules the stop detector (crawling
  /// traffic can look identical to having arrived).
  void dismissStopDetection() {
    if (_phase != TripPhase.stopped) return;
    _phase = TripPhase.running;
    _lastMovementAt = DateTime.now();
    notifyListeners();
  }

  void clearBlocker() {
    if (_blocker == null) return;
    _blocker = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  // ----------------------------------------------------------------- inner ---

  void _onPosition(Position position) {
    // Rule 1: a fix we don't trust is not data.
    if (position.accuracy > GpsTuning.maxAccuracyMeters) {
      _accuracyMeters = position.accuracy;
      notifyListeners();
      return;
    }

    _accuracyMeters = position.accuracy;
    _speedMps = position.speed.isFinite && position.speed > 0 ? position.speed : 0;

    final anchor = _anchor;
    if (anchor == null) {
      // First trustworthy fix: this is Point A.
      _anchor = position;
      _lastMovementAt = DateTime.now();
      _phase = TripPhase.running;
      notifyListeners();
      return;
    }

    final meters = LocationService.metersBetween(anchor, position);
    final seconds = _secondsBetween(anchor, position);

    // Rule 2: a jump no bus could make is a glitch. Re-anchor, count nothing.
    if (seconds > 0 && meters / seconds > GpsTuning.maxPlausibleSpeedMps) {
      _anchor = position;
      notifyListeners();
      return;
    }

    // Rule 3: below the jitter floor, keep the old anchor. Genuine slow travel
    // still gets counted once it accumulates past the threshold.
    if (meters < GpsTuning.minSegmentMeters) {
      notifyListeners();
      return;
    }

    _distanceMeters += meters;
    _anchor = position;
    _lastMovementAt = DateTime.now();
    if (_phase != TripPhase.running) _phase = TripPhase.running;
    notifyListeners();
  }

  void _onStreamError(Object error) {
    // Losing the stream mid-trip (GPS switched off, permission revoked) must
    // not wipe the distance already earned — freeze and let the user decide.
    _speedMps = 0;
    if (_phase == TripPhase.running || _phase == TripPhase.acquiring) {
      _phase = TripPhase.stopped;
    }
    notifyListeners();
  }

  void _onTick() {
    if (!isActive) return;

    final since = _lastMovementAt == null
        ? Duration.zero
        : DateTime.now().difference(_lastMovementAt!);

    if (_phase == TripPhase.running &&
        since > GpsTuning.idleTimeout &&
        _speedMps < GpsTuning.idleSpeedMps) {
      _phase = TripPhase.stopped;
      _speedMps = 0;
    }

    // The elapsed clock is derived, so a plain notify is enough to redraw it.
    notifyListeners();
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Seconds between two fixes, or 0 when a device reports non-increasing
  /// timestamps — in that case the speed-plausibility check is simply skipped
  /// for this segment rather than being fed a bogus divisor.
  double _secondsBetween(Position a, Position b) {
    final delta = b.timestamp.difference(a.timestamp).inMilliseconds / 1000;
    return delta > 0 ? delta : 0;
  }
}
