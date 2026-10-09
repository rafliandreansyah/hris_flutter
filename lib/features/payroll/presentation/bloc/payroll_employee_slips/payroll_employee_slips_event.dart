import 'package:equatable/equatable.dart';

abstract class PayrollEmployeeSlipsEvent extends Equatable {
  const PayrollEmployeeSlipsEvent();

  @override
  List<Object?> get props => [];
}

class PayrollEmployeeSlipsStarted extends PayrollEmployeeSlipsEvent {
  final String employeeId;

  const PayrollEmployeeSlipsStarted(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class PayrollEmployeeSlipsYearChanged extends PayrollEmployeeSlipsEvent {
  final int year;

  const PayrollEmployeeSlipsYearChanged(this.year);

  @override
  List<Object?> get props => [year];
}

class PayrollEmployeeSlipsFilterApplied extends PayrollEmployeeSlipsEvent {
  final int? year;
  final int? month;
  final String? status;

  const PayrollEmployeeSlipsFilterApplied({
    this.year,
    this.month,
    this.status,
  });

  @override
  List<Object?> get props => [year, month, status];
}

class PayrollEmployeeSlipsSearchChanged extends PayrollEmployeeSlipsEvent {
  final String query;

  const PayrollEmployeeSlipsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PayrollEmployeeSlipsPrivacyToggled extends PayrollEmployeeSlipsEvent {
  const PayrollEmployeeSlipsPrivacyToggled();
}

class PayrollEmployeeSlipsRefreshed extends PayrollEmployeeSlipsEvent {
  const PayrollEmployeeSlipsRefreshed();
}

class PayrollEmployeeSlipsLoadMore extends PayrollEmployeeSlipsEvent {
  const PayrollEmployeeSlipsLoadMore();
}
