import 'package:equatable/equatable.dart';

class PayrollPeriodModel extends Equatable {
  final String id;
  final String? companyId;
  final int month;
  final int year;
  final String label;
  final String startDate;
  final String endDate;
  final String payDate;
  final String status;

  const PayrollPeriodModel({
    required this.id,
    this.companyId,
    required this.month,
    required this.year,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.payDate,
    required this.status,
  });

  factory PayrollPeriodModel.fromJson(Map<String, dynamic> json) {
    return PayrollPeriodModel(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String?,
      month: (json['month'] as num?)?.toInt() ?? 1,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      label: json['label'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      payDate: json['payDate'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (companyId != null) 'companyId': companyId,
      'month': month,
      'year': year,
      'label': label,
      'startDate': startDate,
      'endDate': endDate,
      'payDate': payDate,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        month,
        year,
        label,
        startDate,
        endDate,
        payDate,
        status,
      ];
}
