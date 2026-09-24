import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Informasi kategori aset ringkas di dalam item penugasan.
class AssetCategoryInfoModel extends Equatable {
  final String id;
  final String name;
  final String code;

  const AssetCategoryInfoModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory AssetCategoryInfoModel.fromJson(Map<String, dynamic> json) {
    return AssetCategoryInfoModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
      };

  @override
  List<Object?> get props => [id, name, code];
}

/// Informasi calon penerima alih tangan saat status aktif sedang dialihkan.
class PendingTransferToModel extends Equatable {
  final String assignmentId;
  final String employeeId;
  final String employeeName;
  final DateTime? requestedAt;

  const PendingTransferToModel({
    required this.assignmentId,
    required this.employeeId,
    required this.employeeName,
    this.requestedAt,
  });

  factory PendingTransferToModel.fromJson(Map<String, dynamic> json) {
    return PendingTransferToModel(
      assignmentId: json['assignmentId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'requestedAt': requestedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [assignmentId, employeeId, employeeName, requestedAt];
}

/// Informasi inisiator alih tangan saat status menunggu konfirmasi saya.
class TransferredFromModel extends Equatable {
  final String assignmentId;
  final String employeeId;
  final String employeeName;
  final String conditionOnCheckout;
  final String? checkoutNotes;
  final String? department;

  const TransferredFromModel({
    required this.assignmentId,
    required this.employeeId,
    required this.employeeName,
    this.conditionOnCheckout = 'GOOD',
    this.checkoutNotes,
    this.department,
  });

  factory TransferredFromModel.fromJson(Map<String, dynamic> json) {
    return TransferredFromModel(
      assignmentId: json['assignmentId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      conditionOnCheckout: json['conditionOnCheckout'] as String? ?? 'GOOD',
      checkoutNotes: json['checkoutNotes'] as String?,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'conditionOnCheckout': conditionOnCheckout,
        'checkoutNotes': checkoutNotes,
        'department': department,
      };

  /// Dua huruf inisial nama karyawan pengalih
  String get initials {
    final parts = employeeName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '??';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Nama ringkas pemberi (misal: "Rina S.")
  String get shortName {
    final parts = employeeName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return employeeName;
    return '${parts[0]} ${parts[1][0]}.';
  }

  @override
  List<Object?> get props => [
        assignmentId,
        employeeId,
        employeeName,
        conditionOnCheckout,
        checkoutNotes,
        department,
      ];
}

/// Item representasi aset fisik atau penugasan fasilitas.
class AssetListItem extends Equatable {
  final String id;
  final String? assignmentId;
  final String assetCode;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String status;
  final String condition;
  final String? location;
  final String? photoUrl;
  final DateTime? assignedDate;
  final String? conditionOnCheckout;
  final String? checkoutNotes;
  final String? agreementUrl;
  final AssetCategoryInfoModel? category;
  final bool isPendingTransfer;
  final PendingTransferToModel? pendingTransferTo;
  final TransferredFromModel? transferredFrom;

  const AssetListItem({
    required this.id,
    this.assignmentId,
    required this.assetCode,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    required this.status,
    this.condition = 'GOOD',
    this.location,
    this.photoUrl,
    this.assignedDate,
    this.conditionOnCheckout,
    this.checkoutNotes,
    this.agreementUrl,
    this.category,
    this.isPendingTransfer = false,
    this.pendingTransferTo,
    this.transferredFrom,
  });

  factory AssetListItem.fromJson(Map<String, dynamic> json) {
    return AssetListItem(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String?,
      assetCode: json['assetCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      condition: json['condition'] as String? ?? 'GOOD',
      location: json['location'] as String?,
      photoUrl: json['photoUrl'] as String?,
      assignedDate: json['assignedDate'] != null
          ? DateTime.tryParse(json['assignedDate'].toString())
          : null,
      conditionOnCheckout: json['conditionOnCheckout'] as String?,
      checkoutNotes: json['checkoutNotes'] as String?,
      agreementUrl: json['agreementUrl'] as String?,
      category: json['category'] != null && json['category'] is Map<String, dynamic>
          ? AssetCategoryInfoModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      isPendingTransfer: json['isPendingTransfer'] as bool? ?? false,
      pendingTransferTo: json['pendingTransferTo'] != null &&
              json['pendingTransferTo'] is Map<String, dynamic>
          ? PendingTransferToModel.fromJson(
              json['pendingTransferTo'] as Map<String, dynamic>)
          : null,
      transferredFrom: json['transferredFrom'] != null &&
              json['transferredFrom'] is Map<String, dynamic>
          ? TransferredFromModel.fromJson(
              json['transferredFrom'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignmentId': assignmentId,
        'assetCode': assetCode,
        'name': name,
        'brand': brand,
        'model': model,
        'serialNumber': serialNumber,
        'status': status,
        'condition': condition,
        'location': location,
        'photoUrl': photoUrl,
        'assignedDate': assignedDate?.toIso8601String(),
        'conditionOnCheckout': conditionOnCheckout,
        'checkoutNotes': checkoutNotes,
        'agreementUrl': agreementUrl,
        'category': category?.toJson(),
        'isPendingTransfer': isPendingTransfer,
        'pendingTransferTo': pendingTransferTo?.toJson(),
        'transferredFrom': transferredFrom?.toJson(),
      };

  // Status Helpers
  bool get isPendingAcceptance => status.toUpperCase() == 'PENDING_ACCEPTANCE';
  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isReturned => status.toUpperCase() == 'RETURNED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';

  /// Label teks status fasilitas untuk badge M3
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING_ACCEPTANCE':
        return 'Menunggu';
      case 'ACTIVE':
        return 'Aktif';
      case 'RETURNED':
        return 'Dikembalikan';
      case 'REJECTED':
        return 'Ditolak';
      case 'AVAILABLE':
        return 'Tersedia';
      default:
        return status;
    }
  }

  /// Warna badge background sesuai Stitch M3
  Color get statusBadgeBgColor {
    switch (status.toUpperCase()) {
      case 'PENDING_ACCEPTANCE':
        return const Color(0xFFFEF3C7); // Amber 100
      case 'ACTIVE':
        return const Color(0xFFECFDF5); // Emerald 50
      case 'RETURNED':
        return const Color(0xFFF1F5F9); // Slate 100
      case 'REJECTED':
        return const Color(0xFFFEE2E2); // Red 100
      case 'AVAILABLE':
        return const Color(0xFFEFF6FF); // Blue 50
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  /// Warna teks status badge
  Color get statusBadgeTextColor {
    switch (status.toUpperCase()) {
      case 'PENDING_ACCEPTANCE':
        return const Color(0xFF92400E); // Amber 800
      case 'ACTIVE':
        return const Color(0xFF047857); // Emerald 700
      case 'RETURNED':
        return const Color(0xFF475569); // Slate 600
      case 'REJECTED':
        return const Color(0xFFB91C1C); // Red 700
      case 'AVAILABLE':
        return const Color(0xFF1D4ED8); // Blue 700
      default:
        return const Color(0xFF475569);
    }
  }

  /// Warna border badge
  Color get statusBadgeBorderColor {
    switch (status.toUpperCase()) {
      case 'PENDING_ACCEPTANCE':
        return const Color(0xFFFCD34D); // Amber 300
      case 'ACTIVE':
        return const Color(0xFFA7F3D0); // Emerald 200
      case 'RETURNED':
        return const Color(0xFFCBD5E1); // Slate 300
      case 'REJECTED':
        return const Color(0xFFFECACA); // Red 200
      case 'AVAILABLE':
        return const Color(0xFFBFDBFE); // Blue 200
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  /// Icon kategori aset sesuai Stitch M3
  IconData get categoryIcon {
    final catCode = category?.code.toUpperCase() ?? '';
    final catName = category?.name.toUpperCase() ?? '';
    final n = name.toUpperCase();

    if (catCode.contains('LPT') ||
        catCode.contains('LAPTOP') ||
        catName.contains('LAPTOP') ||
        n.contains('MACBOOK') ||
        n.contains('LAPTOP') ||
        n.contains('NOTEBOOK') ||
        n.contains('DELL') ||
        n.contains('THINKPAD')) {
      return LucideIcons.laptop;
    }
    if (catCode.contains('PHN') ||
        catCode.contains('PHONE') ||
        catName.contains('SMARTPHONE') ||
        catName.contains('HP') ||
        catName.contains('PONSEL') ||
        n.contains('IPHONE') ||
        n.contains('GALAXY') ||
        n.contains('SAMSUNG') ||
        n.contains('XIAOMI')) {
      return LucideIcons.smartphone;
    }
    if (catCode.contains('VCL') ||
        catCode.contains('CAR') ||
        catName.contains('KENDARAAN') ||
        catName.contains('MOBIL') ||
        catName.contains('MOTOR') ||
        n.contains('INNOVA') ||
        n.contains('AVANZA') ||
        n.contains('ZENIX') ||
        n.contains('HYBRID')) {
      return LucideIcons.car;
    }
    if (catCode.contains('OFFICE') ||
        catCode.contains('MON') ||
        catName.contains('KANTOR') ||
        catName.contains('MONITOR') ||
        catName.contains('PRINTER') ||
        n.contains('MONITOR') ||
        n.contains('PRINTER')) {
      return LucideIcons.monitor;
    }
    return LucideIcons.packageCheck;
  }

  /// Tanggal serah terima terformat
  String get formattedAssignedDate {
    if (assignedDate == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(assignedDate!);
  }

  /// Subtitle string untuk active card: "[Kategori] • Sejak [Tanggal]"
  String get subtitleInfo {
    final cat = category?.name ?? 'Fasilitas';
    if (assignedDate != null) {
      return '$cat • Sejak $formattedAssignedDate';
    }
    return cat;
  }

  @override
  List<Object?> get props => [
        id,
        assignmentId,
        assetCode,
        name,
        brand,
        model,
        serialNumber,
        status,
        condition,
        assignedDate,
        isPendingTransfer,
        pendingTransferTo,
        transferredFrom,
      ];
}

/// Metadata paginasi untuk daftar aset
class AssetPaginationMeta extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AssetPaginationMeta({
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 1,
  });

  factory AssetPaginationMeta.fromJson(Map<String, dynamic> json) {
    return AssetPaginationMeta(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? (json['size'] as int? ?? 10),
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
      };

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

/// Response model untuk GET /api/v1/assets
class AssetListResponse extends Equatable {
  final bool success;
  final String message;
  final List<AssetListItem> data;
  final AssetPaginationMeta? meta;

  const AssetListResponse({
    this.success = true,
    this.message = '',
    this.data = const [],
    this.meta,
  });

  factory AssetListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ?? [];
    final items = list
        .map((e) => AssetListItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return AssetListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: items,
      meta: json['meta'] != null && json['meta'] is Map<String, dynamic>
          ? AssetPaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, data, meta];
}
