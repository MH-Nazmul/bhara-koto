import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fare_config.dart';
import '../models/overcharge_report_model.dart';
import '../models/trip_history_model.dart';
import '../utils/constants.dart';

/// Thin, synchronous-after-init wrapper over SharedPreferences.
///
/// Everything the app must survive a reboot with lives here: the last known
/// rates, any manual override, the Gist URL, theme and language.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async =>
      StorageService._(await SharedPreferences.getInstance());

  // ---------------------------------------------------------------- rates ---

  /// The last successfully fetched remote config, returned as [FareSource.cached]
  /// because at read time it is exactly that: a saved copy.
  FareConfig? readRemoteConfig() => _readConfig(PrefKeys.remoteConfig, FareSource.cached);

  Future<void> writeRemoteConfig(FareConfig config) =>
      _writeConfig(PrefKeys.remoteConfig, config);

  FareConfig? readManualConfig() => _readConfig(PrefKeys.manualConfig, FareSource.manual);

  Future<void> writeManualConfig(FareConfig config) async {
    await _writeConfig(PrefKeys.manualConfig, config);
    await _prefs.setBool(PrefKeys.manualEnabled, true);
  }

  bool get manualEnabled => _prefs.getBool(PrefKeys.manualEnabled) ?? false;

  Future<void> setManualEnabled(bool value) =>
      _prefs.setBool(PrefKeys.manualEnabled, value);

  // -------------------------------------------------------------- profile ---

  /// Which kind of bus the passenger last rode — remembered so the common case
  /// is zero taps.
  FareProfile get fareProfile => FareProfile.fromKey(_prefs.getString(PrefKeys.fareProfile));

  Future<void> setFareProfile(FareProfile profile) =>
      _prefs.setString(PrefKeys.fareProfile, profile.key);

  // ----------------------------------------------------------------- sync ---

  DateTime? get lastSyncedAt {
    final raw = _prefs.getString(PrefKeys.lastSyncedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastSyncedAt(DateTime time) =>
      _prefs.setString(PrefKeys.lastSyncedAt, time.toIso8601String());

  // ------------------------------------------------------------ appearance ---

  ThemeMode get themeMode => switch (_prefs.getString(PrefKeys.themeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(PrefKeys.themeMode, mode.name);

  /// `null` means "follow the device language".
  String? get languageCode {
    final code = _prefs.getString(PrefKeys.languageCode);
    return (code == null || code.isEmpty) ? null : code;
  }

  Future<void> setLanguageCode(String? code) => code == null
      ? _prefs.remove(PrefKeys.languageCode)
      : _prefs.setString(PrefKeys.languageCode, code);

  // -------------------------------------------------------------- history ---

  List<TripHistoryItem> readTripHistory() {
    final raw = _prefs.getString(PrefKeys.tripHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((item) => TripHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> addTripHistoryItem(TripHistoryItem item) async {
    final history = readTripHistory();
    history.insert(0, item); // newest first
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(PrefKeys.tripHistory, encoded);
  }

  Future<void> clearTripHistory() async {
    await _prefs.remove(PrefKeys.tripHistory);
  }

  // --------------------------------------------------- overcharge reports ---

  List<OverchargeReport> readOverchargeReports() {
    final raw = _prefs.getString(PrefKeys.overchargeReports);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((item) => OverchargeReport.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> addOverchargeReport(OverchargeReport report) async {
    final reports = readOverchargeReports();
    reports.insert(0, report);
    final encoded = jsonEncode(reports.map((e) => e.toJson()).toList());
    await _prefs.setString(PrefKeys.overchargeReports, encoded);
  }

  FareConfig? _readConfig(String key, FareSource source) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final fetchedAt = DateTime.tryParse(decoded['fetched_at'] as String? ?? '');
      return FareConfig.fromJson(decoded, source: source, fetchedAt: fetchedAt);
    } on Object {
      // Corrupt entry (hand-edited, or written by an older build) — drop it
      // rather than blocking startup.
      return null;
    }
  }

  Future<void> _writeConfig(String key, FareConfig config) =>
      _prefs.setString(key, jsonEncode(config.toJson()));
}
