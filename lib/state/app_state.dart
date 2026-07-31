import 'package:flutter/material.dart';

import '../models/fare_config.dart';
import '../services/config_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

enum SyncStatus { idle, syncing, success, unchanged, failed }

/// Owns everything that outlives a single trip: the active fare rules, which
/// kind of bus they apply to, and the user's theme / language choices.
///
/// Startup contract (blueprint step 2): local storage answers instantly, the
/// network answers later and only if it succeeds.
class AppState extends ChangeNotifier {
  AppState({required StorageService storage, required ConfigService configService})
      : _storage = storage,
        _config = configService;

  final StorageService _storage;
  final ConfigService _config;

  FareConfig? _remote;
  FareConfig? _manual;
  bool _manualEnabled = false;

  SyncStatus _syncStatus = SyncStatus.idle;
  ConfigFailure? _lastFailure;
  DateTime? _lastSyncedAt;

  late FareProfile _profile;
  late ThemeMode _themeMode;
  String? _languageCode;

  // --------------------------------------------------------------- getters ---

  /// The rules the meter runs on right now — both profiles.
  FareConfig get config {
    if (_manualEnabled && _manual != null) return _manual!;
    return _remote ?? FareConfig.fallback;
  }

  /// Which kind of bus the passenger is on.
  FareProfile get profile => _profile;

  /// The numbers actually being charged, i.e. [config] narrowed to [profile].
  FareRate get activeRate => config.rateFor(_profile);

  /// What the badge should say. Derived from how recently the rates were
  /// *verified*, not from whether this particular launch happened to fetch —
  /// with the daily throttle most launches skip the network, and calling those
  /// rates "Offline" would be a lie.
  FareSource get source {
    if (_manualEnabled && _manual != null) return FareSource.manual;
    if (_remote == null) return FareSource.fallback;

    final last = _lastSyncedAt;
    final verifiedRecently =
        last != null && DateTime.now().difference(last) < kConfigRefreshInterval;
    return verifiedRecently ? FareSource.remote : FareSource.cached;
  }
  bool get manualEnabled => _manualEnabled;
  SyncStatus get syncStatus => _syncStatus;
  ConfigFailure? get lastFailure => _lastFailure;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  ThemeMode get themeMode => _themeMode;
  String? get languageCode => _languageCode;
  Locale? get locale => _languageCode == null ? null : Locale(_languageCode!);

  // ------------------------------------------------------------- lifecycle ---

  /// Reads local state synchronously, then kicks off a background sync. Never
  /// blocks the first frame on the network.
  void bootstrap() {
    _remote = _storage.readRemoteConfig();
    _manual = _storage.readManualConfig();
    _manualEnabled = _storage.manualEnabled && _manual != null;
    _profile = _storage.fareProfile;
    _themeMode = _storage.themeMode;
    _languageCode = _storage.languageCode;
    _lastSyncedAt = _storage.lastSyncedAt;
    notifyListeners();

    syncIfStale();
  }

  /// Refreshes the rates at most once a day. Fares move a few times a year, so
  /// hitting the Gist on every launch would burn data for nothing — and this is
  /// why there is no Sync button: the app keeps itself current on its own.
  Future<void> syncIfStale() async {
    final last = _lastSyncedAt;
    if (last != null && DateTime.now().difference(last) < kConfigRefreshInterval) {
      return;
    }
    await sync();
  }

  /// Pulls `fare_rules.json`. Failure is deliberately quiet: the cached rates
  /// stay in place and the passenger is never shown a network error — the
  /// source badge simply keeps reading "Offline".
  Future<void> sync() async {
    if (_syncStatus == SyncStatus.syncing) return;
    _syncStatus = SyncStatus.syncing;
    _lastFailure = null;
    notifyListeners();

    try {
      final fetched = await _config.fetch(kFareRulesUrl);
      final changed = _remote == null || !_remote!.sameRatesAs(fetched);

      _remote = fetched;
      _lastSyncedAt = fetched.fetchedAt ?? DateTime.now();
      await _storage.writeRemoteConfig(fetched);
      await _storage.setLastSyncedAt(_lastSyncedAt!);

      _syncStatus = changed ? SyncStatus.success : SyncStatus.unchanged;
    } on ConfigException catch (error) {
      _lastFailure = error.failure;
      _syncStatus = SyncStatus.failed;
    } finally {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- config ---

  Future<void> setProfile(FareProfile profile) async {
    if (profile == _profile) return;
    _profile = profile;
    notifyListeners();
    await _storage.setFareProfile(profile);
  }

  /// Overrides one profile's numbers by hand, leaving the other profile as it
  /// is. Used to bridge the gap between a fare revision and the Gist catching
  /// up.
  Future<void> saveManualRate(FareProfile profile, FareRate rate) async {
    final manual = config.withRate(profile, rate, source: FareSource.manual);
    _manual = manual;
    _manualEnabled = true;
    await _storage.writeManualConfig(manual);
    notifyListeners();
  }

  /// Hands control back to the server copy. The manual numbers are kept on disk
  /// so switching back later is one tap.
  Future<void> useServerRates() async {
    _manualEnabled = false;
    await _storage.setManualEnabled(false);
    notifyListeners();
    await sync();
  }

  // ------------------------------------------------------------ appearance ---

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.setThemeMode(mode);
  }

  /// `null` follows the device language.
  Future<void> setLanguage(String? code) async {
    if (code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
    await _storage.setLanguageCode(code);
  }
}
