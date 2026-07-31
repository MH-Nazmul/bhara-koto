/// Locale-aware number rendering.
///
/// Everything is formatted with plain Dart first and then transliterated into
/// Bengali digits when the UI language is Bangla, so the app needs no extra
/// locale data at startup and a "৳২৫.৩০" never falls back to "৳25.30" halfway.
abstract final class Fmt {
  static const List<String> _bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  /// Converts ASCII digits to the script of [languageCode].
  static String digits(String input, String languageCode) {
    if (languageCode != 'bn') return input;
    final buffer = StringBuffer();
    for (final unit in input.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        buffer.write(_bengaliDigits[unit - 0x30]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  /// A fixed-decimal number, e.g. `12.40` → `১২.৪০` in Bangla.
  static String decimal(double value, String languageCode, {int places = 2}) {
    final safe = value.isFinite ? value : 0.0;
    return digits(safe.toStringAsFixed(places), languageCode);
  }

  /// Fare amounts always show two decimals — money should not shift width.
  static String money(double value, String languageCode) =>
      decimal(value, languageCode, places: 2);

  /// Distance: metres below 1 km would read as `0.00`, so keep 2 decimals but
  /// let the caller show the unit.
  static String distanceKm(double meters, String languageCode) =>
      decimal(meters / 1000, languageCode, places: 2);

  static String speedKmh(double metersPerSecond, String languageCode) =>
      decimal(metersPerSecond * 3.6, languageCode, places: 0);

  /// `mm:ss` under an hour, `h:mm:ss` beyond it.
  static String duration(Duration d, String languageCode) {
    final seconds = d.inSeconds.clamp(0, 359999);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final text = h > 0
        ? '$h:${_two(m)}:${_two(s)}'
        : '${_two(m)}:${_two(s)}';
    return digits(text, languageCode);
  }

  /// Trims trailing zeros so a rate reads `2.53` and `3` rather than `3.00`.
  static String rate(double value, String languageCode) {
    var text = value.toStringAsFixed(2);
    if (text.endsWith('0')) text = text.substring(0, text.length - 1);
    if (text.endsWith('0')) text = text.substring(0, text.length - 1);
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return digits(text, languageCode);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
