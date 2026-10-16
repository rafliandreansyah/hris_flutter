import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';

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

/// Atasan menyetujui (1-on-1) atau menolak pengajuan resign bawahan.
class ResignationListSubordinateReviewed extends ResignationListEvent {
  final String id;
  final bool isApproved;

  /// Catatan 1-on-1 (setuju) atau alasan penolakan (tolak); minimal 5 karakter.
  final String notes;
  final bool approveEarlyNotice;

  const ResignationListSubordinateReviewed({
    required this.id,
    required this.isApproved,
    required this.notes,
    this.approveEarlyNotice = true,
  });

  @override
  List<Object?> get props => [id, isApproved, notes, approveEarlyNotice];
}

/// Karyawan mengirim kuesioner exit interview.
class ResignationListExitInterviewSubmitted extends ResignationListEvent {
  final ExitInterviewRequestModel request;

  const ResignationListExitInterviewSubmitted(this.request);

  @override
  List<Object?> get props => [request];
}
