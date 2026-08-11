/// App-wide constants: remote config location, storage keys and the GPS
/// tuning numbers that decide how forgiving the meter is.
library;

/// ---------------------------------------------------------------------------
/// REMOTE CONFIG
/// ---------------------------------------------------------------------------
/// The fare rules live in a GitHub Gist so a government revision reaches every
/// phone without shipping a new build. This is baked into the binary on
/// purpose — passengers never see or set it; you just edit the Gist.
///
/// Note there is **no revision hash** between `raw/` and the filename. GitHub's
/// "Raw" button hands you a URL pinned to one commit, which would keep serving
/// today's rates forever. Stripping the hash makes it always serve the latest.
const String kFareRulesUrl =
    'https://gist.githubusercontent.com/MH-Nazmul/b1b9308147c33a231133805d39f2150a/raw/fare_rules.json';

/// How long to wait for the Gist before giving up and using cached rates.
const Duration kConfigFetchTimeout = Duration(seconds: 8);

/// How often the app re-reads the Gist. Fares are revised a handful of times a
/// year, so checking once a day is plenty — and it means the passenger never
/// has to think about syncing.
const Duration kConfigRefreshInterval = Duration(hours: 24);

/// Shown on the About section. Keep in step with `version:` in pubspec.yaml.
const String kAppVersion = '1.0.0';

/// ---------------------------------------------------------------------------
/// FALLBACK FARES
/// ---------------------------------------------------------------------------
/// Used only until the Gist answers for the first time. Bangladesh charges two
/// different per-km rates, so both need a fallback.
///
/// These mirror the live Gist so a first launch with no network still meters
/// correctly. The Gist stays the source of truth.
const double kFallbackLocalRatePerKm = 2.53;
const double kFallbackLocalMinFare = 10.0;
const double kFallbackIntercityRatePerKm = 2.43;
const double kFallbackIntercityMinFare = 10.0;

/// ---------------------------------------------------------------------------
/// STORAGE KEYS
/// ---------------------------------------------------------------------------
abstract final class PrefKeys {
  static const remoteConfig = 'config.remote';
  static const manualConfig = 'config.manual';
  static const manualEnabled = 'config.manual_enabled';
  static const lastSyncedAt = 'config.last_synced_at';
  static const fareProfile = 'fare.profile';
  static const themeMode = 'ui.theme_mode';
  static const languageCode = 'ui.language_code';
  static const tripHistory = 'trip.history';
  static const overchargeReports = 'overcharge.reports';
}

/// ---------------------------------------------------------------------------
/// GPS TUNING
/// ---------------------------------------------------------------------------
/// These are the knobs that separate "a fare meter" from "a random number
/// generator". A parked phone still reports positions that wander by a few
/// metres; without filtering, a 20 minute wait would silently add a kilometre.
abstract final class GpsTuning {
  /// Ask the OS for a new fix only after this much movement (battery saver).
  static const int distanceFilterMeters = 5;

  /// Upper bound on how often Android delivers a fix.
  static const Duration androidInterval = Duration(seconds: 4);

  /// Fixes less precise than this are thrown away entirely.
  static const double maxAccuracyMeters = 40;

  /// A hop shorter than this is treated as GPS drift, not travel.
  /// The anchor point is kept, so genuine slow movement still accumulates.
  static const double minSegmentMeters = 8;

  /// A hop implying a speed above this is a teleport glitch — re-anchor, skip.
  static const double maxPlausibleSpeedMps = 45; // ≈ 162 km/h

  /// Below this speed the bus counts as "not moving".
  static const double idleSpeedMps = 1.4; // ≈ 5 km/h

  /// No real movement for this long ⇒ highlight the fare (probably arrived).
  static const Duration idleTimeout = Duration(seconds: 40);

  /// Warn about signal quality above this accuracy radius.
  static const double weakSignalMeters = 25;
}
