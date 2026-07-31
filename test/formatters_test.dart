import 'package:bhara_koto/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt', () {
    test('leaves English numerals alone', () {
      expect(Fmt.money(25.3, 'en'), '25.30');
      expect(Fmt.distanceKm(1234, 'en'), '1.23');
    });

    test('renders Bangla numerals so the whole screen stays in one script', () {
      expect(Fmt.money(25.3, 'bn'), '২৫.৩০');
      expect(Fmt.distanceKm(1234, 'bn'), '১.২৩');
      expect(Fmt.speedKmh(10, 'bn'), '৩৬');
    });

    test('keeps non-digits untouched while transliterating', () {
      expect(Fmt.digits('±12 m', 'bn'), '±১২ m');
    });

    test('drops trailing zeros from rates but keeps meaningful decimals', () {
      expect(Fmt.rate(2.53, 'en'), '2.53');
      expect(Fmt.rate(3.0, 'en'), '3');
      expect(Fmt.rate(2.50, 'en'), '2.5');
    });

    test('shows hours only once a trip needs them', () {
      expect(Fmt.duration(const Duration(seconds: 65), 'en'), '01:05');
      expect(Fmt.duration(const Duration(hours: 1, minutes: 2, seconds: 3), 'en'), '1:02:03');
      expect(Fmt.duration(const Duration(minutes: 5), 'bn'), '০৫:০০');
    });

    test('clamps a negative duration instead of printing a minus sign', () {
      expect(Fmt.duration(const Duration(seconds: -30), 'en'), '00:00');
    });
  });
}
