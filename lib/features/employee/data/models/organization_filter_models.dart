/// Model data Perusahaan dari API `/companies`.
class CompanyItem {
  final String id;
  final String name;
  final String? tenantId;
  final String? parentId;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;

  const CompanyItem({
    required this.id,
    required this.name,
    this.tenantId,
    this.parentId,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
  });

  factory CompanyItem.fromJson(Map<String, dynamic> json) {
    return CompanyItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      parentId: json['parentId']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tenantId': tenantId,
      'parentId': parentId,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
    };
  }
}

/// Model data Departemen dari API `/departments`.
class DepartmentItem {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? companyId;
  final String? companyName;

  const DepartmentItem({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.companyId,
    this.companyName,
  });

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    String? compName;
    if (json['company'] is Map<String, dynamic>) {
      compName = json['company']['name']?.toString();
    }
    return DepartmentItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      companyId: json['companyId']?.toString(),
      companyName: compName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'companyId': companyId,
      if (companyName != null) 'company': {'id': companyId, 'name': companyName},
    };
  }
}

/// Model data Jabatan/Posisi dari API `/positions`.
class PositionItem {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? companyId;
  final String? departmentId;
  final String? companyName;
  final String? departmentName;

  const PositionItem({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.companyId,
    this.departmentId,
    this.companyName,
    this.departmentName,
  });

  factory PositionItem.fromJson(Map<String, dynamic> json) {
    String? compName;
    if (json['company'] is Map<String, dynamic>) {
      compName = json['company']['name']?.toString();
    }

    String? deptName;
    if (json['department'] is Map<String, dynamic>) {
      deptName = json['department']['name']?.toString();
    }

    return PositionItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      companyId: json['companyId']?.toString(),
      departmentId: json['departmentId']?.toString(),
      companyName: compName,
      departmentName: deptName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'companyId': companyId,
      'departmentId': departmentId,
      if (companyName != null) 'company': {'id': companyId, 'name': companyName},
      if (departmentName != null)
        'department': {'id': departmentId, 'name': departmentName},
    };
  }
}
