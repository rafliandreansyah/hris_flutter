import 'dart:io';
import 'package:flutter/foundation.dart';

/// Daftar konstanta URL dan Endpoint API backend Muratech HRIS.
abstract class ApiEndpoints {
  /// Base URL dinamis yang otomatis mendeteksi platform saat development:
  /// - Android Emulator: http://10.0.2.2:3000/api/v1
  /// - iOS Simulator / Desktop / Web: http://localhost:3000/api/v1
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
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

  // ==========================================
  // --- 👤 EMPLOYEE ENDPOINTS ---
  // ==========================================
  static const String employees = '/employees';
  static const String employeeProfile = '/employees/profile';

  // ==========================================
  // --- ⏱️ ATTENDANCE ENDPOINTS ---
  // ==========================================
  static const String attendance = '/attendance';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceLogs = '/attendance/logs';
  static const String attendanceSummary = '/attendance/summary';
  static const String outsideAttendance = '/attendance/outside';

  // ==========================================
  // --- 🏖️ LEAVE & TIME-OFF ENDPOINTS ---
  // ==========================================
  static const String leaveRequests = '/leave-requests';
  static const String leaveQuota = '/leave-requests/quota';
  static const String leaveTypes = '/leave-requests/types';

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
}
