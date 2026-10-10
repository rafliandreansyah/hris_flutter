/// Konstanta kode wewenang fungsional (Functional Permissions)
/// Sesuai dokumentasi resmi docs/AUTHORIZATION_AND_PERMISSIONS.md dan AGENTS.md Rule 17.
abstract class AppPermissions {
  // --- Modul Aktivitas ---
  static const String activityManage = 'activity.manage';
  static const String reportActivityView = 'report.activity.view';

  // --- Modul Lembur (Overtime) ---
  static const String approvalOvertimeAction = 'approval.overtime.action';
  static const String approvalOvertimeView = 'approval.overtime.view';
  static const String reportOvertimeView = 'report.overtime.view';
  static const String overtimeManage = 'overtime.manage';

  // --- Modul Izin & Cuti (Leave) ---
  static const String approvalLeaveAction = 'approval.leave.action';
  static const String approvalLeaveView = 'approval.leave.view';
  static const String reportLeaveView = 'report.leave.view';
  static const String leaveManage = 'leave.manage';

  // --- Modul Absen Luar Kantor (Attendance Requests) ---
  static const String approvalAttendanceAction = 'approval.attendance.action';
  static const String approvalAttendanceView = 'approval.attendance.view';

  // --- Modul Presensi & Log Absensi (Attendance Logs) ---
  static const String attendanceManage = 'attendance.manage';
  static const String reportAttendanceView = 'report.attendance.view';

  // --- Modul Pegawai (Employee Directory) ---
  static const String employeeView = 'employee.view';

  // --- Modul Surat Peringatan (Warning Letter) ---
  static const String warningLetterView = 'warning_letter.view';
  static const String warningLetterCreate = 'warning_letter.create';

  // --- Modul Slip Gaji (Payroll) ---
  static const String payrollSlipView = 'payroll.slip.view';

  // --- Modul Jadwal Kerja (Work Schedule) ---
  static const String workScheduleView = 'work_schedule.view';
  static const String workScheduleAssign = 'work_schedule.assign';

  // --- Modul Klaim & Kasbon (Reimbursement / Expenses) ---
  static const String reimbursementCreate = 'reimbursement.create';
  static const String reimbursementView = 'reimbursement.view';
  static const String reportReimbursementView = 'report.reimbursement.view';
  static const String approvalReimbursementManager = 'approval.reimbursement.manager';
  static const String approvalReimbursementFinance = 'approval.reimbursement.finance';

  // --- Modul Fasilitas & Aset (Asset) ---
  static const String assetMyAssets = 'asset.my_assets';
  static const String assetView = 'asset.view';

  // --- Modul Resign (Resignation) ---
  static const String resignationView = 'resignation.view';
  static const String resignationCreate = 'resignation.create';
  static const String approvalResignationManager = 'approval.resignation.manager';
  static const String approvalResignationHr = 'approval.resignation.hr';
}
