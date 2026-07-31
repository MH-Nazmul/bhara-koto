import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Bhara koto'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Bus fare meter'**
  String get appTagline;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Journey'**
  String get startJourney;

  /// No description provided for @endJourney.
  ///
  /// In en, this message translates to:
  /// **'End Journey'**
  String get endJourney;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get newTrip;

  /// No description provided for @stillMoving.
  ///
  /// In en, this message translates to:
  /// **'Still moving'**
  String get stillMoving;

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusIdle;

  /// No description provided for @statusLocking.
  ///
  /// In en, this message translates to:
  /// **'Finding GPS'**
  String get statusLocking;

  /// No description provided for @statusTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get statusTracking;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusPaused;

  /// No description provided for @statusFinished.
  ///
  /// In en, this message translates to:
  /// **'Trip ended'**
  String get statusFinished;

  /// No description provided for @labelDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get labelDistance;

  /// No description provided for @labelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDuration;

  /// No description provided for @labelSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get labelSpeed;

  /// No description provided for @labelRatePerKm.
  ///
  /// In en, this message translates to:
  /// **'Rate / km'**
  String get labelRatePerKm;

  /// No description provided for @labelMinFare.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get labelMinFare;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitKmh.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKmh;

  /// No description provided for @unitTaka.
  ///
  /// In en, this message translates to:
  /// **'৳'**
  String get unitTaka;

  /// No description provided for @minFareApplied.
  ///
  /// In en, this message translates to:
  /// **'Minimum fare applied'**
  String get minFareApplied;

  /// No description provided for @fareBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{distance} km × ৳{rate}'**
  String fareBreakdown(String distance, String rate);

  /// No description provided for @arrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Looks like you\'ve stopped'**
  String get arrivedTitle;

  /// No description provided for @arrivedBody.
  ///
  /// In en, this message translates to:
  /// **'This is your fare. Tap End Journey when you get off.'**
  String get arrivedBody;

  /// No description provided for @weakSignal.
  ///
  /// In en, this message translates to:
  /// **'Weak GPS signal'**
  String get weakSignal;

  /// No description provided for @accuracyMeters.
  ///
  /// In en, this message translates to:
  /// **'±{meters} m'**
  String accuracyMeters(String meters);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sectionFare.
  ///
  /// In en, this message translates to:
  /// **'Fare rates'**
  String get sectionFare;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sourceRemote.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get sourceRemote;

  /// No description provided for @sourceCached.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get sourceCached;

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sourceManual;

  /// No description provided for @sourceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sourceDefault;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String lastSynced(String time);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get neverSynced;

  /// No description provided for @editRates.
  ///
  /// In en, this message translates to:
  /// **'Edit rates manually'**
  String get editRates;

  /// No description provided for @editRatesHint.
  ///
  /// In en, this message translates to:
  /// **'Use this if the government changes the fare before the server does.'**
  String get editRatesHint;

  /// No description provided for @manualBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual rates are in use'**
  String get manualBannerTitle;

  /// No description provided for @manualBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Server updates are ignored until you switch back.'**
  String get manualBannerBody;

  /// No description provided for @useServerRates.
  ///
  /// In en, this message translates to:
  /// **'Use server rates'**
  String get useServerRates;

  /// No description provided for @fieldRatePerKm.
  ///
  /// In en, this message translates to:
  /// **'Rate per kilometre'**
  String get fieldRatePerKm;

  /// No description provided for @fieldMinFare.
  ///
  /// In en, this message translates to:
  /// **'Minimum fare'**
  String get fieldMinFare;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than 0'**
  String get invalidNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access needed'**
  String get permissionTitle;

  /// No description provided for @permissionBody.
  ///
  /// In en, this message translates to:
  /// **'Bhara Koto measures your trip distance with GPS. Nothing leaves your phone.'**
  String get permissionBody;

  /// No description provided for @permissionGrant.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get permissionGrant;

  /// No description provided for @permissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for this app. Enable it from system settings.'**
  String get permissionDeniedForever;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @serviceDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off'**
  String get serviceDisabledTitle;

  /// No description provided for @serviceDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location / GPS to start the meter.'**
  String get serviceDisabledBody;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get openLocationSettings;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Distance comes from GPS, so the fare is a close estimate — not an official receipt.'**
  String get disclaimer;

  /// No description provided for @startHint.
  ///
  /// In en, this message translates to:
  /// **'Tap start as you get on the bus.'**
  String get startHint;

  /// No description provided for @fareType.
  ///
  /// In en, this message translates to:
  /// **'Bus type'**
  String get fareType;

  /// No description provided for @profileLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get profileLocal;

  /// No description provided for @profileIntercity.
  ///
  /// In en, this message translates to:
  /// **'Long distance'**
  String get profileIntercity;

  /// No description provided for @profileLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Within the district'**
  String get profileLocalHint;

  /// No description provided for @profileIntercityHint.
  ///
  /// In en, this message translates to:
  /// **'Between districts'**
  String get profileIntercityHint;

  /// No description provided for @editRatesFor.
  ///
  /// In en, this message translates to:
  /// **'Edit “{profile}” rates'**
  String editRatesFor(String profile);

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get inUse;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
