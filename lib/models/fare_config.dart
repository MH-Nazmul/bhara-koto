import '../utils/constants.dart';

/// Bangladesh charges two different per-km rates depending on the kind of
/// service, so the passenger has to tell the meter which bus they are on.
enum FareProfile {
  /// Inside one district — city and local routes.
  local,

  /// Between districts — long-distance coaches.
  intercity;

  /// The key used in `fare_rules.json` and in local storage.
  String get key => name;

  static FareProfile fromKey(String? key) =>
      FareProfile.values.firstWhere((p) => p.key == key, orElse: () => FareProfile.local);
}

/// Where the currently active rates came from. Shown to the user so they always
/// know whether they are looking at live, cached or self-entered numbers.
enum FareSource { remote, cached, manual, fallback }

/// One profile's numbers: what you pay per kilometre and the floor below which
/// the fare never drops.
class FareRate {
  const FareRate({required this.ratePerKm, required this.minFare});

  final double ratePerKm;
  final double minFare;

  /// Tolerant parser: numbers may arrive as ints, doubles or quoted strings,
  /// under snake_case or camelCase — a hand-edited Gist shouldn't crash the app.
  factory FareRate.fromJson(Map<String, dynamic> json, {required String label}) {
    final rate = _readNumber(json, const ['rate_per_km', 'ratePerKm', 'rate']);
    final min = _readNumber(json, const ['min_fare', 'minFare', 'minimum_fare']);

    if (rate == null || rate <= 0) {
      throw FormatException('fare_rules.json: "$label.rate_per_km" missing or not a positive number');
    }
    if (min == null || min < 0) {
      throw FormatException('fare_rules.json: "$label.min_fare" missing or negative');
    }
    return FareRate(ratePerKm: rate, minFare: min);
  }

  Map<String, dynamic> toJson() => {'rate_per_km': ratePerKm, 'min_fare': minFare};

  @override
  bool operator ==(Object other) =>
      other is FareRate && other.ratePerKm == ratePerKm && other.minFare == minFare;

  @override
  int get hashCode => Object.hash(ratePerKm, minFare);
}

/// The fare rules the meter runs on — the shape of `fare_rules.json`.
///
/// ```json
/// {
///   "version": "2026-07",
///   "updated_at": "2026-07-01",
///   "fares": {
///     "local":     { "rate_per_km": 2.53, "min_fare": 10.0 },
///     "intercity": { "rate_per_km": 2.15, "min_fare": 10.0 }
///   },
///   "notice_en": "Rates revised by BRTA on 1 July.",
///   "notice_bn": "১ জুলাই বিআরটিএ ভাড়া সংশোধন করেছে।"
/// }
/// ```
///
/// A flat `{"rate_per_km": …, "min_fare": …}` file (the single-rate format) is
/// still accepted and applies to both profiles, so an older Gist keeps working.
class FareConfig {
  const FareConfig({
    required this.local,
    required this.intercity,
    this.source = FareSource.fallback,
    this.detectVehicleSpeedKmh = 15.0,
    this.version,
    this.updatedAt,
    this.noticeEn,
    this.noticeBn,
    this.fetchedAt,
  });

  final FareRate local;
  final FareRate intercity;
  final FareSource source;

  /// Speed threshold in km/h to auto-detect vehicle movement and show popup.
  final double detectVehicleSpeedKmh;

  /// Free-form label from the Gist, e.g. "2026-07" — handy for spotting stale
  /// rules at a glance.
  final String? version;
  final DateTime? updatedAt;
  final String? noticeEn;
  final String? noticeBn;

  /// When this copy was pulled/loaded, set by the app rather than the JSON.
  final DateTime? fetchedAt;

  /// Used before storage or network have said anything.
  static const FareConfig fallback = FareConfig(
    local: FareRate(ratePerKm: kFallbackLocalRatePerKm, minFare: kFallbackLocalMinFare),
    intercity: FareRate(
      ratePerKm: kFallbackIntercityRatePerKm,
      minFare: kFallbackIntercityMinFare,
    ),
    detectVehicleSpeedKmh: 15.0,
  );

  FareRate rateFor(FareProfile profile) => switch (profile) {
        FareProfile.local => local,
        FareProfile.intercity => intercity,
      };

  factory FareConfig.fromJson(
    Map<String, dynamic> json, {
    FareSource source = FareSource.remote,
    DateTime? fetchedAt,
  }) {
    final fares = json['fares'];

    final FareRate localRate;
    final FareRate intercityRate;

    if (fares is Map<String, dynamic>) {
      // Either profile may be omitted; the other then covers both, which keeps
      // a half-filled Gist usable instead of fatal.
      final localJson = fares[FareProfile.local.key];
      final intercityJson = fares[FareProfile.intercity.key];

      if (localJson is! Map<String, dynamic> && intercityJson is! Map<String, dynamic>) {
        throw const FormatException(
          'fare_rules.json: "fares" must contain a "local" and/or "intercity" object',
        );
      }
      localRate = localJson is Map<String, dynamic>
          ? FareRate.fromJson(localJson, label: 'fares.local')
          : FareRate.fromJson(intercityJson! as Map<String, dynamic>, label: 'fares.intercity');
      intercityRate = intercityJson is Map<String, dynamic>
          ? FareRate.fromJson(intercityJson, label: 'fares.intercity')
          : localRate;
    } else {
      // Legacy flat format — one rate for everything.
      final flat = FareRate.fromJson(json, label: 'root');
      localRate = flat;
      intercityRate = flat;
    }

    double speedThreshold = 15.0;
    final detectJson = json['detect_vehicle'];
    if (detectJson is Map<String, dynamic>) {
      speedThreshold = _readNumber(detectJson, const ['speed_threshold_kmh', 'speedThresholdKmh', 'speed_threshold']) ?? 15.0;
    } else if (json.containsKey('detect_vehicle_speed')) {
      speedThreshold = _readNumber(json, const ['detect_vehicle_speed']) ?? 15.0;
    }

    return FareConfig(
      local: localRate,
      intercity: intercityRate,
      source: source,
      detectVehicleSpeedKmh: speedThreshold,
      version: _readString(json, const ['version']),
      updatedAt: DateTime.tryParse(_readString(json, const ['updated_at', 'updatedAt']) ?? ''),
      noticeEn: _readString(json, const ['notice_en', 'noticeEn', 'notice']),
      noticeBn: _readString(json, const ['notice_bn', 'noticeBn']),
      fetchedAt: fetchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'fares': {
          FareProfile.local.key: local.toJson(),
          FareProfile.intercity.key: intercity.toJson(),
        },
        'detect_vehicle': {
          'speed_threshold_kmh': detectVehicleSpeedKmh,
        },
        if (version != null) 'version': version,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (noticeEn != null) 'notice_en': noticeEn,
        if (noticeBn != null) 'notice_bn': noticeBn,
        if (fetchedAt != null) 'fetched_at': fetchedAt!.toIso8601String(),
      };

  /// Replaces one profile's numbers, keeping everything else — used when the
  /// user overrides a rate by hand.
  FareConfig withRate(FareProfile profile, FareRate rate, {FareSource? source}) => FareConfig(
        local: profile == FareProfile.local ? rate : local,
        intercity: profile == FareProfile.intercity ? rate : intercity,
        source: source ?? this.source,
        version: version,
        updatedAt: updatedAt,
        noticeEn: noticeEn,
        noticeBn: noticeBn,
        fetchedAt: fetchedAt,
      );

  /// Ignores metadata — only asks "would any passenger pay a different amount?".
  bool sameRatesAs(FareConfig other) => local == other.local && intercity == other.intercity;

  /// The notice for the active UI language, falling back to the other one.
  String? noticeFor(String languageCode) {
    final preferred = languageCode == 'bn' ? noticeBn : noticeEn;
    final other = languageCode == 'bn' ? noticeEn : noticeBn;
    final picked = (preferred?.trim().isNotEmpty ?? false) ? preferred : other;
    return (picked?.trim().isNotEmpty ?? false) ? picked!.trim() : null;
  }
}

double? _readNumber(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
