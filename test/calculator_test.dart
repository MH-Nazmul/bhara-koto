import 'package:bhara_koto/models/fare_config.dart';
import 'package:bhara_koto/utils/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rate = FareRate(ratePerKm: 2.53, minFare: 10);

  group('FareCalculator', () {
    test('charges distance × rate once past the minimum', () {
      final fare = FareCalculator.compute(distanceMeters: 12000, rate: rate);

      expect(fare.metered, 30.36);
      expect(fare.total, 30.36);
      expect(fare.minimumApplied, isFalse);
      expect(fare.distanceKm, 12);
    });

    test('floors short trips at the minimum fare', () {
      final fare = FareCalculator.compute(distanceMeters: 1500, rate: rate);

      expect(fare.metered, 3.8); // 1.5 km × 2.53 = 3.795, rounded
      expect(fare.total, 10);
      expect(fare.minimumApplied, isTrue);
    });

    test('treats the boundary as met, not below', () {
      // 3.9526 km × 2.53 ≈ 10.0 — exactly the minimum, so no floor is applied.
      final fare = FareCalculator.compute(distanceMeters: 3952.6, rate: rate);

      expect(fare.total, 10);
      expect(fare.minimumApplied, isFalse);
    });

    test('a trip that never moved still costs the minimum', () {
      final fare = FareCalculator.compute(distanceMeters: 0, rate: rate);

      expect(fare.metered, 0);
      expect(fare.total, 10);
      expect(fare.minimumApplied, isTrue);
    });

    test('ignores garbage distances instead of producing NaN fares', () {
      final fare = FareCalculator.compute(distanceMeters: double.nan, rate: rate);

      expect(fare.distanceMeters, 0);
      expect(fare.total, 10);
    });

    test('rounds money to two decimals', () {
      final fare = FareCalculator.compute(distanceMeters: 7333, rate: rate);

      // 7.333 × 2.53 = 18.55249
      expect(fare.total, 18.55);
    });
  });
}
