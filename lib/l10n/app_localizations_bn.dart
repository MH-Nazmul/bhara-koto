// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ভাড়া কত';

  @override
  String get appTagline => 'বাসের ভাড়ার মিটার';

  @override
  String get startJourney => 'যাত্রা শুরু';

  @override
  String get endJourney => 'যাত্রা শেষ';

  @override
  String get newTrip => 'নতুন যাত্রা';

  @override
  String get stillMoving => 'এখনো চলছি';

  @override
  String get statusIdle => 'প্রস্তুত';

  @override
  String get statusLocking => 'জিপিএস খোঁজা হচ্ছে';

  @override
  String get statusTracking => 'চলছে';

  @override
  String get statusPaused => 'থেমে আছে';

  @override
  String get statusFinished => 'যাত্রা শেষ';

  @override
  String get labelDistance => 'দূরত্ব';

  @override
  String get labelDuration => 'সময়';

  @override
  String get labelSpeed => 'গতি';

  @override
  String get labelRatePerKm => 'প্রতি কিমি';

  @override
  String get labelMinFare => 'সর্বনিম্ন';

  @override
  String get unitKm => 'কিমি';

  @override
  String get unitKmh => 'কিমি/ঘণ্টা';

  @override
  String get unitTaka => '৳';

  @override
  String get minFareApplied => 'সর্বনিম্ন ভাড়া প্রযোজ্য';

  @override
  String fareBreakdown(String distance, String rate) {
    return '$distance কিমি × ৳$rate';
  }

  @override
  String get arrivedTitle => 'মনে হচ্ছে আপনি থেমেছেন';

  @override
  String get arrivedBody => 'এটাই আপনার ভাড়া। নামার সময় যাত্রা শেষ চাপুন।';

  @override
  String get weakSignal => 'জিপিএস সিগন্যাল দুর্বল';

  @override
  String accuracyMeters(String meters) {
    return '±$meters মি';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get sectionFare => 'ভাড়ার হার';

  @override
  String get sectionAppearance => 'চেহারা';

  @override
  String get sectionAbout => 'অ্যাপ সম্পর্কে';

  @override
  String get language => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get sourceRemote => 'সার্ভার';

  @override
  String get sourceCached => 'অফলাইন';

  @override
  String get sourceManual => 'নিজের হার';

  @override
  String get sourceDefault => 'ডিফল্ট';

  @override
  String lastSynced(String time) {
    return 'সর্বশেষ সিঙ্ক $time';
  }

  @override
  String get neverSynced => 'কখনো সিঙ্ক হয়নি';

  @override
  String get editRates => 'নিজে হার ঠিক করুন';

  @override
  String get editRatesHint =>
      'সরকার ভাড়া বদলালে সার্ভার হালনাগাদের আগেই এটি ব্যবহার করুন।';

  @override
  String get manualBannerTitle => 'নিজে দেওয়া হার চলছে';

  @override
  String get manualBannerBody =>
      'ফিরে না যাওয়া পর্যন্ত সার্ভারের হালনাগাদ উপেক্ষা করা হবে।';

  @override
  String get useServerRates => 'সার্ভারের হার ব্যবহার করুন';

  @override
  String get fieldRatePerKm => 'প্রতি কিলোমিটার ভাড়া';

  @override
  String get fieldMinFare => 'সর্বনিম্ন ভাড়া';

  @override
  String get invalidNumber => '০ এর বেশি একটি সংখ্যা দিন';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get close => 'বন্ধ';

  @override
  String get permissionTitle => 'লোকেশন অনুমতি দরকার';

  @override
  String get permissionBody =>
      'ভাড়া কত জিপিএস দিয়ে দূরত্ব মাপে। কোনো তথ্য ফোনের বাইরে যায় না।';

  @override
  String get permissionGrant => 'লোকেশন অনুমতি দিন';

  @override
  String get permissionDeniedForever =>
      'এই অ্যাপের জন্য লোকেশন বন্ধ করা আছে। সিস্টেম সেটিংস থেকে চালু করুন।';

  @override
  String get openAppSettings => 'অ্যাপ সেটিংস খুলুন';

  @override
  String get serviceDisabledTitle => 'লোকেশন বন্ধ আছে';

  @override
  String get serviceDisabledBody =>
      'মিটার চালু করতে লোকেশন / জিপিএস চালু করুন।';

  @override
  String get openLocationSettings => 'লোকেশন চালু করুন';

  @override
  String version(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get disclaimer =>
      'দূরত্ব জিপিএস থেকে আসে, তাই ভাড়া কাছাকাছি হিসাব — সরকারি রসিদ নয়।';

  @override
  String get startHint => 'বাসে ওঠার সময় শুরু চাপুন।';

  @override
  String get fareType => 'বাসের ধরন';

  @override
  String get profileLocal => 'লোকাল';

  @override
  String get profileIntercity => 'দূরপাল্লা';

  @override
  String get profileLocalHint => 'জেলার ভিতরে';

  @override
  String get profileIntercityHint => 'এক জেলা থেকে অন্য জেলায়';

  @override
  String editRatesFor(String profile) {
    return '“$profile” হার ঠিক করুন';
  }

  @override
  String get inUse => 'চালু';
}
