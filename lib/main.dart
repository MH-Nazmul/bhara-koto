import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/config_service.dart';
import 'services/location_service.dart';
import 'services/storage_service.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'state/trip_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage is the only thing worth blocking the first frame for — it is a
  // local read, and it decides which rates the meter opens with.
  final storage = await StorageService.create();
  final configService = ConfigService();
  final locationService = LocationService();

  final app = AppState(storage: storage, configService: configService);
  final trip = TripState(location: locationService);

  // Reads the cache synchronously, then fires the Gist request in the
  // background; being offline simply means nothing changes.
  app.bootstrap();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(BharaKotoApp(app: app, trip: trip, locationService: locationService));
}

class BharaKotoApp extends StatelessWidget {
  const BharaKotoApp({
    super.key,
    required this.app,
    required this.trip,
    required this.locationService,
  });

  final AppState app;
  final TripState trip;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    // AppScope sits above MaterialApp so pushed routes reach the same
    // controllers without any of them becoming globals.
    return AppScope(
      app: app,
      trip: trip,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) => MaterialApp(
          title: 'Bhara koto',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: app.themeMode,
          locale: app.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            // The fare must stay readable at any system font size, but an
            // unbounded scale would break the single-screen layout.
            final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.overlayFor(Theme.of(context).brightness),
                child: child!,
              ),
            );
          },
          home: HomeScreen(locationService: locationService),
        ),
      ),
    );
  }
}
