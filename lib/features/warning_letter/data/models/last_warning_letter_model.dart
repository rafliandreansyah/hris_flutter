import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:intl/intl.dart';

/// Model untuk surat peringatan terakhir seorang pegawai
/// dari endpoint `GET /warning-letter/employee/{employeeId}/last`.
class LastWarningLetterModel extends Equatable {
  final String id;
  final WarningLetterTypeModel warningLetterType;
  final String referenceNumber;
  final String? attachmentUrl;
  final String? infractionReason;
  final String? sanction;
  final DateTime? issuedDate;
  final DateTime? expiredDate;
  final String timezone;
  final bool isActive;
  final WarningLetterEmployee? employee;
  final WarningLetterEmployee? issuedByEmployee;
  final DateTime? createdAt;

  const LastWarningLetterModel({
    required this.id,
    required this.warningLetterType,
    required this.referenceNumber,
    this.attachmentUrl,
    this.infractionReason,
    this.sanction,
    this.issuedDate,
    this.expiredDate,
    required this.timezone,
    required this.isActive,
    this.employee,
    this.issuedByEmployee,
    this.createdAt,
  });

  factory LastWarningLetterModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      return DateTime.tryParse(date.toString());
    }

    return LastWarningLetterModel(
      id: json['id']?.toString() ?? '',
      warningLetterType: json['warningLetterType'] is Map<String, dynamic>
          ? WarningLetterTypeModel.fromJson(
              json['warningLetterType'] as Map<String, dynamic>,
            )
          : const WarningLetterTypeModel(
              id: '',
              name: 'Surat Peringatan',
              level: 1,
              validityPeriodMonths: 0,
            ),
      referenceNumber: json['referenceNumber']?.toString() ?? '-',
      attachmentUrl: json['attachmentUrl']?.toString(),
      infractionReason: json['infractionReason']?.toString(),
      sanction: json['sanction']?.toString(),
      issuedDate: parseDate(json['issuedDate']),
      expiredDate: parseDate(json['expiredDate']),
      timezone: json['timezone']?.toString() ?? 'WIB',
      isActive: json['isActive'] == true,
      employee: json['employee'] is Map<String, dynamic>
          ? WarningLetterEmployee.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
      issuedByEmployee: json['issuedByEmployee'] is Map<String, dynamic>
          ? WarningLetterEmployee.fromJson(
              json['issuedByEmployee'] as Map<String, dynamic>,
            )
          : null,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warningLetterType': warningLetterType.toJson(),
      'referenceNumber': referenceNumber,
      'attachmentUrl': attachmentUrl,
      'infractionReason': infractionReason,
      'sanction': sanction,
      'issuedDate': issuedDate?.toIso8601String(),
      'expiredDate': expiredDate?.toIso8601String(),
      'timezone': timezone,
      'isActive': isActive,
      'employee': employee?.toJson(),
      'issuedByEmployee': issuedByEmployee?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Format tanggal terbit, contoh: "29 Agustus 2026"
  String get formattedIssuedDate {
    if (issuedDate == null) return '-';
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(issuedDate!);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy').format(issuedDate!);
      } catch (_) {
        return issuedDate!.toString();
      }
    }
  }

  /// Format tanggal berakhir / kedaluwarsa, contoh: "28 Februari 2027"
  String get formattedExpiredDate {
    if (expiredDate == null) return '-';
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(expiredDate!);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy').format(expiredDate!);
      } catch (_) {
        return expiredDate!.toString();
      }
    }
  }

  /// Format rentang masa berlaku: "29 Agustus 2026 s/d 28 Februari 2027"
  String get formattedPeriod {
    return '$formattedIssuedDate s/d $formattedExpiredDate';
  }

  /// Label badge tingkat SP (contoh: "SP 1", "SP 2")
  String get levelBadgeLabel {
    if (warningLetterType.level > 0) {
      return 'SP ${warningLetterType.level}';
    }
    return 'SP';
  }

  @override
  List<Object?> get props => [
        id,
        warningLetterType,
        referenceNumber,
        attachmentUrl,
        infractionReason,
        sanction,
        issuedDate,
        expiredDate,
        timezone,
        isActive,
        employee,
        issuedByEmployee,
        createdAt,
      ];
}
