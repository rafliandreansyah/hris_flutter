// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oasish';

  @override
  String greeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Try Again';

  @override
  String get loading => 'Processing...';

  @override
  String get error => 'An Error Occurred';

  @override
  String get success => 'Success';

  @override
  String get notice => 'Notice';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get currentStatus => 'CURRENT STATUS';

  @override
  String get flexibleShift => 'Flexible Shift';

  @override
  String get noWorkSchedule => 'No Work Schedule';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get updates => 'Updates';

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get noAnnouncementsDesc =>
      'There are currently no announcements from the company';

  @override
  String get failedToLoadDashboard => 'Failed to load Dashboard';

  @override
  String get attendanceTitle => 'Attendance & Check-In';

  @override
  String get clockIn => 'Clock In';

  @override
  String get clockOut => 'Clock Out';

  @override
  String get breakSession => 'Break Session';

  @override
  String get breakIn => 'Break In';

  @override
  String get breakOut => 'Break Out';

  @override
  String get clockInNow => 'Clock In Now';

  @override
  String get clockOutNow => 'Clock Out Now';

  @override
  String get reportLocationIssue => 'Report Location Issue';

  @override
  String get scheduleNotice => 'Schedule Notice';

  @override
  String get failedToLoadAttendance => 'Failed to Load Attendance';

  @override
  String get insideGeofence => 'Inside Geofence Radius';

  @override
  String get outsideGeofence => 'Outside Geofence Radius';

  @override
  String get anywhereAttendance => 'Anywhere Attendance';

  @override
  String get gpsDetecting => 'Detecting location...';

  @override
  String get updateGpsLocation => 'Update GPS Location';

  @override
  String get workLocation => 'Work Location';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get settingsAndPreferences => 'SETTINGS & PREFERENCES';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update your account security password';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Reminders for attendance, leave, overtime & broadcasts';

  @override
  String get active => 'Active';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Select application display language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get indonesian => 'Bahasa Indonesia (ID)';

  @override
  String get english => 'English (EN)';

  @override
  String get logout => 'Sign Out (Logout)';

  @override
  String get logoutSubtitle => 'Sign out from this device session';

  @override
  String get logoutConfirmationTitle => 'Confirm Logout';

  @override
  String get logoutConfirmationDesc =>
      'Are you sure you want to sign out of this account session?';

  @override
  String get languageUpdatedSuccess => 'Language updated successfully';
}
