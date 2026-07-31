import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fare_config.dart';
import '../utils/constants.dart';

/// Why a sync attempt failed, so the UI can say something more useful than
/// "error".
enum ConfigFailure { notConfigured, badUrl, offline, badResponse, badFormat }

class ConfigException implements Exception {
  const ConfigException(this.failure, [this.detail]);

  final ConfigFailure failure;
  final String? detail;

  @override
  String toString() => 'ConfigException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Fetches `fare_rules.json` from the GitHub Gist raw URL.
///
/// The caller decides what to do on failure — this class never falls back on
/// its own, it just reports precisely what went wrong.
class ConfigService {
  ConfigService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FareConfig> fetch(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const ConfigException(ConfigFailure.notConfigured);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.isScheme('https') || uri.host.isEmpty) {
      throw const ConfigException(ConfigFailure.badUrl);
    }

    // Gist raw URLs sit behind a CDN; a cache-buster keeps a fare change from
    // taking hours to reach phones.
    final busted = uri.replace(queryParameters: {
      ...uri.queryParameters,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final http.Response response;
    try {
      response = await _client
          .get(busted, headers: const {'Cache-Control': 'no-cache', 'Accept': 'application/json'})
          .timeout(kConfigFetchTimeout);
    } on Object catch (error) {
      throw ConfigException(ConfigFailure.offline, error.toString());
    }

    if (response.statusCode != 200) {
      throw ConfigException(ConfigFailure.badResponse, 'HTTP ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Top level of fare_rules.json must be an object');
      }
      return FareConfig.fromJson(
        decoded,
        source: FareSource.remote,
        fetchedAt: DateTime.now(),
      );
    } on ConfigException {
      rethrow;
    } on Object catch (error) {
      throw ConfigException(ConfigFailure.badFormat, error.toString());
    }
  }

  void dispose() => _client.close();
}
