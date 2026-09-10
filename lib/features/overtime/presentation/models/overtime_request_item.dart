import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Status permintaan lembur pada Oasish HRIS.
///
/// Token warna mengikuti ActivityStatusExtension (fitur aktivitas) &
/// LeaveStatusExtension agar desain badge status konsisten di seluruh app:
/// pending/requested -> amber, approved -> green, rejected -> red.
enum OvertimeStatus { pending, approved, rejected, requested }

extension OvertimeStatusExtension on OvertimeStatus {
  String get label {
    switch (this) {
      case OvertimeStatus.pending:
      case OvertimeStatus.requested:
        return 'Pending';
      case OvertimeStatus.approved:
        return 'Approved';
      case OvertimeStatus.rejected:
        return 'Rejected';
    }
  }

  /// Warna teks badge — sama persis dengan ActivityStatusExtension
  /// (Amber 700 / Green 800 / Red 800).
  Color get textColor {
    switch (this) {
      case OvertimeStatus.pending:
      case OvertimeStatus.requested:
        return const Color(0xFFB45309); // Amber 700
      case OvertimeStatus.approved:
        return const Color(0xFF166534); // Green 800
      case OvertimeStatus.rejected:
        return const Color(0xFF991B1B); // Red 800
    }
  }

  /// Warna background badge (Amber 100 / Green 100 / Red 100).
  Color get backgroundColor {
    switch (this) {
      case OvertimeStatus.pending:
      case OvertimeStatus.requested:
        return const Color(0xFFFEF3C7); // Amber 100
      case OvertimeStatus.approved:
        return const Color(0xFFDCFCE7); // Green 100
      case OvertimeStatus.rejected:
        return const Color(0xFFFEE2E2); // Red 100
    }
  }

  /// Warna dot 6px di dalam badge (Amber 500 / Green 600 / Red 500).
  Color get dotColor {
    switch (this) {
      case OvertimeStatus.pending:
      case OvertimeStatus.requested:
        return const Color(0xFFF59E0B);
      case OvertimeStatus.approved:
        return const Color(0xFF16A34A);
      case OvertimeStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

/// Model item permintaan lembur (Overtime Requests).
///
/// Di-render oleh `OvertimeRequestCard` yang memakai widget global
/// `EmployeeInfoRow` untuk identitas pegawai. Equatable dipakai agar
/// state BLoC bisa dibandingkan (props list item).
class OvertimeRequestItem extends Equatable {
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

  // ── Data lembur ──────────────────────────────────────────────────────
  /// Waktu mulai lembur (locale-app dari timestamp API).
  final DateTime? startTime;

  /// Waktu selesai lembur (locale-app dari timestamp API).
  final DateTime? endTime;

  /// Alasan lembur dari pegawai (field `notes`).
  final String note;

  /// Catatan dari approver (field `approverNotes`).
  final String approverNotes;

  final OvertimeStatus status;

  /// Zona waktu lembur, mis. "WIB".
  final String timezone;

  /// True jika permintaan milik user sendiri (tab "My Overtime").
  final bool isSelf;

  const OvertimeRequestItem({
    required this.id,
    this.employeeId = '',
    required this.name,
    this.role = 'Staff',
    this.department = 'Umum',
    this.company = '',
    this.employeeNumber,
    this.avatarUrl,
    required this.initials,
    this.startTime,
    this.endTime,
    this.note = '',
    this.approverNotes = '',
    this.status = OvertimeStatus.pending,
    this.timezone = 'WIB',
    this.isSelf = false,
  });

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

  /// Tanggal mulai terformat, mis. "28 Agu 2026".
  String get dateLabel {
    final start = startTime;
    if (start == null) return '-';
    return '${start.day.toString().padLeft(2, '0')} '
        '${_months[start.month - 1]} ${start.year}';
  }

  /// Rentang jam terformat, mis. "17:00 - 21:00".
  String get timeRangeLabel {
    final start = startTime;
    final end = endTime;
    if (start == null && end == null) return '-';

    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';

    if (start == null) return fmt(end!);
    if (end == null) return fmt(start);
    return '${fmt(start)} - ${fmt(end)}';
  }

  /// Durasi lembur dalam jam (desimal hingga 0,5).
  double get durationHours {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return 0;
    final hours = (end.difference(start).inMinutes / 60.0).clamp(0, 999);
    // Bulatkan ke kelipatan 0,5 agar rapi ("4", "4.5").
    final half = (hours * 2).round() / 2;
    return half == 0 ? 0.5 : half;
  }

  /// Label durasi, mis. "4 Jam Kerja" / "2.5 Jam Kerja".
  String get durationLabel {
    if (startTime == null || endTime == null) return '-';
    final value = durationHours;
    final text = value == value.roundToDouble()
        ? value.roundToDouble().toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text Jam Kerja';
  }

  OvertimeRequestItem copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? role,
    String? department,
    String? company,
    String? employeeNumber,
    String? avatarUrl,
    String? initials,
    DateTime? startTime,
    DateTime? endTime,
    String? note,
    String? approverNotes,
    OvertimeStatus? status,
    String? timezone,
    bool? isSelf,
  }) {
    return OvertimeRequestItem(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      company: company ?? this.company,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      approverNotes: approverNotes ?? this.approverNotes,
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
        startTime,
        endTime,
        note,
        approverNotes,
        status,
        timezone,
        isSelf,
      ];
}
