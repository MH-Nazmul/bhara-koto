import 'package:bhara_koto/main.dart';
import 'package:bhara_koto/services/config_service.dart';
import 'package:bhara_koto/services/location_service.dart';
import 'package:bhara_koto/services/storage_service.dart';
import 'package:bhara_koto/state/app_state.dart';
import 'package:bhara_koto/state/trip_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _twoProfileGist = '''
{
  "version": "test",
  "fares": {
    "local":     { "rate_per_km": 2.53, "min_fare": 10.0 },
    "intercity": { "rate_per_km": 2.15, "min_fare": 12.0 }
  }
}
''';

/// Builds the real app with a stubbed network so the Gist fetch is deterministic
/// instead of depending on GitHub being reachable from the test runner.
Future<Widget> buildApp({
  Map<String, Object> prefs = const {},
  String? gistBody = _twoProfileGist,
  List<Uri>? hits,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await StorageService.create();
  final location = LocationService();

  final client = MockClient((request) async {
    hits?.add(request.url);
    return gistBody == null
        ? http.Response('not found', 404)
        : http.Response(gistBody, 200, headers: {'content-type': 'application/json'});
  });

  final app = AppState(storage: storage, configService: ConfigService(client: client))
    ..bootstrap();

  return BharaKotoApp(
    app: app,
    trip: TripState(location: location),
    locationService: location,
  );
}

void main() {
  testWidgets('opens on the meter with the local rate and a start button', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Bhara koto'), findsOneWidget);
    expect(find.text('Start Journey'), findsOneWidget);
    // No trip yet: the fare and the distance both read zero.
    expect(find.text('0.00'), findsNWidgets(2));
    // Local is the default profile, so its rate is the one on the strip.
    expect(find.textContaining('2.53'), findsWidgets);
  });

  testWidgets('switching bus type swaps in the long-distance rate', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('2.53'), findsWidgets);
    expect(find.textContaining('2.15'), findsNothing);

    await tester.tap(find.text('Long distance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2.15'), findsWidgets);
    expect(find.textContaining('Minimum ৳12'), findsOneWidget);
    expect(find.textContaining('2.53'), findsNothing);
  });

  testWidgets('the chosen bus type survives a restart', (tester) async {
    await tester.pumpWidget(await buildApp(prefs: {'fare.profile': 'intercity'}));
    await tester.pumpAndSettle();

    expect(find.textContaining('2.15'), findsWidgets);
  });

  testWidgets('switching language redraws the meter in Bangla numerals', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('অ'));
    await tester.pumpAndSettle();

    expect(find.text('ভাড়া কত'), findsOneWidget);
    expect(find.text('যাত্রা শুরু'), findsOneWidget);
    expect(find.text('০.০০'), findsNWidgets(2));
    expect(find.text('দূরপাল্লা'), findsOneWidget);
  });

  testWidgets('an unreachable Gist falls back to the cached copy, not the default',
      (tester) async {
    await tester.pumpWidget(await buildApp(
      gistBody: null, // every request 404s
      prefs: {
        'config.remote': '{"fares":{"local":{"rate_per_km":9.99,"min_fare":20.0},'
            '"intercity":{"rate_per_km":8.88,"min_fare":25.0}}}',
      },
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('9.99'), findsWidgets);
    expect(find.text('Offline'), findsOneWidget);
  });

  group('daily refresh', () {
    // Cached rates that differ from what the Gist would serve, so it is obvious
    // from the UI alone whether a fetch happened.
    const cached = '{"fares":{"local":{"rate_per_km":9.99,"min_fare":20.0},'
        '"intercity":{"rate_per_km":8.88,"min_fare":25.0}}}';

    testWidgets('skips the network when it already synced today', (tester) async {
      final hits = <Uri>[];
      await tester.pumpWidget(await buildApp(
        hits: hits,
        prefs: {
          'config.remote': cached,
          'config.last_synced_at':
              DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        },
      ));
      await tester.pumpAndSettle();

      expect(hits, isEmpty, reason: 'synced 3 hours ago — nothing to do');
      expect(find.textContaining('9.99'), findsWidgets);
      // Skipping the fetch must not make today's rates look stale.
      expect(find.text('Server'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('fetches again once the rates are a day old', (tester) async {
      final hits = <Uri>[];
      await tester.pumpWidget(await buildApp(
        hits: hits,
        prefs: {
          'config.remote': cached,
          'config.last_synced_at':
              DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
        },
      ));
      await tester.pumpAndSettle();

      expect(hits, hasLength(1));
      expect(find.textContaining('2.53'), findsWidgets, reason: 'picked up the Gist');
      expect(find.textContaining('9.99'), findsNothing);
    });

    testWidgets('fetches on a first-ever launch', (tester) async {
      final hits = <Uri>[];
      await tester.pumpWidget(await buildApp(hits: hits));
      await tester.pumpAndSettle();

      expect(hits, hasLength(1));
    });
  });

  testWidgets('a saved manual override wins over the fetched rates', (tester) async {
    await tester.pumpWidget(await buildApp(prefs: {
      'config.manual': '{"fares":{"local":{"rate_per_km":3.15,"min_fare":15.0},'
          '"intercity":{"rate_per_km":2.15,"min_fare":12.0}}}',
      'config.manual_enabled': true,
    }));
    await tester.pumpAndSettle();

    expect(find.textContaining('3.15'), findsWidgets);
    expect(find.text('Manual'), findsOneWidget);
  });
}
