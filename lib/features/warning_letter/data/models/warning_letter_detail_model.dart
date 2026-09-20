import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';

class WarningLetterDetail extends Equatable {
  final String id;
  final WarningLetterTypeSummary warningLetterType;
  final String? referenceNumber;
  final String? attachmentUrl;
  final String? infractionReason;
  final String? sanction;
  final WarningLetterEmployee? employee;
  final DateTime? issuedDate;
  final DateTime? expiredDate;
  final String timezone;
  final bool isActive;
  final WarningLetterEmployee? issuedByEmployee;
  final DateTime? createdAt;

  const WarningLetterDetail({
    required this.id,
    required this.warningLetterType,
    this.referenceNumber,
    this.attachmentUrl,
    this.infractionReason,
    this.sanction,
    this.employee,
    this.issuedDate,
    this.expiredDate,
    required this.timezone,
    required this.isActive,
    this.issuedByEmployee,
    this.createdAt,
  });

  factory WarningLetterDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return WarningLetterDetail(
      id: json['id']?.toString() ?? '',
      warningLetterType: json['warningLetterType'] is Map<String, dynamic>
          ? WarningLetterTypeSummary.fromJson(
              json['warningLetterType'] as Map<String, dynamic>,
            )
          : const WarningLetterTypeSummary(level: 1, name: 'Surat Peringatan'),
      referenceNumber: json['referenceNumber']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      infractionReason: json['infractionReason']?.toString(),
      sanction: json['sanction']?.toString(),
      employee: json['employee'] is Map<String, dynamic>
          ? WarningLetterEmployee.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
      issuedDate: parseDate(json['issuedDate']),
      expiredDate: parseDate(json['expiredDate']),
      timezone: json['timezone']?.toString() ?? 'WIB',
      isActive: json['isActive'] == true,
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
      'employee': employee?.toJson(),
      'issuedDate': issuedDate?.toIso8601String(),
      'expiredDate': expiredDate?.toIso8601String(),
      'timezone': timezone,
      'isActive': isActive,
      'issuedByEmployee': issuedByEmployee?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get displayTitle {
    final reason = infractionReason?.trim();
    if (reason != null && reason.isNotEmpty) {
      return reason;
    }
    return warningLetterType.name;
  }

  String get levelBadgeLabel {
    if (warningLetterType.level > 0) {
      return 'Surat Peringatan ${warningLetterType.level} (SP ${warningLetterType.level})';
    }
    return warningLetterType.name;
  }

  String get formattedIssuedDate {
    if (issuedDate == null) return '-';
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(issuedDate!);
    } catch (_) {
      try {
        return DateFormat('d MMM yyyy').format(issuedDate!);
      } catch (_) {
        return issuedDate!.toString();
      }
    }
  }

  String get formattedExpiredDate {
    if (expiredDate == null) return '-';
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(expiredDate!);
    } catch (_) {
      try {
        return DateFormat('d MMM yyyy').format(expiredDate!);
      } catch (_) {
        return expiredDate!.toString();
      }
    }
  }

  String get formattedPeriod {
    if (issuedDate != null && expiredDate != null) {
      return '$formattedIssuedDate – $formattedExpiredDate';
    } else if (issuedDate != null) {
      return '$formattedIssuedDate – Seterusnya';
    }
    return '-';
  }

  String get formattedCreatedAt {
    if (createdAt == null) return '-';
    try {
      final dateStr = DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(createdAt!);
      return '$dateStr $timezone'.trim();
    } catch (_) {
      try {
        final dateStr = DateFormat('d MMM yyyy, HH:mm').format(createdAt!);
        return '$dateStr $timezone'.trim();
      } catch (_) {
        return createdAt!.toString();
      }
    }
  }

  String get attachmentFileName {
    if (attachmentUrl == null || attachmentUrl!.isEmpty) {
      final ref = referenceNumber?.replaceAll(RegExp(r'[^\w\-]'), '_') ?? id;
      return 'Surat_Peringatan_$ref.pdf';
    }
    try {
      final uri = Uri.parse(attachmentUrl!);
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (segment.isNotEmpty) {
        return Uri.decodeComponent(segment);
      }
    } catch (_) {}
    final ref = referenceNumber?.replaceAll(RegExp(r'[^\w\-]'), '_') ?? id;
    return 'Surat_Peringatan_$ref.pdf';
  }

  bool get hasAttachment =>
      attachmentUrl != null && attachmentUrl!.trim().isNotEmpty;

  bool get isAttachmentImage {
    if (!hasAttachment) return false;
    final cleanUrl = attachmentUrl!.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.webp') ||
        cleanUrl.endsWith('.heic') ||
        cleanUrl.endsWith('.gif') ||
        cleanUrl.endsWith('.bmp');
  }

  bool get isAttachmentPdf {
    if (!hasAttachment) return false;
    if (isAttachmentImage) return false;
    final cleanUrl = attachmentUrl!.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.pdf') || cleanUrl.contains('pdf');
  }

  @override
  List<Object?> get props => [
        id,
        warningLetterType,
        referenceNumber,
        attachmentUrl,
        infractionReason,
        sanction,
        employee,
        issuedDate,
        expiredDate,
        timezone,
        isActive,
        issuedByEmployee,
        createdAt,
      ];
}

class WarningLetterDetailResponse extends Equatable {
  final bool success;
  final String message;
  final WarningLetterDetail data;

  const WarningLetterDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory WarningLetterDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Data detail surat peringatan tidak ditemukan.');
    }

    return WarningLetterDetailResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: WarningLetterDetail.fromJson(rawData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}
