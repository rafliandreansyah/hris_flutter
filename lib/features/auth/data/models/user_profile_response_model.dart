import 'package:equatable/equatable.dart';

/// Model representasi data profil lengkap dari endpoint `GET /auth/profile`.
class UserProfileData extends Equatable {
  final UserModel user;
  final EmployeeProfileModel? employee;
  final String? dataScope;
  final List<String> permissions;

  const UserProfileData({
    required this.user,
    this.employee,
    this.dataScope,
    this.permissions = const [],
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      user: UserModel.fromJson((json['user'] as Map<String, dynamic>?) ?? {}),
      employee: json['employee'] != null
          ? EmployeeProfileModel.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
      dataScope: json['dataScope'] as String?,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'employee': employee?.toJson(),
      'dataScope': dataScope,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [user, employee, dataScope, permissions];
}

class UserModel extends Equatable {
  final String id;
  final String? name;
  final String email;
  final String? role;
  final bool status;
  final String? language;
  final String? lastLogin;

  const UserModel({
    required this.id,
    this.name,
    required this.email,
    this.role,
    this.status = true,
    this.language,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String?,
      email: (json['email'] ?? '').toString(),
      role: json['role'] as String?,
      status: json['status'] is bool ? json['status'] as bool : true,
      language: json['language'] as String?,
      lastLogin: json['lastLogin'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'language': language,
      'lastLogin': lastLogin,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    status,
    language,
    lastLogin,
  ];
}

class EmployeeProfileModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final OrgItemModel? company;
  final OrgItemModel? department;
  final OrgItemModel? position;

  const EmployeeProfileModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.photoUrl,
    this.company,
    this.department,
    this.position,
  });

  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileModel(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      company: json['company'] != null
          ? OrgItemModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] != null
          ? OrgItemModel.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] != null
          ? OrgItemModel.fromJson(json['position'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'company': company?.toJson(),
      'department': department?.toJson(),
      'position': position?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    photoUrl,
    company,
    department,
    position,
  ];
}

class OrgItemModel extends Equatable {
  final String id;
  final String name;
  final String? code;

  const OrgItemModel({required this.id, required this.name, this.code});

  factory OrgItemModel.fromJson(Map<String, dynamic> json) {
    return OrgItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }

  @override
  List<Object?> get props => [id, name, code];
}
