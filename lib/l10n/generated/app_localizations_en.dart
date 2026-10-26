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
  String get dayOffSchedule => 'Day Off';

  @override
  String get dayOffNotice => 'Day Off Schedule';

  @override
  String get dayOffDescription =>
      'You do not have an active work schedule today (Day Off).';

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

  @override
  String get theme => 'Theme';

  @override
  String get themeSubtitle => 'Select application display theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get themeUpdatedSuccess => 'Theme updated successfully';

  @override
  String get attendanceDetailTitle => 'Attendance Detail';

  @override
  String get verificationDetails => 'Attendance Verification';

  @override
  String get onTime => 'On Time';

  @override
  String lateByMinutes(int minutes) {
    return 'Late by $minutes mins';
  }

  @override
  String earlyByMinutes(int minutes) {
    return 'Early by $minutes mins';
  }

  @override
  String get verifiedIdentityNotice =>
      'Identity verified via biometrics and GPS geofence';

  @override
  String get attendanceLocation => 'Attendance Location';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get gpsCoordinates => 'GPS Coordinates';

  @override
  String get outsideAttendanceTitle => 'Outside Attendance';

  @override
  String get outsideAttendanceDesc =>
      'Check-in from Outside Attendance request';

  @override
  String get requestReference => 'Request Reference';

  @override
  String get employeeInfo => 'Employee Information';

  @override
  String get shiftSchedule => 'Shift Schedule';

  @override
  String get attendanceMethod => 'Attendance Method';

  @override
  String get proofAttachment => 'Attendance Photo Proof';

  @override
  String get tapToPreview => 'Tap to preview full photo';

  @override
  String get requestAttendanceCorrection => 'Request Attendance Correction';

  @override
  String get attendanceDetailNotFound => 'Attendance detail not found';

  @override
  String get attendanceDetailNoAccess =>
      'You do not have permission to view this data';

  @override
  String get noPayrollPeriodTitle => 'Payroll Period Not Available';

  @override
  String get noPayrollPeriodLastMonthDesc =>
      'No payroll period available for last month. You can check the Current Month period.';

  @override
  String get viewCurrentMonth => 'View Current Month';

  @override
  String get tabMyRequests => 'My Requests';

  @override
  String get tabTeamApprovals => 'Team Approvals';

  @override
  String get tabSelf => 'Me';

  @override
  String get tabMyTeam => 'My Team';

  @override
  String get tabWarningReceived => 'Received Letters';

  @override
  String get tabWarningIssued => 'Issued Letters';

  @override
  String get menuAttendance => 'Attendance History';

  @override
  String get menuOutsideAttendance => 'Outside Check-in';

  @override
  String get menuSchedule => 'Work Schedule';

  @override
  String get menuLiveTracking => 'Live Tracking';

  @override
  String get menuLeave => 'Leave';

  @override
  String get menuOvertime => 'Overtime';

  @override
  String get menuActivity => 'Activities';

  @override
  String get menuPayroll => 'Payslip';

  @override
  String get menuClaims => 'Claims & Advances';

  @override
  String get menuEmployee => 'Employees';

  @override
  String get menuWarningLetter => 'Warning Letters';

  @override
  String get menuAsset => 'Assets';

  @override
  String get menuResignation => 'Resignation';

  @override
  String get menuMore => 'More';

  @override
  String get menuGroupAttendance => 'Attendance';

  @override
  String get menuGroupRequests => 'Requests';

  @override
  String get menuGroupFinance => 'Finance';

  @override
  String get menuGroupEmployee => 'People';

  @override
  String get seeAll => 'See All';

  @override
  String get clockInAction => 'Clock In';

  @override
  String get clockOutAction => 'Clock Out';

  @override
  String get clockInShort => 'In';

  @override
  String get clockOutShort => 'Out';

  @override
  String get latestCompanyAnnouncement => 'Latest · Company Announcement';

  @override
  String get titleLeave => 'Leave & Time Off';

  @override
  String get titleLeaveDetail => 'Leave Request Detail';

  @override
  String get titleOvertime => 'Overtime Requests';

  @override
  String get titleOvertimeDetail => 'Overtime Request Detail';

  @override
  String get titleAttendanceLogs => 'Attendance Logs';

  @override
  String get titleActivityReports => 'Activity Reports';

  @override
  String get titleActivityDetail => 'Activity Detail';

  @override
  String get titleCreateActivity => 'Create Activity';

  @override
  String get statusWaitingApproval => 'Waiting for Approval';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get clockInLabel => 'Clock In';

  @override
  String get clockOutLabel => 'Clock Out';

  @override
  String get titleEmployeeDirectory => 'Employee Directory';

  @override
  String get consentTitle => 'Privacy Policy & Terms';

  @override
  String get consentIntro =>
      'Before using Oasish, please read and accept how we collect and process your data.';

  @override
  String get consentDataHeader => 'DATA WE PROCESS';

  @override
  String get consentDataLocation =>
      'Precise location for attendance. While you are clocked in and during field tasks, your work route is recorded, including when the app is closed or in the background.';

  @override
  String get consentDataCamera =>
      'Camera and photos for attendance selfies, activity proof, and claim documents.';

  @override
  String get consentDataBiometric =>
      'Biometrics (fingerprint / Face ID) are processed on the device and never sent to our servers.';

  @override
  String get consentDataDevice =>
      'Employment data, device ID, battery level, and notification token to run the service.';

  @override
  String get consentDocumentsHeader => 'LEGAL DOCUMENTS';

  @override
  String get consentAgreement =>
      'I have read and agree to the Oasish Privacy Policy and Terms & Conditions.';

  @override
  String get consentAccept => 'Agree & Continue';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String get legalTerms => 'Terms & Conditions';

  @override
  String get legalRefundPolicy => 'Refund Policy';

  @override
  String get legalFaq => 'FAQ';

  @override
  String get legalDeleteData => 'Delete Account & Data';

  @override
  String get legalDeleteDataSubtitle =>
      'Request deletion of your account and personal data';

  @override
  String get legalContact => 'Contact';

  @override
  String get legalAndHelp => 'LEGAL & HELP';

  @override
  String get legalLinkOpenFailed =>
      'The page could not be opened. Check your internet connection and try again.';

  @override
  String get trackingResumeTitle => 'Work location tracking paused';

  @override
  String get trackingResumeBody =>
      'Tap to resume tracking during your working hours.';

  @override
  String get menuLifecycle => 'Evaluation & Contracts';

  @override
  String get teamContractsTitle => 'Team Contracts Ending';

  @override
  String get teamContractsEmptyTitle => 'No Contracts Ending Soon';

  @override
  String get teamContractsEmptyMessage =>
      'No team contracts end within the next 30 days.';

  @override
  String teamContractsDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String teamContractsEndsOn(String date) {
    return 'Ends $date';
  }

  @override
  String get teamContractsOpenEvaluation => 'View Evaluation';

  @override
  String get teamContractsNoEvaluation => 'Evaluation not created yet';
}
