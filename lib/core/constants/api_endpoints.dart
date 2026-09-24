import 'dart:io';
import 'package:flutter/foundation.dart';

/// Daftar konstanta URL dan Endpoint API backend Muratech HRIS.
abstract class ApiEndpoints {
  /// Base URL dinamis yang otomatis mendeteksi platform saat development:
  /// - Android Emulator: http://10.0.2.2:3000/api/v1
  /// - iOS Simulator / Desktop / Web: http://localhost:3000/api/v1
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://apidev.hroasish.com/api/v1';
    }
    if (Platform.isAndroid) {
      return 'https://apidev.hroasish.com/api/v1';
    }
    return 'https://apidev.hroasish.com/api/v1';
  }

  // ==========================================
  // --- 🔐 AUTHENTICATION ENDPOINTS ---
  // ==========================================
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String authMenus = '/auth/menus';
  static const String authLanguage = '/auth/language';
  static const String authProfile = '/auth/profile';

  // ==========================================
  // --- 👤 EMPLOYEE ENDPOINTS ---
  // ==========================================
  static const String employees = '/employees';
  static const String employee = '/employee';
  static const String employeeProfile = '/employees/profile';
  static const String employeeDashboard = '/employee/dashboard';
  static const String employeeCoworkers = '/employee/coworkers';
  static const String employeeDefaultWorkLocation = '/employee/default-work-location';
  static const String employeeUpdatePassword = '/employee/update-password';
  static const String employeeWorkSchedule = '/employee/work-schedule';

  // ==========================================
  // --- 🏢 ORGANIZATION FILTER ENDPOINTS ---
  // ==========================================
  static const String companies = '/companies';
  static const String departments = '/departments';
  static const String positions = '/positions';

  // ==========================================
  // --- ⏱️ ATTENDANCE ENDPOINTS ---
  // ==========================================
  static const String attendance = '/attendance';
  static const String attendances = '/attendances';
  static const String attendancesEmployees = '/attendances/employees';
  static const String employeeAttendanceInfo = '/employee/attendance/info';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceLogs = '/attendances';
  static const String attendanceSummary = '/attendance/summary';
  static const String outsideAttendance = '/attendance/outside';
  static const String attendanceRequests = '/attendances/requests';
  static const String attendanceLiveRequest = '/attendances/requests/live';
  static const String attendanceScheduleRequest = '/attendances/requests/schedule';
  static String attendanceDetail(String id) => '/attendances/$id';
  static String attendanceRequestDetail(String id) => '/attendances/requests/$id';
  static String attendanceRequestApprove(String id) => '/attendances/requests/$id/approve';

  // ==========================================
  // --- 🏖️ LEAVE & TIME-OFF ENDPOINTS ---
  // ==========================================
  static const String leaveRequests = '/leave-requests';
  /// Endpoint tunggal untuk daftar pengajuan cuti/izin (Leave & Time Off).
  static const String leaveRequest = '/leave-request';
  static const String leaveQuota = '/leave-requests/quota';
  static const String leaveTypes = '/leave-request/types';
  static String leaveRequestDetail(String id) => '/leave-request/$id';
  static String leaveRequestApprove(String id) => '/leave-request/$id/approve';

  // ==========================================
  // --- ⏰ OVERTIME ENDPOINTS ---
  // ==========================================
  static const String overtime = '/overtime';
  static const String myOvertime = '/overtime/my';
  static const String overtimeSchedule = '/overtime/schedule';
  static String overtimeDetail(String id) => '/overtime/$id';
  static String overtimeApprove(String id) => '/overtime/$id/approve';

  // ==========================================
  // --- ⚠️ WARNING LETTERS ENDPOINTS ---
  // ==========================================
  static const String warningLetters = '/warning-letters';
  static const String myWarningLetters = '/warning-letters/my';
  static const String warningLetter = '/warning-letter';
  static const String warningLetterType = '/warning-letter/type';
  static String lastWarningLetterByEmployee(String employeeId) =>
      '/warning-letter/employee/$employeeId/last';
  static String warningLetterDetail(String id) => '/warning-letter/$id';

  // ==========================================
  // --- 📢 ANNOUNCEMENT & AUDIT ENDPOINTS ---
  // ==========================================
  static const String announcement = '/announcement';
  static const String announcements = '/announcements';
  static String announcementDetail(String id) => '/announcement/$id';
  static String announcementAcknowledge(String id) =>
      '/announcement/$id/acknowledge';
  static const String auditLogs = '/audit-logs/my';

  // ==========================================
  // --- 📋 ACTIVITY ENDPOINTS ---
  // ==========================================
  static const String activity = '/activity';
  static const String activityPlan = '/activity/plan';
  static const String activityTypes = '/activity/types';
  static String activityDetail(String id) => '/activity/$id';
  static String activityStart(String id) => '/activity/$id/start';
  static String activityFinish(String id) => '/activity/$id/finish';
  static String activityCancel(String id) => '/activity/$id/cancel';

  // ==========================================
  // --- 🔔 NOTIFICATION ENDPOINTS ---
  // ==========================================
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String employeeNotificationSettings = '/employee/notification-settings';

  // ==========================================
  // --- 💰 EXPENSES, REIMBURSEMENT & KASBON ENDPOINTS ---
  // ==========================================
  static const String expensesFeed = '/expenses';
  static const String reimbursements = '/reimbursements';
  static const String reimbursementCategories = '/reimbursements/categories';
  static String reimbursementDetail(String id) => '/reimbursements/$id';
  static String reimbursementApprove(String id) => '/reimbursements/$id/approve';
  static String reimbursementDisburse(String id) => '/reimbursements/$id/disburse';
  static const String financeDisbursements = '/finance/disbursements';
  static String financeDisbursement(String id) => '/finance/disbursements/$id';
  static const String cashAdvances = '/cash-advances';
  static String cashAdvanceDetail(String id) => '/cash-advances/$id';
  static String cashAdvanceApprove(String id) => '/cash-advances/$id/approve';
  static String cashAdvanceDisburse(String id) => '/cash-advances/$id/disburse';
  static String cashAdvanceRefund(String id) => '/cash-advances/$id/refund';

  // ==========================================
  // --- 💻 ASSET & FASILITAS ENDPOINTS ---
  // ==========================================
  static const String assets = '/assets';
  static const String assetCategories = '/assets/categories';
  static String assetDetail(String id) => '/assets/$id';
  static String assetHandover(String id) => '/assets/$id/handover';
  static String assetTransfer(String id) => '/assets/$id/transfer';
  static String assetApprove(String assignmentId) =>
      '/assets/assignments/$assignmentId/approve';
  static String assetReject(String assignmentId) =>
      '/assets/assignments/$assignmentId/reject';
  
  // ==========================================
  // --- 💻 RESIGNATION ---
  // ==========================================
  static const String resignations = '/resignations';
  static const String myResignationStatus = '/resignations/my-status';
  static const String resignationInitialForm = '/resignations/initial-form';
  static const String subordinateResignations = '/resignations/subordinates';
  static String resignationDetail(String id) => '/resignations/$id';
  static String resignationClearance(String id) => '/resignations/$id/clearance';
}

