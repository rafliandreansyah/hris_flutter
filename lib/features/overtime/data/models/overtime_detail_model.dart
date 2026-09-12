import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

/// Nama-nama bulan dalam bahasa Indonesia untuk formatting tanggal.
const List<String> _monthsIndonesian = [
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

/// Model data inti untuk Detail Pengajuan Lembur dari endpoint `GET /overtime/{id}`.
class OvertimeDetailData extends Equatable {
  final String id;
  final DateTime? startOvertime;
  final DateTime? endOvertime;
  final String? notes;
  final String status;
  final OvertimeEmployeeModel employee;
  final OvertimeEmployeeModel? approver;
  final String? approverNotes;
  final String? filePath;
  final String? timezone;
  final DateTime? createdAt;

  const OvertimeDetailData({
    required this.id,
    this.startOvertime,
    this.endOvertime,
    this.notes,
    required this.status,
    required this.employee,
    this.approver,
    this.approverNotes,
    this.filePath,
    this.timezone,
    this.createdAt,
  });

  factory OvertimeDetailData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return OvertimeDetailData(
      id: json['id']?.toString() ?? '',
      startOvertime: parseDate(json['startOvertime']),
      endOvertime: parseDate(json['endOvertime']),
      notes: json['notes']?.toString() ??
          json['note']?.toString() ??
          json['reason']?.toString(),
      status: json['status']?.toString() ?? 'requested',
      employee: json['employee'] is Map<String, dynamic>
          ? OvertimeEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : const OvertimeEmployeeModel(
              id: '',
              firstName: 'Pegawai',
            ),
      approver: json['approver'] is Map<String, dynamic>
          ? OvertimeEmployeeModel.fromJson(
              json['approver'] as Map<String, dynamic>,
            )
          : null,
      approverNotes: json['approverNotes']?.toString() ??
          json['approverNote']?.toString(),
      filePath: json['filePath']?.toString(),
      timezone: json['timezone']?.toString() ?? 'WIB',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startOvertime': startOvertime?.toIso8601String(),
        'endOvertime': endOvertime?.toIso8601String(),
        'notes': notes,
        'status': status,
        'employee': {
          'id': employee.id,
          'firstName': employee.firstName,
          'lastName': employee.lastName,
          'email': employee.email,
          'phone': employee.phone,
          'idNumber': employee.idNumber,
          'employeeNumber': employee.employeeNumber,
          'company': employee.company != null
              ? {'id': employee.company!.id, 'name': employee.company!.name}
              : null,
          'department': employee.department != null
              ? {'id': employee.department!.id, 'name': employee.department!.name}
              : null,
          'position': employee.position != null
              ? {'id': employee.position!.id, 'name': employee.position!.name}
              : null,
          'photoUrl': employee.photoUrl,
        },
        'approver': approver != null
            ? {
                'id': approver!.id,
                'firstName': approver!.firstName,
                'lastName': approver!.lastName,
                'email': approver!.email,
                'phone': approver!.phone,
                'idNumber': approver!.idNumber,
                'employeeNumber': approver!.employeeNumber,
                'company': approver!.company != null
                    ? {'id': approver!.company!.id, 'name': approver!.company!.name}
                    : null,
                'department': approver!.department != null
                    ? {
                        'id': approver!.department!.id,
                        'name': approver!.department!.name
                      }
                    : null,
                'position': approver!.position != null
                    ? {
                        'id': approver!.position!.id,
                        'name': approver!.position!.name
                      }
                    : null,
                'photoUrl': approver!.photoUrl,
              }
            : null,
        'approverNotes': approverNotes,
        'filePath': filePath,
        'timezone': timezone,
        'createdAt': createdAt?.toIso8601String(),
      };

  OvertimeDetailData copyWith({
    String? id,
    DateTime? startOvertime,
    DateTime? endOvertime,
    String? notes,
    String? status,
    OvertimeEmployeeModel? employee,
    OvertimeEmployeeModel? approver,
    bool clearApprover = false,
    String? approverNotes,
    bool clearApproverNotes = false,
    String? filePath,
    bool clearFilePath = false,
    String? timezone,
    DateTime? createdAt,
  }) {
    return OvertimeDetailData(
      id: id ?? this.id,
      startOvertime: startOvertime ?? this.startOvertime,
      endOvertime: endOvertime ?? this.endOvertime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      employee: employee ?? this.employee,
      approver: clearApprover ? null : (approver ?? this.approver),
      approverNotes:
          clearApproverNotes ? null : (approverNotes ?? this.approverNotes),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==========================================
  // --- STATUS HELPERS (requested, approved, rejected) ---
  // ==========================================

  /// Status masih dalam permohonan / menunggu persetujuan
  bool get isRequested {
    final s = status.trim().toLowerCase();
    return s == 'requested' || s == 'pending';
  }

  /// Alias isPending untuk konsistensi
  bool get isPending => isRequested;

  /// Status sudah disetujui
  bool get isApproved {
    final s = status.trim().toLowerCase();
    return s == 'approved' || s.contains('approv');
  }

  /// Status ditolak
  bool get isRejected {
    final s = status.trim().toLowerCase();
    return s == 'rejected' || s.contains('reject');
  }

  String get statusLabel {
    if (isApproved) return 'Approved';
    if (isRejected) return 'Rejected';
    return 'Pending Approval';
  }

  // ==========================================
  // --- DATE & TIME FORMATTING HELPERS ---
  // ==========================================

  /// Format tanggal utama (misal: "28 Agustus 2026")
  String get formattedDate {
    final date = startOvertime ?? endOvertime;
    if (date == null) return '-';
    final monthName = _monthsIndonesian[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  /// Format rentang waktu lembur (misal: "17:00 - 21:00 WIB")
  String get formattedTimeRange {
    if (startOvertime == null && endOvertime == null) return '-';

    String fmtTime(DateTime dt) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final startStr = startOvertime != null ? fmtTime(startOvertime!) : '--:--';
    final endStr = endOvertime != null ? fmtTime(endOvertime!) : '--:--';
    final tz = (timezone != null && timezone!.trim().isNotEmpty)
        ? timezone!.trim()
        : 'WIB';

    return '$startStr - $endStr $tz';
  }

  /// Total durasi lembur dalam satuan jam
  double get durationHours {
    if (startOvertime == null || endOvertime == null) return 0.0;
    final diff = endOvertime!.difference(startOvertime!);
    final hours = diff.inMinutes / 60.0;
    return hours > 0 ? hours : 0.0;
  }

  /// Label durasi lembur (misal: "4 Jam Kerja" atau "3.5 Jam Kerja")
  String get durationHoursLabel {
    final hours = durationHours;
    if (hours <= 0) return '0 Jam Kerja';

    // Format integer jika bulat, atau 1 desimal jika pecahan
    final formatted = (hours % 1 == 0)
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
    return '$formatted Jam Kerja';
  }

  /// Format waktu pengajuan (misal: "28 Agustus 2026, 09:33 WIB")
  String get formattedCreatedAt {
    final dt = createdAt ?? startOvertime;
    if (dt == null) return '-';

    final monthName = _monthsIndonesian[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final tz = (timezone != null && timezone!.trim().isNotEmpty)
        ? timezone!.trim()
        : 'WIB';

    return '${dt.day} $monthName ${dt.year}, $hour:$minute $tz';
  }

  /// URL file bukti lembur yang sudah ter-resolve path absolutnya
  String? get resolvedFilePath => resolveFileUrl(filePath);

  @override
  List<Object?> get props => [
        id,
        startOvertime,
        endOvertime,
        notes,
        status,
        employee,
        approver,
        approverNotes,
        filePath,
        timezone,
        createdAt,
      ];
}

/// Pembungkus respons dari `GET /overtime/{id}`
class OvertimeDetailResponse extends Equatable {
  final bool success;
  final String message;
  final OvertimeDetailData data;

  const OvertimeDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OvertimeDetailResponse.fromJson(Map<String, dynamic> json) {
    return OvertimeDetailResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: OvertimeDetailData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.toJson(),
      };

  @override
  List<Object?> get props => [success, message, data];
}

/// Payload request untuk `PATCH /overtime/{id}/approve`
class OvertimeApprovePayload {
  final bool isApproved;
  final String? approverNotes;

  const OvertimeApprovePayload({
    required this.isApproved,
    this.approverNotes,
  });

  Map<String, dynamic> toJson() => {
        'isApproved': isApproved,
        'approverNotes': approverNotes ?? '',
        'approverNote': approverNotes ?? '',
      };
}
