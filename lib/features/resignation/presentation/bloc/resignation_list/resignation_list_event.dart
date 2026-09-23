import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';

abstract class ResignationListEvent extends Equatable {
  const ResignationListEvent();

  @override
  List<Object?> get props => [];
}

class ResignationListStarted extends ResignationListEvent {
  const ResignationListStarted();
}

class ResignationListTabChanged extends ResignationListEvent {
  final int tabIndex;

  const ResignationListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class ResignationListMyStatusRequested extends ResignationListEvent {
  final bool isRefresh;

  const ResignationListMyStatusRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class ResignationListSubordinatesRequested extends ResignationListEvent {
  final bool isRefresh;
  final String? statusFilter;

  const ResignationListSubordinatesRequested({
    this.isRefresh = false,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [isRefresh, statusFilter];
}

class ResignationListSubordinatesLoadMore extends ResignationListEvent {
  const ResignationListSubordinatesLoadMore();
}

class ResignationListSearchChanged extends ResignationListEvent {
  final String query;

  const ResignationListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ResignationListFilterApplied extends ResignationListEvent {
  final AppRequestFilterData filterData;

  const ResignationListFilterApplied(this.filterData);

  @override
  List<Object?> get props => [filterData];
}

class ResignationListFilterReset extends ResignationListEvent {
  const ResignationListFilterReset();
}

class ResignationListCancelRequested extends ResignationListEvent {
  const ResignationListCancelRequested();
}
