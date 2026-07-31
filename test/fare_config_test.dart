import 'package:bhara_koto/models/fare_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FareConfig.fromJson', () {
    test('reads the two-profile shape', () {
      final config = FareConfig.fromJson({
        'version': '2026-07',
        'fares': {
          'local': {'rate_per_km': 2.53, 'min_fare': 10.0},
          'intercity': {'rate_per_km': 2.15, 'min_fare': 12.0},
        },
        'notice_en': 'Revised on 1 July.',
      });

      expect(config.rateFor(FareProfile.local).ratePerKm, 2.53);
      expect(config.rateFor(FareProfile.local).minFare, 10);
      expect(config.rateFor(FareProfile.intercity).ratePerKm, 2.15);
      expect(config.rateFor(FareProfile.intercity).minFare, 12);
      expect(config.version, '2026-07');
      expect(config.source, FareSource.remote);
    });

    test('a legacy single-rate file still works and covers both profiles', () {
      final config = FareConfig.fromJson({'rate_per_km': 2.53, 'min_fare': 10.0});

      expect(config.local.ratePerKm, 2.53);
      expect(config.intercity.ratePerKm, 2.53);
    });

    test('a half-filled "fares" object falls back rather than failing', () {
      final config = FareConfig.fromJson({
        'fares': {
          'local': {'rate_per_km': 3.0, 'min_fare': 10.0},
        },
      });

      expect(config.local.ratePerKm, 3.0);
      expect(config.intercity.ratePerKm, 3.0);
    });

    test('survives a hand-edited Gist: camelCase, ints and quoted numbers', () {
      final config = FareConfig.fromJson({
        'fares': {
          'local': {'ratePerKm': '2.75', 'min_fare': 12},
          'intercity': {'rate': 2, 'minimum_fare': 8},
        },
      });

      expect(config.local.ratePerKm, 2.75);
      expect(config.local.minFare, 12);
      expect(config.intercity.ratePerKm, 2);
      expect(config.intercity.minFare, 8);
    });

    test('rejects a missing or zero rate rather than metering everything free', () {
      expect(() => FareConfig.fromJson({'min_fare': 10}), throwsFormatException);
      expect(
        () => FareConfig.fromJson({
          'fares': {
            'local': {'rate_per_km': 0, 'min_fare': 10},
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects an empty "fares" object', () {
      expect(() => FareConfig.fromJson({'fares': <String, dynamic>{}}), throwsFormatException);
    });

    test('rejects a negative minimum fare', () {
      expect(
        () => FareConfig.fromJson({'rate_per_km': 2.5, 'min_fare': -1}),
        throwsFormatException,
      );
    });

    test('round-trips through JSON, keeping both profiles distinct', () {
      const original = FareConfig(
        local: FareRate(ratePerKm: 2.53, minFare: 10),
        intercity: FareRate(ratePerKm: 2.15, minFare: 12),
        version: 'x',
      );
      final restored = FareConfig.fromJson(original.toJson());

      expect(restored.sameRatesAs(original), isTrue);
      expect(restored.intercity.ratePerKm, 2.15);
      expect(restored.version, 'x');
    });
  });

  group('FareConfig', () {
    const config = FareConfig(
      local: FareRate(ratePerKm: 2.53, minFare: 10),
      intercity: FareRate(ratePerKm: 2.15, minFare: 12),
    );

    test('withRate replaces one profile and leaves the other alone', () {
      final edited = config.withRate(
        FareProfile.intercity,
        const FareRate(ratePerKm: 3.0, minFare: 15),
        source: FareSource.manual,
      );

      expect(edited.intercity.ratePerKm, 3.0);
      expect(edited.local, config.local);
      expect(edited.source, FareSource.manual);
    });

    test('sameRatesAs notices a change in either profile', () {
      const sameNumbersNewLabel = FareConfig(
        local: FareRate(ratePerKm: 2.53, minFare: 10),
        intercity: FareRate(ratePerKm: 2.15, minFare: 12),
        version: 'july',
      );
      final onlyIntercityMoved =
          config.withRate(FareProfile.intercity, const FareRate(ratePerKm: 2.2, minFare: 12));

      expect(config.sameRatesAs(sameNumbersNewLabel), isTrue);
      expect(config.sameRatesAs(onlyIntercityMoved), isFalse);
    });

    test('picks the notice for the active language and falls back', () {
      const both = FareConfig(
        local: FareRate(ratePerKm: 2, minFare: 5),
        intercity: FareRate(ratePerKm: 2, minFare: 5),
        noticeEn: 'English notice',
        noticeBn: 'বাংলা নোটিশ',
      );
      expect(both.noticeFor('bn'), 'বাংলা নোটিশ');
      expect(both.noticeFor('en'), 'English notice');

      const englishOnly = FareConfig(
        local: FareRate(ratePerKm: 2, minFare: 5),
        intercity: FareRate(ratePerKm: 2, minFare: 5),
        noticeEn: 'Only English',
      );
      expect(englishOnly.noticeFor('bn'), 'Only English');
      expect(config.noticeFor('bn'), isNull);
    });
  });

  group('FareProfile', () {
    test('round-trips through its storage key and defaults to local', () {
      expect(FareProfile.fromKey('intercity'), FareProfile.intercity);
      expect(FareProfile.fromKey('local'), FareProfile.local);
      expect(FareProfile.fromKey(null), FareProfile.local);
      expect(FareProfile.fromKey('nonsense'), FareProfile.local);
    });
  });
}
