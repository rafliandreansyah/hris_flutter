import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Status pengajuan presensi luar kantor pada Oasish HRIS.
enum AttendanceRequestStatus { requested, approved, rejected }

extension AttendanceRequestStatusExtension on AttendanceRequestStatus {
  String get label {
    switch (this) {
      case AttendanceRequestStatus.requested:
        return 'Menunggu';
      case AttendanceRequestStatus.approved:
        return 'Disetujui';
      case AttendanceRequestStatus.rejected:
        return 'Ditolak';
    }
  }

  /// Warna teks badge status (Amber 700 / Emerald 700 / Red 700).
  Color get textColor {
    switch (this) {
      case AttendanceRequestStatus.requested:
        return const Color(0xFFB45309);
      case AttendanceRequestStatus.approved:
        return const Color(0xFF047857);
      case AttendanceRequestStatus.rejected:
        return const Color(0xFFB91C1C);
    }
  }

  /// Warna background badge status (Amber 50 / Emerald 50 / Red 50).
  Color get backgroundColor {
    switch (this) {
      case AttendanceRequestStatus.requested:
        return const Color(0xFFFFFBEB);
      case AttendanceRequestStatus.approved:
        return const Color(0xFFECFDF5);
      case AttendanceRequestStatus.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  /// Warna dot indikator di dalam badge (Amber 500 / Emerald 600 / Red 500).
  Color get dotColor {
    switch (this) {
      case AttendanceRequestStatus.requested:
        return const Color(0xFFF59E0B);
      case AttendanceRequestStatus.approved:
        return const Color(0xFF059669);
      case AttendanceRequestStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

/// Jenis metode presensi luar kantor untuk modal bottom sheet selection.
enum AttendanceOutsideMethod {
  live,
  schedule,
}

/// Model item pengajuan presensi luar kantor (Attendance Request).
class AttendanceRequestItem extends Equatable {
  final String id;

  // ── Identitas pegawai ──────────────────────────────────────────────
  final String employeeId;
  final String name;
  final String role;
  final String department;
  final String company;
  final String? employeeNumber;
  final String? avatarUrl;
  final String initials;

  // ── Data waktu & presensi ──────────────────────────────────────────
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? workHours;
  final String notes;
  final AttendanceRequestStatus status;
  final DateTime? createdAt;
  final bool isSelf;
  final String? attendanceType;
  final String? approverNotes;

  const AttendanceRequestItem({
    required this.id,
    this.employeeId = '',
    required this.name,
    this.role = '',
    this.department = '',
    this.company = '',
    this.employeeNumber,
    this.avatarUrl,
    this.initials = '?',
    this.date,
    this.startTime,
    this.endTime,
    this.workHours,
    this.notes = '',
    this.status = AttendanceRequestStatus.requested,
    this.createdAt,
    this.isSelf = false,
    this.attendanceType,
    this.approverNotes,
  });

  /// Format tanggal presensi, e.g. "29 Agustus 2026"
  String get formattedDate {
    if (date == null) return '-';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date!.day} ${months[date!.month - 1]} ${date!.year}';
  }

  /// Format jam kerja, e.g. "Jam Kerja: Masuk 08:30 WIB s/d Pulang 17:00 WIB"
  String get formattedWorkHours {
    if (workHours != null && workHours!.trim().isNotEmpty) {
      return workHours!;
    }
    final sTime = startTime?.trim();
    final eTime = endTime?.trim();
    if (sTime != null && sTime.isNotEmpty && eTime != null && eTime.isNotEmpty) {
      return 'Jam Kerja: Masuk $sTime WIB s/d Pulang $eTime WIB';
    } else if (sTime != null && sTime.isNotEmpty) {
      return 'Jam Masuk: $sTime WIB';
    } else if (eTime != null && eTime.isNotEmpty) {
      return 'Jam Pulang: $eTime WIB';
    }
    return 'Jam Kerja: Jam Operasional Normal';
  }

  /// Format tanggal pengajuan, e.g. "Diajukan: 29 Agustus 2026, 13:35 WIB"
  String get formattedSubmittedAt {
    if (createdAt == null) return 'Diajukan: -';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final h = createdAt!.hour.toString().padLeft(2, '0');
    final m = createdAt!.minute.toString().padLeft(2, '0');
    return 'Diajukan: ${createdAt!.day} ${months[createdAt!.month - 1]} ${createdAt!.year}, $h:$m WIB';
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
        date,
        startTime,
        endTime,
        workHours,
        notes,
        status,
        createdAt,
        isSelf,
        attendanceType,
        approverNotes,
      ];
}
