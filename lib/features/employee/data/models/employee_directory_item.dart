/// Model representasi data karyawan pada direktori Oasish HRIS
/// sesuai rancangan Google Stitch dan disinkronkan dengan respons API `/employee`.
class EmployeeDirectoryItem {
  final String id;
  final String name;
  final String role;
  final String department;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String initials;
  final String? company;

  // Additional fields from API
  final String? rawId;
  final String? firstName;
  final String? lastName;
  final String? idNumber;
  final String? employeeNumber;
  final String? companyId;
  final String? departmentId;
  final String? positionId;

  const EmployeeDirectoryItem({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.initials,
    this.company,
    this.rawId,
    this.firstName,
    this.lastName,
    this.idNumber,
    this.employeeNumber,
    this.companyId,
    this.departmentId,
    this.positionId,
  });

  factory EmployeeDirectoryItem.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString();
    final fullName = (lastName != null && lastName.trim().isNotEmpty)
        ? '$firstName $lastName'.trim()
        : firstName.trim();

    final compMap = json['company'] is Map<String, dynamic>
        ? json['company'] as Map<String, dynamic>
        : null;
    final deptMap = json['department'] is Map<String, dynamic>
        ? json['department'] as Map<String, dynamic>
        : null;
    final posMap = json['position'] is Map<String, dynamic>
        ? json['position'] as Map<String, dynamic>
        : null;

    final companyName = compMap?['name']?.toString();
    final companyId = compMap?['id']?.toString() ?? json['companyId']?.toString();
    final departmentName = deptMap?['name']?.toString() ?? '';
    final departmentId = deptMap?['id']?.toString() ?? json['departmentId']?.toString();
    final positionName = posMap?['name']?.toString() ?? '';
    final positionId = posMap?['id']?.toString() ?? json['positionId']?.toString();

    final empNumber = json['employeeNumber']?.toString();
    final rawId = json['id']?.toString() ?? '';
    final displayId = (empNumber != null && empNumber.isNotEmpty)
        ? empNumber
        : (rawId.isNotEmpty ? rawId : 'EMP-000');

    // Generate Initials (e.g. "Sarah Jenkins" -> "SJ")
    String initials = 'EP';
    final parts = fullName.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }

    return EmployeeDirectoryItem(
      id: displayId,
      rawId: rawId,
      name: fullName.isNotEmpty ? fullName : 'Pegawai',
      role: positionName.isNotEmpty ? positionName : 'Staff',
      department: departmentName.isNotEmpty ? departmentName : 'Umum',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString(),
      avatarUrl: json['photoUrl']?.toString() ?? json['avatarUrl']?.toString(),
      initials: initials,
      company: companyName,
      firstName: firstName,
      lastName: lastName,
      idNumber: json['idNumber']?.toString(),
      employeeNumber: empNumber,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': rawId ?? id,
      'firstName': firstName ?? name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'idNumber': idNumber,
      'employeeNumber': employeeNumber ?? id,
      if (company != null || companyId != null)
        'company': {
          if (companyId != null) 'id': companyId,
          if (company != null) 'name': company,
        },
      if (department.isNotEmpty || departmentId != null)
        'department': {
          if (departmentId != null) 'id': departmentId,
          'name': department,
        },
      if (role.isNotEmpty || positionId != null)
        'position': {
          if (positionId != null) 'id': positionId,
          'name': role,
        },
      'photoUrl': avatarUrl,
    };
  }

  /// Mock data karyawan yang disinkronkan dengan Google Stitch
  static const List<EmployeeDirectoryItem> sampleEmployees = [
    EmployeeDirectoryItem(
      id: 'EMP-092',
      name: 'Sarah Jenkins',
      role: 'Senior Frontend Engineer',
      department: 'Engineering',
      company: 'PT Oasish Group',
      email: 's.jenkins@oasis.corp',
      phone: '+62 812-3456-7890',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC8v1R6ffgqCi-rkgTvcKXtjMWifqCWaznU-5wPmVu6Fe-zzKyJqF2iQ9VdzmLOmdy6rlaZtNViMCB2TpbR4-tiREL6KgPUUaO-TxFm6tBU-dwyEIKN8wVlInfU2lgqsizV_ab4VfLXBIUwISXhl2m2bu_3kTQJDxYSsMNCblCGWmbadTwv9pJUXv2xr8ilTpPRKO9zPaXFA2GugffXzUWyqJe1q3B0TDa-vVQAsFaP2i0y-UKamMqk0g',
      initials: 'SJ',
    ),
    EmployeeDirectoryItem(
      id: 'EMP-145',
      name: 'Budi Santoso',
      role: 'Site Operations Supervisor',
      department: 'Operations',
      company: 'PT Oasish Nusantara',
      email: 'b.santoso@oasis.corp',
      phone: '+62 813-9876-5432',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA3Okff1J66FcjLS1yHBmjevNcN7povC8fV0GXs79EKndd459TzGkjjGtTTnwlOQJcE5ksCPdzIU9Upx1ViEEzKcdiTyJvy_Lkh0zK1mSvlDZAS2AUZDLKCN4s34UrECm43TFi7TJaMy6q4d8uMiqFzQVodqT6r2fmVkSOWiYk1UEFmKJz43YXCTvHBNtG9OElUpA99HK7OrRkLXLdeB4vTgY-7z3JinrH2L7hw-A575mnzuTVDAM_wrA',
      initials: 'BS',
    ),
    EmployeeDirectoryItem(
      id: 'EMP-003',
      name: 'Jessica Pranata',
      role: 'Head of People & Culture',
      department: 'Human Resources',
      company: 'PT Oasish Group',
      email: 'j.pranata@oasis.corp',
      phone: '+62 811-2233-4455',
      avatarUrl: null,
      initials: 'JP',
    ),
    EmployeeDirectoryItem(
      id: 'EMP-005',
      name: 'Alex Rivera',
      role: 'Senior Engineering Manager',
      department: 'Engineering',
      company: 'PT Oasish Group',
      email: 'a.rivera@oasis.corp',
      phone: '+62 812-7788-9900',
      avatarUrl: null,
      initials: 'AR',
    ),
    EmployeeDirectoryItem(
      id: 'EMP-041',
      name: 'Linda Permata',
      role: 'Finance & Tax Specialist',
      department: 'Finance',
      company: 'PT Oasish Nusantara',
      email: 'l.permata@oasis.corp',
      phone: '+62 815-6677-8899',
      avatarUrl: null,
      initials: 'LP',
    ),
  ];
}
