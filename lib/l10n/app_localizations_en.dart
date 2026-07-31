// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bhara koto';

  @override
  String get appTagline => 'Bus fare meter';

  @override
  String get startJourney => 'Start Journey';

  @override
  String get endJourney => 'End Journey';

  @override
  String get newTrip => 'New Trip';

  @override
  String get stillMoving => 'Still moving';

  @override
  String get statusIdle => 'Ready';

  @override
  String get statusLocking => 'Finding GPS';

  @override
  String get statusTracking => 'Tracking';

  @override
  String get statusPaused => 'Stopped';

  @override
  String get statusFinished => 'Trip ended';

  @override
  String get labelDistance => 'Distance';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelSpeed => 'Speed';

  @override
  String get labelRatePerKm => 'Rate / km';

  @override
  String get labelMinFare => 'Minimum';

  @override
  String get unitKm => 'km';

  @override
  String get unitKmh => 'km/h';

  @override
  String get unitTaka => '৳';

  @override
  String get minFareApplied => 'Minimum fare applied';

  @override
  String fareBreakdown(String distance, String rate) {
    return '$distance km × ৳$rate';
  }

  @override
  String get arrivedTitle => 'Looks like you\'ve stopped';

  @override
  String get arrivedBody =>
      'This is your fare. Tap End Journey when you get off.';

  @override
  String get weakSignal => 'Weak GPS signal';

  @override
  String accuracyMeters(String meters) {
    return '±$meters m';
  }

  @override
  String get settings => 'Settings';

  @override
  String get sectionFare => 'Fare rates';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionAbout => 'About';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sourceRemote => 'Server';

  @override
  String get sourceCached => 'Offline';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceDefault => 'Default';

  @override
  String lastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get neverSynced => 'Never synced';

  @override
  String get editRates => 'Edit rates manually';

  @override
  String get editRatesHint =>
      'Use this if the government changes the fare before the server does.';

  @override
  String get manualBannerTitle => 'Manual rates are in use';

  @override
  String get manualBannerBody =>
      'Server updates are ignored until you switch back.';

  @override
  String get useServerRates => 'Use server rates';

  @override
  String get fieldRatePerKm => 'Rate per kilometre';

  @override
  String get fieldMinFare => 'Minimum fare';

  @override
  String get invalidNumber => 'Enter a number greater than 0';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get permissionTitle => 'Location access needed';

  @override
  String get permissionBody =>
      'Bhara Koto measures your trip distance with GPS. Nothing leaves your phone.';

  @override
  String get permissionGrant => 'Allow location';

  @override
  String get permissionDeniedForever =>
      'Location is blocked for this app. Enable it from system settings.';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get serviceDisabledTitle => 'Location is switched off';

  @override
  String get serviceDisabledBody =>
      'Turn on Location / GPS to start the meter.';

  @override
  String get openLocationSettings => 'Turn on location';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get disclaimer =>
      'Distance comes from GPS, so the fare is a close estimate — not an official receipt.';

  @override
  String get startHint => 'Tap start as you get on the bus.';

  @override
  String get fareType => 'Bus type';

  @override
  String get profileLocal => 'Local';

  @override
  String get profileIntercity => 'Long distance';

  @override
  String get profileLocalHint => 'Within the district';

  @override
  String get profileIntercityHint => 'Between districts';

  @override
  String editRatesFor(String profile) {
    return 'Edit “$profile” rates';
  }

  @override
  String get inUse => 'In use';
}
