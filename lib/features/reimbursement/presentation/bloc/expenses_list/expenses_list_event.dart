import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';

abstract class ExpensesListEvent extends Equatable {
  const ExpensesListEvent();

  @override
  List<Object?> get props => [];
}

class ExpensesListStarted extends ExpensesListEvent {
  const ExpensesListStarted();
}

class ExpensesListTabChanged extends ExpensesListEvent {
  final int tabIndex; // 0: Pengajuan Saya, 1: Bawahan
  const ExpensesListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class ExpensesListTypeFilterChanged extends ExpensesListEvent {
  final String type; // 'all', 'reimbursement', 'cash_advance'
  const ExpensesListTypeFilterChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class ExpensesListFetchRequested extends ExpensesListEvent {
  final bool isRefresh;
  final bool isTeam;
  const ExpensesListFetchRequested({
    this.isRefresh = false,
    required this.isTeam,
  });

  @override
  List<Object?> get props => [isRefresh, isTeam];
}

class ExpensesListLoadMoreRequested extends ExpensesListEvent {
  final bool isTeam;
  const ExpensesListLoadMoreRequested({required this.isTeam});

  @override
  List<Object?> get props => [isTeam];
}

class ExpensesListSearchChanged extends ExpensesListEvent {
  final String query;
  const ExpensesListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ExpensesListFilterApplied extends ExpensesListEvent {
  final AppRequestFilterData criteria;
  const ExpensesListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

class ExpensesListFilterReset extends ExpensesListEvent {
  const ExpensesListFilterReset();
}
