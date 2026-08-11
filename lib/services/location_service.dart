import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/constants.dart';

/// Everything that can stand between the app and a GPS fix.
enum LocationReadiness {
  ready,
  serviceDisabled,
  denied,
  deniedForever,
}

/// Owns the platform side of GPS: permissions, the settings used for the
/// stream, and the stream itself. It counts nothing — accumulating distance is
/// [TripState]'s job, which keeps this class trivially replaceable in tests.
class LocationService {
  /// Checks that location is switched on and that we hold permission,
  /// prompting the user once if we don't.
  Future<LocationReadiness> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationReadiness.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.denied => LocationReadiness.denied,
      LocationPermission.deniedForever => LocationReadiness.deniedForever,
      _ => LocationReadiness.ready,
    };
  }

  /// A filtered position stream tuned for a bus ride: high accuracy, but only
  /// woken every few seconds / metres so a long trip doesn't flatten the phone.
  ///
  /// Stream used during standby monitoring to keep background GPS awake when app is minimized.
  Stream<Position> standbyPositions({
    required String notificationTitle,
    required String notificationText,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _settingsFor(
        notificationTitle,
        notificationText,
        distanceFilter: 0,
        interval: const Duration(seconds: 1),
      ),
    );
  }

  /// On Android a foreground-service notification keeps the meter alive while
  /// the passenger's screen is off; [notificationTitle]/[notificationText] are
  /// passed in already localised.
  Stream<Position> positions({
    required String notificationTitle,
    required String notificationText,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _settingsFor(notificationTitle, notificationText),
    );
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Straight-line (Haversine) metres between two fixes.
  static double metersBetween(Position a, Position b) => Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );

  LocationSettings _settingsFor(
    String title,
    String text, {
    int? distanceFilter,
    Duration? interval,
  }) {
    final filter = distanceFilter ?? GpsTuning.distanceFilterMeters;
    final intervalDuration = interval ?? GpsTuning.androidInterval;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: filter,
        intervalDuration: intervalDuration,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: title,
          notificationText: text,
          notificationChannelName: 'Fare meter',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: filter,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: filter,
    );
  }
}
