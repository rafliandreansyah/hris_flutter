/// Konstanta kode wewenang fungsional (Functional Permissions)
/// Sesuai dokumentasi resmi docs/AUTHORIZATION_AND_PERMISSIONS.md dan AGENTS.md Rule 17.
abstract class AppPermissions {
  // --- Modul Aktivitas ---
  static const String activityManage = 'activity.manage';

  // --- Modul Lembur (Overtime) ---
  static const String approvalOvertimeAction = 'approval.overtime.action';
  static const String reportOvertimeView = 'report.overtime.view';

  // --- Modul Izin & Cuti (Leave) ---
  static const String approvalLeaveAction = 'approval.leave.action';
  static const String reportLeaveView = 'report.leave.view';

  // --- Modul Absen Luar Kantor (Attendance Requests) ---
  static const String approvalAttendanceAction = 'approval.attendance.action';

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

  // --- Modul Klaim & Kasbon (Reimbursement / Expenses) ---
  static const String reimbursementCreate = 'reimbursement.create';
  static const String approvalReimbursementManager = 'approval.reimbursement.manager';

  // --- Modul Fasilitas & Aset (Asset) ---
  static const String assetMyAssets = 'asset.my_assets';

  // --- Modul Resign (Resignation) ---
  static const String resignationView = 'resignation.view';
  static const String approvalResignationManager = 'approval.resignation.manager';
}
