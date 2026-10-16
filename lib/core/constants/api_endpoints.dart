import 'package:flutter/foundation.dart' show kReleaseMode;

/// Daftar konstanta URL dan Endpoint API backend Muratech HRIS.
abstract class ApiEndpoints {
  /// Host API release (production). Dipakai pada build release bila tidak ada override.
  static const String _releaseApiBaseUrl = 'https://api.hroasish.com/api/v1';

  /// Host API development. Dipakai pada debug/profile bila tidak ada override.
  static const String _devApiBaseUrl = 'https://apidev.hroasish.com/api/v1';

  /// Base URL API. Bisa diganti per build, misalnya:
  /// `flutter build apk --dart-define=API_BASE_URL=https://api.hroasish.com/api/v1`
  /// Satu sumber untuk semua platform (Android, iOS, web).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return kReleaseMode ? _releaseApiBaseUrl : _devApiBaseUrl;
  }

  /// Host untuk file statis/upload (tanpa prefix `/api/vX`), diturunkan dari [baseUrl].
  static String get fileBaseUrl {
    return baseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
  }

  // ==========================================
  // --- 🔐 AUTHENTICATION ENDPOINTS ---
  // ==========================================
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
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
  static const String attendanceBreakStart = '/attendances/break/start';
  static const String attendanceBreakEnd = '/attendances/break/end';
  static const String attendanceBreakToday = '/attendances/break/today';
  static const String employeeAttendanceInfo = '/employee/attendance/info';
  static const String attendanceLogs = '/attendances';
  static const String attendanceRequests = '/attendances/requests';
  static const String attendanceLiveRequest = '/attendances/requests/live';
  static const String attendanceScheduleRequest = '/attendances/requests/schedule';
  static String attendanceDetail(String id) => '/attendances/$id';
  static String attendanceRequestDetail(String id) => '/attendances/requests/$id';
  static String attendanceRequestApprove(String id) => '/attendances/requests/$id/approve';

  // ==========================================
  // --- 🏖️ LEAVE & TIME-OFF ENDPOINTS ---
  // ==========================================
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
  static const String resignationExitInterview = '/resignations/my/exit-interview';
  static String subordinateResignationApprove(String id) =>
      '/resignations/subordinates/$id/approve';
  static String subordinateResignationReject(String id) =>
      '/resignations/subordinates/$id/reject';
  static String resignationClearance(String id) => '/resignations/$id/clearance';

  // ==========================================
  // --- 🔄 EMPLOYEE LIFECYCLE ---
  // ==========================================
  static const String lifecycleEvaluationsAssigned = '/lifecycle/evaluations/assigned';
  static const String lifecycleEvaluationsMy = '/lifecycle/evaluations/my';
  static String lifecycleEvaluationMyDetail(String id) => '/lifecycle/evaluations/my/$id';
  static String lifecycleEvaluation(String id) => '/lifecycle/evaluations/$id';
  static String lifecycleEvaluationAnswers(String id) => '/lifecycle/evaluations/$id/answers';
  static String lifecycleEvaluationSubmit(String id) => '/lifecycle/evaluations/$id/submit';
  static String lifecycleEvaluationAcknowledge(String id) => '/lifecycle/evaluations/$id/acknowledge';
  static const String lifecycleContractsMy = '/lifecycle/contracts/my';
  static const String lifecycleCareerHistoryMy = '/lifecycle/career-history/my';
  static const String lifecycleOffboardingMy = '/lifecycle/offboarding/my';
  static const String lifecycleOnboardingMy = '/lifecycle/onboarding/my';
  static const String lifecycleTasksMy = '/lifecycle/tasks/my';
  static String lifecycleTaskComplete(String id) => '/lifecycle/tasks/$id/complete';

  // ==========================================
  // --- 📍 LOCATION TRACKING ENDPOINTS ---
  // ==========================================
  static const String trackingConfig = '/tracking/config';
  static const String trackingBatch = '/tracking/batch';
  static const String trackingLogs = '/tracking/logs';
  static const String trackingLive = '/tracking/live';

  // ==========================================
  // --- 💵 PAYROLL & SLIP GAJI ENDPOINTS ---
  // ==========================================
  static const String payrolls = '/payrolls';
  static const String myPayslips = '/payrolls/me/slips';
  static const String payrollPeriods = '/payrolls/periods';
  static const String payrollEmployees = '/payrolls/employees';
  static String payrollDetail(String id) => '/payrolls/$id';
  static String payrollDownload(String id) => '/payrolls/$id/download';
}


