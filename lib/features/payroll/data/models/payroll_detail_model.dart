import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';

class PayrollCompanyModel extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? taxId;
  final String? logoUrl;

  const PayrollCompanyModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.taxId,
    this.logoUrl,
  });

  String? get resolvedLogoUrl => resolveFileUrl(logoUrl);

  factory PayrollCompanyModel.fromJson(Map<String, dynamic> json) {
    return PayrollCompanyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      taxId: json['taxId'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'taxId': taxId,
      'logoUrl': logoUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        email,
        website,
        taxId,
        logoUrl,
      ];
}

class PayrollEmployeeDetailModel extends Equatable {
  final String id;
  final String nik;
  final String name;
  final String email;
  final String? phone;
  final String department;
  final String position;
  final String? bankName;
  final String? accountNumber;
  final String? taxStatus;
  final String? taxNumber;
  final String? bpjsEmployment;
  final String? bpjsHealth;

  const PayrollEmployeeDetailModel({
    required this.id,
    required this.nik,
    required this.name,
    required this.email,
    this.phone,
    required this.department,
    required this.position,
    this.bankName,
    this.accountNumber,
    this.taxStatus,
    this.taxNumber,
    this.bpjsEmployment,
    this.bpjsHealth,
  });

  factory PayrollEmployeeDetailModel.fromJson(Map<String, dynamic> json) {
    return PayrollEmployeeDetailModel(
      id: json['id'] as String? ?? '',
      nik: json['nik'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      department: json['department'] as String? ?? '',
      position: json['position'] as String? ?? '',
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      taxStatus: json['taxStatus'] as String?,
      taxNumber: json['taxNumber'] as String?,
      bpjsEmployment: json['bpjsEmployment'] as String?,
      bpjsHealth: json['bpjsHealth'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'position': position,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'taxStatus': taxStatus,
      'taxNumber': taxNumber,
      'bpjsEmployment': bpjsEmployment,
      'bpjsHealth': bpjsHealth,
    };
  }

  @override
  List<Object?> get props => [
        id,
        nik,
        name,
        email,
        phone,
        department,
        position,
        bankName,
        accountNumber,
        taxStatus,
        taxNumber,
        bpjsEmployment,
        bpjsHealth,
      ];
}

class PayrollAttendanceRecapModel extends Equatable {
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final int lateMinutes;
  final double overtimeHours;

  const PayrollAttendanceRecapModel({
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateMinutes,
    required this.overtimeHours,
  });

  factory PayrollAttendanceRecapModel.fromJson(Map<String, dynamic> json) {
    return PayrollAttendanceRecapModel(
      workingDays: (json['workingDays'] as num?)?.toInt() ?? 0,
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 0,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      lateMinutes: (json['lateMinutes'] as num?)?.toInt() ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workingDays': workingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateMinutes': lateMinutes,
      'overtimeHours': overtimeHours,
    };
  }

  @override
  List<Object?> get props => [
        workingDays,
        presentDays,
        absentDays,
        lateMinutes,
        overtimeHours,
      ];
}

class PayrollEarningItemModel extends Equatable {
  final String id;
  final String name;
  final String category;
  final String quantity;
  final double amount;
  final String? formula;

  const PayrollEarningItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.amount,
    this.formula,
  });

  factory PayrollEarningItemModel.fromJson(Map<String, dynamic> json) {
    return PayrollEarningItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      formula: json['formula'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'amount': amount,
      'formula': formula,
    };
  }

  @override
  List<Object?> get props => [id, name, category, quantity, amount, formula];
}

class PayrollDeductionItemModel extends Equatable {
  final String id;
  final String name;
  final String category;
  final String description;
  final double amount;

  const PayrollDeductionItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.amount,
  });

  factory PayrollDeductionItemModel.fromJson(Map<String, dynamic> json) {
    return PayrollDeductionItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'amount': amount,
    };
  }

  @override
  List<Object?> get props => [id, name, category, description, amount];
}

class PayrollDetailModel extends Equatable {
  final String id;
  final String status;
  final double basicSalary;
  final double? dailySalary;
  final double grossSalary;
  final double deductions;
  final double netSalary;
  final String terbilang;
  final String? payslipUrl;
  final String? paidAt;
  final String? generatedAt;
  final PayrollCompanyModel company;
  final PayrollEmployeeDetailModel employee;
  final PayrollPeriodModel period;
  final PayrollAttendanceRecapModel attendanceRecap;
  final List<PayrollEarningItemModel> earnings;
  final List<PayrollDeductionItemModel> deductionsList;

  const PayrollDetailModel({
    required this.id,
    required this.status,
    this.basicSalary = 0.0,
    this.dailySalary,
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
    required this.terbilang,
    this.payslipUrl,
    this.paidAt,
    this.generatedAt,
    required this.company,
    required this.employee,
    required this.period,
    required this.attendanceRecap,
    required this.earnings,
    required this.deductionsList,
  });

  factory PayrollDetailModel.fromJson(Map<String, dynamic> json) {
    return PayrollDetailModel(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ??
          (json['grossSalary'] as num?)?.toDouble() ??
          0.0,
      dailySalary: (json['dailySalary'] as num?)?.toDouble(),
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0.0,
      terbilang: json['terbilang'] as String? ?? '',
      payslipUrl: json['payslipUrl'] as String?,
      paidAt: json['paidAt'] as String?,
      generatedAt: json['generatedAt'] as String?,
      company: json['company'] is Map<String, dynamic>
          ? PayrollCompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : const PayrollCompanyModel(id: '', name: '-'),
      employee: json['employee'] is Map<String, dynamic>
          ? PayrollEmployeeDetailModel.fromJson(
              json['employee'] as Map<String, dynamic>)
          : const PayrollEmployeeDetailModel(
              id: '',
              nik: '-',
              name: '-',
              email: '-',
              department: '-',
              position: '-',
            ),
      period: json['period'] is Map<String, dynamic>
          ? PayrollPeriodModel.fromJson(json['period'] as Map<String, dynamic>)
          : PayrollPeriodModel(
              id: '',
              month: 1,
              year: DateTime.now().year,
              label: '',
              startDate: '',
              endDate: '',
              payDate: '',
              status: '',
            ),
      attendanceRecap: json['attendanceRecap'] is Map<String, dynamic>
          ? PayrollAttendanceRecapModel.fromJson(
              json['attendanceRecap'] as Map<String, dynamic>)
          : const PayrollAttendanceRecapModel(
              workingDays: 0,
              presentDays: 0,
              absentDays: 0,
              lateMinutes: 0,
              overtimeHours: 0,
            ),
      earnings: (json['earnings'] as List<dynamic>?)
              ?.map((e) =>
                  PayrollEarningItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deductionsList: (json['deductionsList'] as List<dynamic>?)
              ?.map((e) =>
                  PayrollDeductionItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        basicSalary,
        dailySalary,
        grossSalary,
        deductions,
        netSalary,
        terbilang,
        payslipUrl,
        paidAt,
        generatedAt,
        company,
        employee,
        period,
        attendanceRecap,
        earnings,
        deductionsList,
      ];
}

class PayrollDownloadResponseModel extends Equatable {
  final String payrollId;
  final String payslipUrl;
  final bool isNewlyGenerated;

  const PayrollDownloadResponseModel({
    required this.payrollId,
    required this.payslipUrl,
    required this.isNewlyGenerated,
  });

  factory PayrollDownloadResponseModel.fromJson(Map<String, dynamic> json) {
    return PayrollDownloadResponseModel(
      payrollId: json['payrollId'] as String? ?? '',
      payslipUrl: json['payslipUrl'] as String? ?? '',
      isNewlyGenerated: json['isNewlyGenerated'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [payrollId, payslipUrl, isNewlyGenerated];
}
