import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

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

/// Model representasi data detail permohonan presensi luar kantor
/// dari endpoint `GET /attendances/requests/{id}`.
class AttendanceRequestDetailData extends Equatable {
  final String id;
  final AttendanceRequestEmployeeModel employee;
  final AttendanceRequestEmployeeModel? approver;
  final String status;
  final String method;
  final String? reason;
  final String? attendanceType;
  final DateTime? attendanceTime;
  final DateTime? attendanceInTime;
  final DateTime? attendanceOutTime;
  final String? approverNote;
  final String? filePath;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? filePathOut;
  final double? latitudeOut;
  final double? longitudeOut;
  final String? addressOut;
  final DateTime? createdAt;
  final String timezone;

  const AttendanceRequestDetailData({
    required this.id,
    required this.employee,
    this.approver,
    required this.status,
    required this.method,
    this.reason,
    this.attendanceType,
    this.attendanceTime,
    this.attendanceInTime,
    this.attendanceOutTime,
    this.approverNote,
    this.filePath,
    this.latitude,
    this.longitude,
    this.address,
    this.filePathOut,
    this.latitudeOut,
    this.longitudeOut,
    this.addressOut,
    this.createdAt,
    this.timezone = 'WIB',
  });

  factory AttendanceRequestDetailData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    final rawType = (json['attendanceType'] ?? json['type'])?.toString();
    final normType = rawType?.toLowerCase().trim();

    final aTime = parseDate(json['attendanceTime']);
    final inTime = parseDate(json['attendanceInTime'] ??
        json['clockIn'] ??
        (normType == 'in' ? json['attendanceTime'] : null));
    final outTime = parseDate(json['attendanceOutTime'] ??
        json['clockOut'] ??
        (normType == 'out' ? json['attendanceTime'] : null));

    return AttendanceRequestDetailData(
      id: json['id']?.toString() ?? '',
      employee: json['employee'] is Map<String, dynamic>
          ? AttendanceRequestEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : const AttendanceRequestEmployeeModel(
              id: '',
              firstName: 'Pegawai',
            ),
      approver: json['approver'] is Map<String, dynamic>
          ? AttendanceRequestEmployeeModel.fromJson(
              json['approver'] as Map<String, dynamic>,
            )
          : null,
      status: json['status']?.toString() ?? 'requested',
      method: json['method']?.toString() ?? 'photo',
      reason: json['reason']?.toString() ??
          json['notes']?.toString() ??
          json['description']?.toString(),
      attendanceType: rawType,
      attendanceTime: aTime,
      attendanceInTime: inTime,
      attendanceOutTime: outTime,
      approverNote: json['approverNote']?.toString() ??
          json['approverNotes']?.toString() ??
          json['approver_note']?.toString(),
      filePath: resolveFileUrl(json['filePath']?.toString()),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      address: json['address']?.toString(),
      filePathOut: resolveFileUrl(json['filePathOut']?.toString()),
      latitudeOut: parseDouble(json['latitudeOut']),
      longitudeOut: parseDouble(json['longitudeOut']),
      addressOut: json['addressOut']?.toString(),
      createdAt: parseDate(json['createdAt']),
      timezone: json['timezone']?.toString() ?? 'WIB',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee': {
          'id': employee.id,
          'firstName': employee.firstName,
          'lastName': employee.lastName,
          'email': employee.email,
          'phone': employee.phone,
          'employeeNumber': employee.employeeNumber,
          'company': employee.company != null
              ? {'id': employee.company!.id, 'name': employee.company!.name}
              : null,
          'department': employee.department != null
              ? {
                  'id': employee.department!.id,
                  'name': employee.department!.name
                }
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
                'employeeNumber': approver!.employeeNumber,
                'company': approver!.company != null
                    ? {
                        'id': approver!.company!.id,
                        'name': approver!.company!.name
                      }
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
        'status': status,
        'method': method,
        'reason': reason,
        'attendanceType': attendanceType,
        'attendanceTime': attendanceTime?.toIso8601String(),
        'attendanceInTime': attendanceInTime?.toIso8601String(),
        'attendanceOutTime': attendanceOutTime?.toIso8601String(),
        'approverNote': approverNote,
        'filePath': filePath,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'filePathOut': filePathOut,
        'latitudeOut': latitudeOut,
        'longitudeOut': longitudeOut,
        'addressOut': addressOut,
        'createdAt': createdAt?.toIso8601String(),
        'timezone': timezone,
      };

  AttendanceRequestDetailData copyWith({
    String? id,
    AttendanceRequestEmployeeModel? employee,
    AttendanceRequestEmployeeModel? approver,
    bool clearApprover = false,
    String? status,
    String? method,
    String? reason,
    String? attendanceType,
    DateTime? attendanceTime,
    DateTime? attendanceInTime,
    DateTime? attendanceOutTime,
    String? approverNote,
    bool clearApproverNote = false,
    String? filePath,
    bool clearFilePath = false,
    double? latitude,
    double? longitude,
    String? address,
    String? filePathOut,
    bool clearFilePathOut = false,
    double? latitudeOut,
    double? longitudeOut,
    String? addressOut,
    DateTime? createdAt,
    String? timezone,
  }) {
    return AttendanceRequestDetailData(
      id: id ?? this.id,
      employee: employee ?? this.employee,
      approver: clearApprover ? null : (approver ?? this.approver),
      status: status ?? this.status,
      method: method ?? this.method,
      reason: reason ?? this.reason,
      attendanceType: attendanceType ?? this.attendanceType,
      attendanceTime: attendanceTime ?? this.attendanceTime,
      attendanceInTime: attendanceInTime ?? this.attendanceInTime,
      attendanceOutTime: attendanceOutTime ?? this.attendanceOutTime,
      approverNote:
          clearApproverNote ? null : (approverNote ?? this.approverNote),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      filePathOut: clearFilePathOut ? null : (filePathOut ?? this.filePathOut),
      latitudeOut: latitudeOut ?? this.latitudeOut,
      longitudeOut: longitudeOut ?? this.longitudeOut,
      addressOut: addressOut ?? this.addressOut,
      createdAt: createdAt ?? this.createdAt,
      timezone: timezone ?? this.timezone,
    );
  }

  // ==========================================
  // --- STATUS HELPERS ---
  // ==========================================

  bool get isRequested {
    final s = status.trim().toLowerCase();
    return s == 'requested' || s == 'pending';
  }

  bool get isApproved {
    final s = status.trim().toLowerCase();
    return s == 'approved' || s.contains('approv');
  }

  bool get isRejected {
    final s = status.trim().toLowerCase();
    return s == 'rejected' || s.contains('reject');
  }

  String get statusLabel {
    if (isApproved) return 'Disetujui';
    if (isRejected) return 'Ditolak';
    return 'Menunggu Persetujuan';
  }

  // ==========================================
  // --- METHOD & TYPE HELPERS ---
  // ==========================================

  /// Apakah metode presensi berupa foto
  bool get isPhotoMethod => method.trim().toLowerCase() == 'photo';

  /// Apakah presensi masuk
  bool get isIn {
    final t = attendanceType?.trim().toLowerCase();
    if (t == 'in') return true;
    if (t == 'out' || t == 'inout' || t == 'in_out' || t == 'in-out') return false;
    return attendanceOutTime == null;
  }

  /// Apakah presensi pulang
  bool get isOut => attendanceType?.trim().toLowerCase() == 'out';

  /// Apakah presensi mencakup masuk dan pulang
  bool get isInOut {
    final t = attendanceType?.trim().toLowerCase();
    return t == 'inout' || t == 'in_out' || t == 'in-out';
  }

  /// Label tipe presensi (Masuk / Pulang / Masuk & Pulang)
  String get attendanceTypeLabel {
    if (isInOut) return 'Presensi Masuk & Pulang';
    if (isOut) return 'Presensi Pulang';
    return 'Presensi Masuk';
  }

  /// Badge tipe presensi (IN / OUT / IN & OUT)
  String get attendanceTypeBadge {
    if (isInOut) return 'IN & OUT';
    if (isOut) return 'OUT';
    return 'IN';
  }

  /// Apakah koordinat masuk valid
  bool get hasValidCoordinates =>
      latitude != null &&
      longitude != null &&
      (latitude != 0.0 || longitude != 0.0);

  /// Apakah koordinat pulang valid
  bool get hasValidCoordinatesOut =>
      latitudeOut != null &&
      longitudeOut != null &&
      (latitudeOut != 0.0 || longitudeOut != 0.0);

  // ==========================================
  // --- DATE & TIME FORMATTING HELPERS ---
  // ==========================================

  /// Format tanggal utama (misal: "29 Agustus 2026")
  String get formattedDate {
    final date = attendanceInTime ?? attendanceTime ?? attendanceOutTime ?? createdAt;
    if (date == null) return '-';
    final monthName = _monthsIndonesian[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  /// Format waktu masuk (misal: "08:30 WIB")
  String get formattedInTime {
    final time = attendanceInTime ?? (isIn ? attendanceTime : null);
    if (time == null) return '-';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m $timezone';
  }

  /// Format waktu pulang (misal: "17:30 WIB")
  String get formattedOutTime {
    final time = attendanceOutTime ?? (isOut ? attendanceTime : null);
    if (time == null) return '-';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m $timezone';
  }

  /// Format info pengajuan (misal: "Diajukan: 29 Agustus 2026, 13:35 WIB • Zona Waktu: WIB")
  String get formattedSubmittedInfo {
    if (createdAt == null) return 'Zona Waktu: $timezone';
    final monthName = _monthsIndonesian[createdAt!.month - 1];
    final h = createdAt!.hour.toString().padLeft(2, '0');
    final m = createdAt!.minute.toString().padLeft(2, '0');
    return 'Diajukan: ${createdAt!.day} $monthName ${createdAt!.year}, $h:$m $timezone • Zona Waktu: $timezone';
  }

  @override
  List<Object?> get props => [
        id,
        employee,
        approver,
        status,
        method,
        reason,
        attendanceType,
        attendanceTime,
        attendanceInTime,
        attendanceOutTime,
        approverNote,
        filePath,
        latitude,
        longitude,
        address,
        filePathOut,
        latitudeOut,
        longitudeOut,
        addressOut,
        createdAt,
        timezone,
      ];
}

/// Pembungkus respons API endpoint `GET /attendances/requests/{id}`.
class AttendanceRequestDetailResponse {
  final bool success;
  final String message;
  final AttendanceRequestDetailData data;

  const AttendanceRequestDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceRequestDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AttendanceRequestDetailResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: AttendanceRequestDetailData.fromJson(rawData),
    );
  }
}
