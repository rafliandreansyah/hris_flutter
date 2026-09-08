import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Oasish'**
  String get appTitle;

  /// Greeting on dashboard header
  ///
  /// In id, this message translates to:
  /// **'Hi, {name} 👋'**
  String greeting(String name);

  /// No description provided for @ok.
  ///
  /// In id, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get close;

  /// No description provided for @back.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get back;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memproses...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In id, this message translates to:
  /// **'Terjadi Kesalahan'**
  String get error;

  /// No description provided for @success.
  ///
  /// In id, this message translates to:
  /// **'Berhasil'**
  String get success;

  /// No description provided for @notice.
  ///
  /// In id, this message translates to:
  /// **'Pemberitahuan'**
  String get notice;

  /// No description provided for @dashboardTitle.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @currentStatus.
  ///
  /// In id, this message translates to:
  /// **'STATUS SAAT INI'**
  String get currentStatus;

  /// No description provided for @flexibleShift.
  ///
  /// In id, this message translates to:
  /// **'Shift Fleksibel'**
  String get flexibleShift;

  /// No description provided for @noWorkSchedule.
  ///
  /// In id, this message translates to:
  /// **'Tidak Ada Jadwal Kerja'**
  String get noWorkSchedule;

  /// No description provided for @quickAccess.
  ///
  /// In id, this message translates to:
  /// **'Akses Cepat'**
  String get quickAccess;

  /// No description provided for @updates.
  ///
  /// In id, this message translates to:
  /// **'Pembaruan'**
  String get updates;

  /// No description provided for @noAnnouncements.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pengumuman'**
  String get noAnnouncements;

  /// No description provided for @noAnnouncementsDesc.
  ///
  /// In id, this message translates to:
  /// **'Saat ini belum ada pengumuman terbaru dari perusahaan'**
  String get noAnnouncementsDesc;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat Dashboard'**
  String get failedToLoadDashboard;

  /// No description provided for @attendanceTitle.
  ///
  /// In id, this message translates to:
  /// **'Kehadiran & Check-In'**
  String get attendanceTitle;

  /// No description provided for @clockIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk Kerja'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In id, this message translates to:
  /// **'Pulang Kerja'**
  String get clockOut;

  /// No description provided for @breakSession.
  ///
  /// In id, this message translates to:
  /// **'Istirahat'**
  String get breakSession;

  /// No description provided for @breakIn.
  ///
  /// In id, this message translates to:
  /// **'Selesai Istirahat'**
  String get breakIn;

  /// No description provided for @breakOut.
  ///
  /// In id, this message translates to:
  /// **'Mulai Istirahat'**
  String get breakOut;

  /// No description provided for @clockInNow.
  ///
  /// In id, this message translates to:
  /// **'Masuk Kerja Sekarang'**
  String get clockInNow;

  /// No description provided for @clockOutNow.
  ///
  /// In id, this message translates to:
  /// **'Pulang Kerja Sekarang'**
  String get clockOutNow;

  /// No description provided for @reportLocationIssue.
  ///
  /// In id, this message translates to:
  /// **'Laporkan Kendala Lokasi'**
  String get reportLocationIssue;

  /// No description provided for @scheduleNotice.
  ///
  /// In id, this message translates to:
  /// **'Pemberitahuan Jadwal'**
  String get scheduleNotice;

  /// No description provided for @failedToLoadAttendance.
  ///
  /// In id, this message translates to:
  /// **'Gagal Memuat Absensi'**
  String get failedToLoadAttendance;

  /// No description provided for @insideGeofence.
  ///
  /// In id, this message translates to:
  /// **'Dalam Radius Kantor'**
  String get insideGeofence;

  /// No description provided for @outsideGeofence.
  ///
  /// In id, this message translates to:
  /// **'Di Luar Radius Kantor'**
  String get outsideGeofence;

  /// No description provided for @anywhereAttendance.
  ///
  /// In id, this message translates to:
  /// **'Absen Dimana Saja'**
  String get anywhereAttendance;

  /// No description provided for @gpsDetecting.
  ///
  /// In id, this message translates to:
  /// **'Mendeteksi lokasi...'**
  String get gpsDetecting;

  /// No description provided for @updateGpsLocation.
  ///
  /// In id, this message translates to:
  /// **'Perbarui Lokasi GPS'**
  String get updateGpsLocation;

  /// No description provided for @workLocation.
  ///
  /// In id, this message translates to:
  /// **'Lokasi Kerja'**
  String get workLocation;

  /// No description provided for @accountSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Akun'**
  String get accountSettings;

  /// No description provided for @settingsAndPreferences.
  ///
  /// In id, this message translates to:
  /// **'PENGATURAN & PREFERENSI'**
  String get settingsAndPreferences;

  /// No description provided for @changePassword.
  ///
  /// In id, this message translates to:
  /// **'Ganti Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Perbarui kata sandi akun keamanan Anda'**
  String get changePasswordSubtitle;

  /// No description provided for @notifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pengingat absen, izin, lembur & broadcast'**
  String get notificationsSubtitle;

  /// No description provided for @active.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih bahasa tampilan aplikasi'**
  String get languageSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In id, this message translates to:
  /// **'Pilih Bahasa'**
  String get selectLanguage;

  /// No description provided for @indonesian.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Indonesia (ID)'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In id, this message translates to:
  /// **'English (EN)'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Akun (Logout)'**
  String get logout;

  /// No description provided for @logoutSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari sesi login perangkat ini'**
  String get logoutSubtitle;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Logout'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutConfirmationDesc.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin keluar dari sesi akun ini?'**
  String get logoutConfirmationDesc;

  /// No description provided for @languageUpdatedSuccess.
  ///
  /// In id, this message translates to:
  /// **'Bahasa berhasil diperbarui'**
  String get languageUpdatedSuccess;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
