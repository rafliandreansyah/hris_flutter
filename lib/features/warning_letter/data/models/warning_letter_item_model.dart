import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Ringkasan tipe surat peringatan di dalam item data.
class WarningLetterTypeSummary extends Equatable {
  final int level;
  final String name;

  const WarningLetterTypeSummary({
    required this.level,
    required this.name,
  });

  factory WarningLetterTypeSummary.fromJson(Map<String, dynamic> json) {
    return WarningLetterTypeSummary(
      level: (json['level'] is num) ? (json['level'] as num).toInt() : 1,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [level, name];
}

/// Organisasi sederhana (Perusahaan, Departemen, Posisi) di dalam employee info.
class WarningLetterOrgUnit extends Equatable {
  final String id;
  final String name;
  final String? code;

  const WarningLetterOrgUnit({
    required this.id,
    required this.name,
    this.code,
  });

  factory WarningLetterOrgUnit.fromJson(Map<String, dynamic> json) {
    return WarningLetterOrgUnit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
    };
  }

  @override
  List<Object?> get props => [id, name, code];
}

/// Informasi pegawai penerima / subjek surat peringatan.
class WarningLetterEmployee extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final WarningLetterOrgUnit? company;
  final WarningLetterOrgUnit? department;
  final WarningLetterOrgUnit? position;
  final String? photoUrl;

  const WarningLetterEmployee({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.idNumber,
    this.employeeNumber,
    this.company,
    this.department,
    this.position,
    this.photoUrl,
  });

  factory WarningLetterEmployee.fromJson(Map<String, dynamic> json) {
    return WarningLetterEmployee(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? WarningLetterOrgUnit.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? WarningLetterOrgUnit.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? WarningLetterOrgUnit.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'idNumber': idNumber,
      'employeeNumber': employeeNumber,
      'company': company?.toJson(),
      'department': department?.toJson(),
      'position': position?.toJson(),
      'photoUrl': photoUrl,
    };
  }

  /// Nama lengkap pegawai
  String get fullName {
    final last = lastName?.trim();
    if (last != null && last.isNotEmpty) {
      return '$firstName $last'.trim();
    }
    return firstName.trim();
  }

  /// Inisial 1-2 huruf
  String get initials {
    final parts = fullName.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'EM';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        idNumber,
        employeeNumber,
        company,
        department,
        position,
        photoUrl,
      ];
}

/// Item surat peringatan pada response daftar API.
class WarningLetterItem extends Equatable {
  final String id;
  final WarningLetterTypeSummary warningLetterType;
  final WarningLetterEmployee? employee;
  final bool isActive;
  final DateTime? createdAt;
  final String timezone;

  const WarningLetterItem({
    required this.id,
    required this.warningLetterType,
    this.employee,
    required this.isActive,
    this.createdAt,
    required this.timezone,
  });

  factory WarningLetterItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    return WarningLetterItem(
      id: json['id']?.toString() ?? '',
      warningLetterType: json['warningLetterType'] is Map<String, dynamic>
          ? WarningLetterTypeSummary.fromJson(
              json['warningLetterType'] as Map<String, dynamic>,
            )
          : const WarningLetterTypeSummary(level: 1, name: 'Surat Peringatan'),
      employee: json['employee'] is Map<String, dynamic>
          ? WarningLetterEmployee.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
      isActive: json['isActive'] == true,
      createdAt: parsedCreatedAt,
      timezone: json['timezone']?.toString() ?? 'WIB',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warningLetterType': warningLetterType.toJson(),
      'employee': employee?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'timezone': timezone,
    };
  }

  /// Label badge tingkat SP (contoh: "SP 1", "SP 2", "SP 3")
  String get levelBadgeLabel {
    if (warningLetterType.level > 0) {
      return 'SP ${warningLetterType.level}';
    }
    return 'SP';
  }

  /// Format tanggal pembuatan yang rapi, contoh: "29 Agustus 2026, 12:47 WIB"
  String get formattedCreatedAt {
    if (createdAt == null) return '-';
    try {
      final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(createdAt!);
      return '$dateStr $timezone'.trim();
    } catch (_) {
      try {
        final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(createdAt!);
        return '$dateStr $timezone'.trim();
      } catch (_) {
        return createdAt!.toString();
      }
    }
  }

  @override
  List<Object?> get props => [
        id,
        warningLetterType,
        employee,
        isActive,
        createdAt,
        timezone,
      ];
}
