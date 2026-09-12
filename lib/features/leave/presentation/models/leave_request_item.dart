import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Status pengajuan cuti/izin pada Oasish HRIS.
///
/// Token warna mengikuti ActivityStatusExtension (fitur aktivitas) agar
/// desain badge status di seluruh app konsisten: pending -> amber,
/// approved -> green, rejected -> red.
enum LeaveStatus { pending, approved, rejected, requested }

extension LeaveStatusExtension on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
      case LeaveStatus.requested:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  /// Warna teks badge — sama persis dengan ActivityStatusExtension
  /// (Amber 700 / Green 800 / Red 800).
  Color get textColor {
    switch (this) {
      case LeaveStatus.pending:
      case LeaveStatus.requested:
        return const Color(0xFFB45309); // Amber 700
      case LeaveStatus.approved:
        return const Color(0xFF166534); // Green 800
      case LeaveStatus.rejected:
        return const Color(0xFF991B1B); // Red 800
    }
  }

  /// Warna background badge (Amber 100 / Green 100 / Red 100).
  Color get backgroundColor {
    switch (this) {
      case LeaveStatus.pending:
      case LeaveStatus.requested:
        return const Color(0xFFFEF3C7); // Amber 100
      case LeaveStatus.approved:
        return const Color(0xFFDCFCE7); // Green 100
      case LeaveStatus.rejected:
        return const Color(0xFFFEE2E2); // Red 100
    }
  }

  /// Warna dot 6px di dalam badge (Amber 500 / Green 600 / Red 500).
  Color get dotColor {
    switch (this) {
      case LeaveStatus.pending:
      case LeaveStatus.requested:
        return const Color(0xFFF59E0B);
      case LeaveStatus.approved:
        return const Color(0xFF16A34A);
      case LeaveStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

/// Model item pengajuan cuti/izin (Leave & Time Off).
///
/// Di-render oleh `LeaveRequestCard` yang memakai widget global
/// `EmployeeInfoRow` untuk identitas pegawai. Equatable dipakai agar
/// state BLoC bisa dibandingkan (props list item).
class LeaveRequestItem extends Equatable {
  final String id;

  // ── Identitas pegawai ────────────────────────────────────────────────
  final String employeeId;
  final String name;
  final String role;
  final String department;
  final String company;
  final String? employeeNumber;
  final String? avatarUrl;
  final String initials;

  // ── Data pengajuan ───────────────────────────────────────────────────
  /// Jenis cuti, mis. "Annual Leave", "Sick Leave".
  final String leaveType;

  /// Jumlah hari cuti.
  final int days;

  /// Tanggal mulai pengajuan.
  final DateTime? startDate;

  /// Tanggal selesai pengajuan.
  final DateTime? endDate;

  /// Catatan/alasan, mis. "Attending technical conference out of town."
  final String notes;
  String get note => notes;

  final LeaveStatus status;

  /// Zona waktu pengajuan, mis. "WIB".
  final String timezone;

  /// True jika pengajuan milik user sendiri (tab "My Requests").
  final bool isSelf;

  const LeaveRequestItem({
    required this.id,
    this.employeeId = '',
    required this.name,
    this.role = 'Staff',
    this.department = 'Umum',
    this.company = '',
    this.employeeNumber,
    this.avatarUrl,
    required this.initials,
    required this.leaveType,
    this.days = 1,
    this.startDate,
    this.endDate,
    String? note,
    String notes = '',
    this.status = LeaveStatus.pending,
    this.timezone = 'WIB',
    this.isSelf = false,
  }) : notes = note ?? notes;

  /// Durasi terformat, mis. "3 Days" / "1 Day".
  String get durationLabel => days == 1 ? '1 Day' : '$days Days';

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Rentang tanggal terformat, mis. "28 Agu 2026 - 30 Agu 2026"
  /// atau "27 Agu 2026" jika satu hari saja.
  String get dateRangeLabel {
    final start = startDate;
    final end = endDate;
    if (start == null && end == null) return '-';

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

    if (start == null) return fmt(end!);
    if (end == null) return fmt(start);

    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return sameDay ? fmt(start) : '${fmt(start)} - ${fmt(end)}';
  }

  LeaveRequestItem copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? role,
    String? department,
    String? company,
    String? employeeNumber,
    String? avatarUrl,
    String? initials,
    String? leaveType,
    int? days,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    LeaveStatus? status,
    String? timezone,
    bool? isSelf,
  }) {
    return LeaveRequestItem(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      company: company ?? this.company,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      leaveType: leaveType ?? this.leaveType,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      timezone: timezone ?? this.timezone,
      isSelf: isSelf ?? this.isSelf,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    name,
    role,
    department,
    company,
    employeeNumber,
    avatarUrl,
    initials,
    leaveType,
    days,
    startDate,
    endDate,
    notes,
    status,
    timezone,
    isSelf,
  ];
}
