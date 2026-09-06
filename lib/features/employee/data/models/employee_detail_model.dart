/// Model lengkap untuk data detail pegawai dari API `/employee/{id}`.
class EmployeeDetailData {
  final String id;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? emergencyContact;
  final String? idNumber;
  final String? employeeNumber;
  final String? address;
  final String? contractExpiryDate;
  final String? joinDate;
  final String? resignDate;
  final String? dob;
  final String? placeOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? religion;
  final String? nationality;
  final String? postalCode;
  final String? photoUrl;
  final String? notes;
  final String? bloodType;
  final num? height;
  final num? weight;
  final bool? wearingGlasses;
  final String? bankName;
  final String? bankAccount;
  final String? bankNumber;
  final num? expectedSalary;
  final String? employmentType;
  final String? taxNumber;
  final String? bpjsNumber;
  final String? bpjsEmploymentNumber;
  final bool status;
  final String? timezone;

  // Organization relations
  final DetailCompany? company;
  final DetailDepartment? department;
  final DetailPosition? position;
  final DetailLevel? level;
  final DetailManager? manager;

  // Regional relations
  final DetailLocationEntity? country;
  final DetailLocationEntity? province;
  final DetailLocationEntity? city;
  final DetailLocationEntity? district;
  final DetailLocationEntity? village;

  // Lists & metrics
  final List<EmployeeWorkLocationItem> employeeWorkLocation;
  final List<DetailCoworker> coworkers;
  final DetailWarningLetter? lastWarningLetter;
  final List<DetailLeaveBalance> leaveBalances;
  final num? totalOvertime;
  final num? totalLeaveRequest;

  const EmployeeDetailData({
    required this.id,
    this.userId,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.emergencyContact,
    this.idNumber,
    this.employeeNumber,
    this.address,
    this.contractExpiryDate,
    this.joinDate,
    this.resignDate,
    this.dob,
    this.placeOfBirth,
    this.gender,
    this.maritalStatus,
    this.religion,
    this.nationality,
    this.postalCode,
    this.photoUrl,
    this.notes,
    this.bloodType,
    this.height,
    this.weight,
    this.wearingGlasses,
    this.bankName,
    this.bankAccount,
    this.bankNumber,
    this.expectedSalary,
    this.employmentType,
    this.taxNumber,
    this.bpjsNumber,
    this.bpjsEmploymentNumber,
    this.status = true,
    this.timezone,
    this.company,
    this.department,
    this.position,
    this.level,
    this.manager,
    this.country,
    this.province,
    this.city,
    this.district,
    this.village,
    this.employeeWorkLocation = const [],
    this.coworkers = const [],
    this.lastWarningLetter,
    this.leaveBalances = const [],
    this.totalOvertime,
    this.totalLeaveRequest,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return firstName;
  }

  String get initials {
    final parts = fullName.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'EP';
  }

  factory EmployeeDetailData.fromJson(Map<String, dynamic> json) {
    return EmployeeDetailData(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      emergencyContact: json['emergencyContact']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      address: json['address']?.toString(),
      contractExpiryDate: json['contractExpiryDate']?.toString(),
      joinDate: json['joinDate']?.toString(),
      resignDate: json['resignDate']?.toString(),
      dob: json['dob']?.toString(),
      placeOfBirth: json['placeOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      maritalStatus: json['maritalStatus']?.toString(),
      religion: json['religion']?.toString(),
      nationality: json['nationality']?.toString(),
      postalCode: json['postalCode']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      notes: json['notes']?.toString(),
      bloodType: json['bloodType']?.toString(),
      height: json['height'] as num?,
      weight: json['weight'] as num?,
      wearingGlasses: json['wearingGlasses'] as bool?,
      bankName: json['bankName']?.toString(),
      bankAccount: json['bankAccount']?.toString(),
      bankNumber: json['bankNumber']?.toString(),
      expectedSalary: json['expectedSalary'] as num?,
      employmentType: json['employmentType']?.toString(),
      taxNumber: json['taxNumber']?.toString(),
      bpjsNumber: json['bpjsNumber']?.toString(),
      bpjsEmploymentNumber: json['bpjsEmploymentNumber']?.toString(),
      status: json['status'] as bool? ?? true,
      timezone: json['timezone']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? DetailCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? DetailDepartment.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? DetailPosition.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      level: json['level'] is Map<String, dynamic>
          ? DetailLevel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
      manager: json['manager'] is Map<String, dynamic>
          ? DetailManager.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      country: json['country'] is Map<String, dynamic>
          ? DetailLocationEntity.fromJson(json['country'] as Map<String, dynamic>)
          : null,
      province: json['province'] is Map<String, dynamic>
          ? DetailLocationEntity.fromJson(json['province'] as Map<String, dynamic>)
          : null,
      city: json['city'] is Map<String, dynamic>
          ? DetailLocationEntity.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      district: json['district'] is Map<String, dynamic>
          ? DetailLocationEntity.fromJson(json['district'] as Map<String, dynamic>)
          : null,
      village: json['village'] is Map<String, dynamic>
          ? DetailLocationEntity.fromJson(json['village'] as Map<String, dynamic>)
          : null,
      employeeWorkLocation: (json['employeeWorkLocation'] is List)
          ? (json['employeeWorkLocation'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => EmployeeWorkLocationItem.fromJson(e))
              .toList()
          : [],
      coworkers: (json['coworkers'] is List)
          ? (json['coworkers'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DetailCoworker.fromJson(e))
              .toList()
          : [],
      lastWarningLetter: json['lastWarningLetter'] is Map<String, dynamic>
          ? DetailWarningLetter.fromJson(json['lastWarningLetter'] as Map<String, dynamic>)
          : null,
      leaveBalances: (json['leaveBalances'] is List)
          ? (json['leaveBalances'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DetailLeaveBalance.fromJson(e))
              .toList()
          : [],
      totalOvertime: json['totalOvertime'] as num?,
      totalLeaveRequest: json['totalLeaveRequest'] as num?,
    );
  }
}

class DetailCompany {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? taxId;
  final String? logoUrl;

  const DetailCompany({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.taxId,
    this.logoUrl,
  });

  factory DetailCompany.fromJson(Map<String, dynamic> json) {
    return DetailCompany(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      taxId: json['taxId']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}

class DetailDepartment {
  final String id;
  final String name;
  final String? description;
  final String? code;
  final String? companyId;

  const DetailDepartment({
    required this.id,
    required this.name,
    this.description,
    this.code,
    this.companyId,
  });

  factory DetailDepartment.fromJson(Map<String, dynamic> json) {
    return DetailDepartment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      code: json['code']?.toString(),
      companyId: json['companyId']?.toString(),
    );
  }
}

class DetailPosition {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? companyId;

  const DetailPosition({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.companyId,
  });

  factory DetailPosition.fromJson(Map<String, dynamic> json) {
    return DetailPosition(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      companyId: json['companyId']?.toString(),
    );
  }
}

class DetailLevel {
  final String id;
  final String name;
  final String? code;
  final int? levelPower;
  final String? description;
  final String? companyId;

  const DetailLevel({
    required this.id,
    required this.name,
    this.code,
    this.levelPower,
    this.description,
    this.companyId,
  });

  factory DetailLevel.fromJson(Map<String, dynamic> json) {
    return DetailLevel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      levelPower: (json['levelPower'] as num?)?.toInt(),
      description: json['description']?.toString(),
      companyId: json['companyId']?.toString(),
    );
  }
}

class DetailManager {
  final String id;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? employeeNumber;
  final String? idNumber;

  const DetailManager({
    required this.id,
    this.userId,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.employeeNumber,
    this.idNumber,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return firstName;
  }

  String get initials {
    final parts = fullName.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'MN';
  }

  factory DetailManager.fromJson(Map<String, dynamic> json) {
    return DetailManager(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      idNumber: json['idNumber']?.toString(),
    );
  }
}

class DetailLocationEntity {
  final String id;
  final String name;

  const DetailLocationEntity({
    required this.id,
    required this.name,
  });

  factory DetailLocationEntity.fromJson(Map<String, dynamic> json) {
    return DetailLocationEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class EmployeeWorkLocationItem {
  final String id;
  final String name;
  final String? address;
  final num? radius;
  final num? latitude;
  final num? longitude;
  final bool? isAnyWhere;
  final bool? isDefault;

  const EmployeeWorkLocationItem({
    required this.id,
    required this.name,
    this.address,
    this.radius,
    this.latitude,
    this.longitude,
    this.isAnyWhere,
    this.isDefault,
  });

  factory EmployeeWorkLocationItem.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkLocationItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      radius: json['radius'] as num?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      isAnyWhere: json['isAnyWhere'] as bool?,
      isDefault: json['isDefault'] as bool?,
    );
  }
}

class DetailCoworker {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? employeeNumber;
  final String? idNumber;

  const DetailCoworker({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.employeeNumber,
    this.idNumber,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return firstName;
  }

  String get initials {
    final parts = fullName.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'CW';
  }

  factory DetailCoworker.fromJson(Map<String, dynamic> json) {
    return DetailCoworker(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      idNumber: json['idNumber']?.toString(),
    );
  }
}

class DetailWarningLetter {
  final String id;
  final String type;
  final String referenceNumber;
  final String? description;
  final String? issuedDate;
  final String? expiryDate;

  const DetailWarningLetter({
    required this.id,
    required this.type,
    required this.referenceNumber,
    this.description,
    this.issuedDate,
    this.expiryDate,
  });

  factory DetailWarningLetter.fromJson(Map<String, dynamic> json) {
    return DetailWarningLetter(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      description: json['description']?.toString(),
      issuedDate: json['issuedDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
    );
  }
}

class DetailLeaveType {
  final String id;
  final String name;
  final String? code;
  final String? description;

  const DetailLeaveType({
    required this.id,
    required this.name,
    this.code,
    this.description,
  });

  factory DetailLeaveType.fromJson(Map<String, dynamic> json) {
    return DetailLeaveType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class DetailLeaveBalance {
  final String id;
  final String? leaveTypeId;
  final int periodYear;
  final int entitlement;
  final int used;
  final int remaining;
  final String? effectiveDate;
  final String? expiredDate;
  final String? source;
  final String? notes;
  final DetailLeaveType? leaveType;

  const DetailLeaveBalance({
    required this.id,
    this.leaveTypeId,
    required this.periodYear,
    required this.entitlement,
    required this.used,
    required this.remaining,
    this.effectiveDate,
    this.expiredDate,
    this.source,
    this.notes,
    this.leaveType,
  });

  factory DetailLeaveBalance.fromJson(Map<String, dynamic> json) {
    return DetailLeaveBalance(
      id: json['id']?.toString() ?? '',
      leaveTypeId: json['leaveTypeId']?.toString(),
      periodYear: (json['periodYear'] as num?)?.toInt() ?? DateTime.now().year,
      entitlement: (json['entitlement'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      effectiveDate: json['effectiveDate']?.toString(),
      expiredDate: json['expiredDate']?.toString(),
      source: json['source']?.toString(),
      notes: json['notes']?.toString(),
      leaveType: json['leaveType'] is Map<String, dynamic>
          ? DetailLeaveType.fromJson(json['leaveType'] as Map<String, dynamic>)
          : null,
    );
  }
}
