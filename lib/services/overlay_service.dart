import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fare_config.dart';
import '../models/trip_history_model.dart';
import '../services/location_service.dart';
import '../state/trip_state.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';

/// Platform & Overlay Service for vehicle motion detection and system overlay popup.
class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.bharakoto.app/overlay');

  /// Requests SYSTEM_ALERT_WINDOW (Display over other apps) permission on Android.
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestPermission') ?? true;
      return granted;
    } on PlatformException {
      return true; // Fallback / Simulated in Flutter layer
    }
  }

  /// Checks whether overlay permission is active.
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool isGranted = await _channel.invokeMethod('checkPermission') ?? true;
      return isGranted;
    } on PlatformException {
      return true;
    }
  }

  /// Opens the system app details settings page for the user to grant background location/notifications.
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException {
      // Fallback
    }
  }

  /// Listens for Start/Stop trip events triggered from inside the native floating overlay widget.
  static void listenNativeOverlayEvents({
    required VoidCallback onStartTrip,
    required VoidCallback onStopTrip,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNativeStartTrip') {
        onStartTrip();
      } else if (call.method == 'onNativeStopTrip') {
        onStopTrip();
      }
    });
  }

  /// Updates the live meter readout on the native system floating overlay.
  static Future<void> updateNativeMeterOverlay({
    required String fareTotal,
    required String distanceKm,
    required String speedKmh,
    String lang = 'en',
  }) async {
    try {
      await _channel.invokeMethod('updateNativeMeterOverlay', {
        'fareTotal': fareTotal,
        'distanceKm': distanceKm,
        'speedKmh': speedKmh,
        'lang': lang,
      });
    } on PlatformException {
      // Fallback
    }
  }

  /// Dismisses the native floating overlay.
  static Future<void> dismissNativeOverlay() async {
    try {
      await _channel.invokeMethod('dismissNativeOverlay');
    } on PlatformException {
      // Fallback
    }
  }

  /// Starts native Kotlin LocationListener in background OS for motion detection.
  static Future<void> startNativeMotionMonitoring(double thresholdKmh, [String lang = 'en']) async {
    try {
      await _channel.invokeMethod('startNativeMotionMonitoring', {
        'thresholdKmh': thresholdKmh,
        'lang': lang,
      });
    } on PlatformException {
      // Fallback
    }
  }

  /// Stops native Kotlin LocationListener.
  static Future<void> stopNativeMotionMonitoring() async {
    try {
      await _channel.invokeMethod('stopNativeMotionMonitoring');
    } on PlatformException {
      // Fallback
    }
  }

  /// Triggers a native system floating overlay window that displays over other apps.
  static Future<void> showNativeOverlay({
    required double currentSpeedKmh,
    required double thresholdKmh,
    String lang = 'en',
  }) async {
    try {
      await _channel.invokeMethod('showNativeOverlay', {
        'speedKmh': currentSpeedKmh,
        'thresholdKmh': thresholdKmh,
        'lang': lang,
      });
    } on PlatformException {
      // Fallback
    }
  }

  /// Triggers a high priority heads-up notification with action button.
  static Future<void> showNotification({
    required String title,
    required String body,
    String lang = 'en',
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'lang': lang,
      });
    } on PlatformException {
      // Fallback
    }
  }

  /// Trigger floating overlay dialog when speed exceeds threshold.
  static void showFloatingPopup({
    required BuildContext context,
    required double currentSpeedKmh,
    required double thresholdKmh,
    required VoidCallback onStartJourneyPressed,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'OverlayPopup',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        final bk = ctx.bk;
        final text = Theme.of(ctx).textTheme;
        final isBangla = Localizations.localeOf(ctx).languageCode == 'bn';

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bk.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bk.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: bk.accent,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isBangla ? 'যানবাহনে গতির শনাক্তকরণ!' : 'Vehicle Movement Detected!',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isBangla
                      ? 'আপনার বর্তমান গতি ${currentSpeedKmh.toStringAsFixed(1)} কিমি/ঘণ্টা (সীমা: ${thresholdKmh.toStringAsFixed(1)} কিমি/ঘণ্টা)।\nআপনি কি ভাড়া গণনা শুরু করতে চান?'
                      : 'Speed: ${currentSpeedKmh.toStringAsFixed(1)} km/h (Threshold: ${thresholdKmh.toStringAsFixed(1)} km/h).\nWould you like to start the fare meter?',
                  style: text.bodySmall?.copyWith(color: bk.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bk.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      isBangla ? 'যাত্রা শুরু করবেন?' : 'Start Journey?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onStartJourneyPressed();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
