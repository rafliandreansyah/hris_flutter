import 'package:equatable/equatable.dart';

/// Response wrapper untuk endpoint GET /api/v1/assets/:id
class AssetDetailResponse extends Equatable {
  final bool success;
  final String message;
  final AssetDetailData data;

  const AssetDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AssetDetailResponse.fromJson(Map<String, dynamic> json) {
    return AssetDetailResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Detail aset berhasil dimuat',
      data: AssetDetailData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
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

/// Data detail unit aset lengkap dengan spesifikasi teknis dan riwayat penugasan
class AssetDetailData extends Equatable {
  final String id;
  final String? companyId;
  final String? categoryId;
  final String assetCode;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchaseCost;
  final DateTime? warrantyExpiry;
  final String? vendor;
  final String? location;
  final String condition;
  final String status;
  final String? photoUrl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AssetDetailCategory? category;
  final List<AssetAssignmentItemModel> assignments;

  const AssetDetailData({
    required this.id,
    this.companyId,
    this.categoryId,
    required this.assetCode,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchaseCost,
    this.warrantyExpiry,
    this.vendor,
    this.location,
    required this.condition,
    required this.status,
    this.photoUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.assignments = const [],
  });

  factory AssetDetailData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    double? parseCost(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    final rawAssignments = json['assignments'] as List<dynamic>? ?? [];
    final assignmentsList = rawAssignments
        .map((e) => AssetAssignmentItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AssetDetailData(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String?,
      categoryId: json['categoryId'] as String?,
      assetCode: json['assetCode'] as String? ?? '-',
      name: json['name'] as String? ?? '-',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      purchaseDate: parseDate(json['purchaseDate']),
      purchaseCost: parseCost(json['purchaseCost']),
      warrantyExpiry: parseDate(json['warrantyExpiry']),
      vendor: json['vendor'] as String?,
      location: json['location'] as String?,
      condition: json['condition'] as String? ?? 'GOOD',
      status: json['status'] as String? ?? 'AVAILABLE',
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      category: json['category'] != null
          ? AssetDetailCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      assignments: assignmentsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'categoryId': categoryId,
        'assetCode': assetCode,
        'name': name,
        'brand': brand,
        'model': model,
        'serialNumber': serialNumber,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'purchaseCost': purchaseCost,
        'warrantyExpiry': warrantyExpiry?.toIso8601String(),
        'vendor': vendor,
        'location': location,
        'condition': condition,
        'status': status,
        'photoUrl': photoUrl,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'category': category?.toJson(),
        'assignments': assignments.map((e) => e.toJson()).toList(),
      };

  /// Pemegang aktif saat ini jika ada penugasan berstatus ACTIVE
  AssetAssignmentItemModel? get activeAssignment {
    try {
      return assignments.firstWhere((a) => a.status == 'ACTIVE');
    } catch (_) {
      return null;
    }
  }

  /// Penugasan yang sedang menunggu persetujuan (PENDING_ACCEPTANCE)
  AssetAssignmentItemModel? get pendingAssignment {
    try {
      return assignments.firstWhere((a) => a.status == 'PENDING_ACCEPTANCE');
    } catch (_) {
      return null;
    }
  }

  /// Mengecek apakah unit sedang berada di gudang pool
  bool get isAvailableInWarehouse => status == 'AVAILABLE';

  @override
  List<Object?> get props => [
        id,
        companyId,
        categoryId,
        assetCode,
        name,
        brand,
        model,
        serialNumber,
        purchaseDate,
        purchaseCost,
        warrantyExpiry,
        vendor,
        location,
        condition,
        status,
        photoUrl,
        notes,
        createdAt,
        updatedAt,
        category,
        assignments,
      ];
}

/// Kategori yang menyertai detail aset
class AssetDetailCategory extends Equatable {
  final String id;
  final String? companyId;
  final String name;
  final String code;
  final String? description;

  const AssetDetailCategory({
    required this.id,
    this.companyId,
    required this.name,
    required this.code,
    this.description,
  });

  factory AssetDetailCategory.fromJson(Map<String, dynamic> json) {
    return AssetDetailCategory(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String?,
      name: json['name'] as String? ?? '-',
      code: json['code'] as String? ?? '-',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'name': name,
        'code': code,
        'description': description,
      };

  @override
  List<Object?> get props => [id, companyId, name, code, description];
}

/// Node riwayat penugasan aset (Chain of Custody / Timeline Node)
class AssetAssignmentItemModel extends Equatable {
  final String id;
  final String assetId;
  final String employeeId;
  final DateTime? assignedDate;
  final DateTime? expectedReturnDate;
  final DateTime? returnedDate;
  final String conditionOnCheckout;
  final String? conditionOnCheckin;
  final String? checkoutNotes;
  final String? checkinNotes;
  final String? agreementUrl;
  final String status;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? transferredFromId;
  final String? assignedById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AssetAssigneeEmployeeModel? employee;
  final AssetTransferredFromModel? transferredFrom;

  const AssetAssignmentItemModel({
    required this.id,
    required this.assetId,
    required this.employeeId,
    this.assignedDate,
    this.expectedReturnDate,
    this.returnedDate,
    required this.conditionOnCheckout,
    this.conditionOnCheckin,
    this.checkoutNotes,
    this.checkinNotes,
    this.agreementUrl,
    required this.status,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.transferredFromId,
    this.assignedById,
    this.createdAt,
    this.updatedAt,
    this.employee,
    this.transferredFrom,
  });

  factory AssetAssignmentItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return AssetAssignmentItemModel(
      id: json['id'] as String? ?? '',
      assetId: json['assetId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      assignedDate: parseDate(json['assignedDate']),
      expectedReturnDate: parseDate(json['expectedReturnDate']),
      returnedDate: parseDate(json['returnedDate']),
      conditionOnCheckout: json['conditionOnCheckout'] as String? ?? 'GOOD',
      conditionOnCheckin: json['conditionOnCheckin'] as String?,
      checkoutNotes: json['checkoutNotes'] as String?,
      checkinNotes: json['checkinNotes'] as String?,
      agreementUrl: json['agreementUrl'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      acceptedAt: parseDate(json['acceptedAt']),
      rejectedAt: parseDate(json['rejectedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      transferredFromId: json['transferredFromId'] as String?,
      assignedById: json['assignedById'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      employee: json['employee'] != null
          ? AssetAssigneeEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
      transferredFrom: json['transferredFrom'] != null
          ? AssetTransferredFromModel.fromJson(
              json['transferredFrom'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetId': assetId,
        'employeeId': employeeId,
        'assignedDate': assignedDate?.toIso8601String(),
        'expectedReturnDate': expectedReturnDate?.toIso8601String(),
        'returnedDate': returnedDate?.toIso8601String(),
        'conditionOnCheckout': conditionOnCheckout,
        'conditionOnCheckin': conditionOnCheckin,
        'checkoutNotes': checkoutNotes,
        'checkinNotes': checkinNotes,
        'agreementUrl': agreementUrl,
        'status': status,
        'acceptedAt': acceptedAt?.toIso8601String(),
        'rejectedAt': rejectedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
        'transferredFromId': transferredFromId,
        'assignedById': assignedById,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'employee': employee?.toJson(),
        'transferredFrom': transferredFrom?.toJson(),
      };

  @override
  List<Object?> get props => [
        id,
        assetId,
        employeeId,
        assignedDate,
        expectedReturnDate,
        returnedDate,
        conditionOnCheckout,
        conditionOnCheckin,
        checkoutNotes,
        checkinNotes,
        agreementUrl,
        status,
        acceptedAt,
        rejectedAt,
        rejectionReason,
        transferredFromId,
        assignedById,
        createdAt,
        updatedAt,
        employee,
        transferredFrom,
      ];

  bool get isActive => status == 'ACTIVE';
  bool get isPending => status == 'PENDING_ACCEPTANCE';
  bool get isReturned => status == 'RETURNED';
  bool get isRejected => status == 'REJECTED';
}

/// Karyawan pemegang/penerima penugasan aset
class AssetAssigneeEmployeeModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? employeeNumber;

  const AssetAssigneeEmployeeModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.employeeNumber,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) {
      return firstName;
    }
    return '$firstName $lastName'.trim();
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = (lastName != null && lastName!.isNotEmpty)
        ? lastName![0].toUpperCase()
        : '';
    return '$first$last'.trim();
  }

  factory AssetAssigneeEmployeeModel.fromJson(Map<String, dynamic> json) {
    return AssetAssigneeEmployeeModel(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'employeeNumber': employeeNumber,
      };

  @override
  List<Object?> get props => [id, firstName, lastName, employeeNumber];
}

/// Node inisiator alih tangan sebelumnya
class AssetTransferredFromModel extends Equatable {
  final String id;
  final AssetAssigneeEmployeeModel? employee;

  const AssetTransferredFromModel({
    required this.id,
    this.employee,
  });

  factory AssetTransferredFromModel.fromJson(Map<String, dynamic> json) {
    return AssetTransferredFromModel(
      id: json['id'] as String? ?? '',
      employee: json['employee'] != null
          ? AssetAssigneeEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee': employee?.toJson(),
      };

  @override
  List<Object?> get props => [id, employee];

  String get employeeName => employee?.fullName ?? '-';
  String get employeeInitials => employee?.initials ?? 'AS';
}
