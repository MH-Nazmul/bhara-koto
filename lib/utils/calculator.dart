import 'dart:math' as math;

import '../models/fare_config.dart';

/// The result of one fare calculation — everything the UI needs to both show
/// the number *and* explain it.
class FareBreakdown {
  const FareBreakdown({
    required this.distanceMeters,
    required this.ratePerKm,
    required this.minFare,
    required this.metered,
    required this.total,
    required this.minimumApplied,
  });

  final double distanceMeters;
  final double ratePerKm;
  final double minFare;

  /// distance × rate, before the minimum-fare floor is applied.
  final double metered;

  /// What the passenger actually pays.
  final double total;

  /// True when the metered amount was below the floor, so [total] == [minFare].
  final bool minimumApplied;

  double get distanceKm => distanceMeters / 1000;
}

/// Fare maths. Deliberately pure and dependency-free so it can be unit tested
/// without a GPS, a network or a widget tree.
abstract final class FareCalculator {
  /// `fare = max(distance_km × rate_per_km, min_fare)` for the given profile's
  /// [rate].
  ///
  /// Money is rounded to 2 decimals at the end (never mid-way) so the displayed
  /// number and the arithmetic behind it can't disagree.
  static FareBreakdown compute({
    required double distanceMeters,
    required FareRate rate,
  }) {
    final safeDistance = distanceMeters.isFinite && distanceMeters > 0 ? distanceMeters : 0.0;
    final metered = _round2((safeDistance / 1000) * rate.ratePerKm);
    final total = _round2(math.max(metered, rate.minFare));

    return FareBreakdown(
      distanceMeters: safeDistance,
      ratePerKm: rate.ratePerKm,
      minFare: rate.minFare,
      metered: metered,
      total: total,
      minimumApplied: metered < rate.minFare,
    );
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;
}
