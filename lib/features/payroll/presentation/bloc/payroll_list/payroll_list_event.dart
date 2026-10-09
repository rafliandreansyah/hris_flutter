import 'package:equatable/equatable.dart';

abstract class PayrollListEvent extends Equatable {
  const PayrollListEvent();

  @override
  List<Object?> get props => [];
}

class PayrollListStarted extends PayrollListEvent {
  const PayrollListStarted();
}

class PayrollListTabChanged extends PayrollListEvent {
  final int tabIndex;

  const PayrollListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class PayrollListYearChanged extends PayrollListEvent {
  final int year;

  const PayrollListYearChanged(this.year);

  @override
  List<Object?> get props => [year];
}

class PayrollListFilterApplied extends PayrollListEvent {
  final int? year;
  final int? month;
  final String? status;
  final String? companyId;
  final String? departmentId;

  const PayrollListFilterApplied({
    this.year,
    this.month,
    this.status,
    this.companyId,
    this.departmentId,
  });

  @override
  List<Object?> get props => [year, month, status, companyId, departmentId];
}

class PayrollListSearchChanged extends PayrollListEvent {
  final String query;

  const PayrollListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PayrollListPrivacyToggled extends PayrollListEvent {
  const PayrollListPrivacyToggled();
}

class PayrollListRefreshed extends PayrollListEvent {
  const PayrollListRefreshed();
}

class PayrollListLoadMore extends PayrollListEvent {
  const PayrollListLoadMore();
}
