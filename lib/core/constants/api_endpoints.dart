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
  static String attendanceDetail(String id) => '/attendances/$id';

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

  // ==========================================
  // --- ⚠️ WARNING LETTERS ENDPOINTS ---
  // ==========================================
  static const String warningLetters = '/warning-letters';
  static const String myWarningLetters = '/warning-letters/my';

  // ==========================================
  // --- 📢 ANNOUNCEMENT & AUDIT ENDPOINTS ---
  // ==========================================
  static const String announcements = '/announcements';
  static const String auditLogs = '/audit-logs/my';

  // ==========================================
  // --- 📋 ACTIVITY ENDPOINTS ---
  // ==========================================
  static const String activity = '/activity';
  static const String activityTypes = '/activity/types';
  static String activityDetail(String id) => '/activity/$id';
  static String activityFinish(String id) => '/activity/$id/finish';
  static String activityCancel(String id) => '/activity/$id/cancel';
}

