import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';

class ResignationListState extends Equatable {
  final int currentTabIndex;
  final bool isMyStatusLoading;
  final MyResignationStatusModel? myStatus;
  final bool isSubordinatesLoading;
  final bool isSubordinatesLoadingMore;
  final List<SubordinateResignationItemModel> subordinates;
  final int subordinatesPage;
  final int subordinatesTotalPages;
  final int subordinatesTotal;
  final String subordinatesStatusFilter;
  final String searchQuery;
  final AppRequestFilterData filterData;
  final bool isCancelling;
  final bool cancelSuccess;

  /// Sedang mengirim aksi (approve/reject/exit interview).
  final bool isActionSubmitting;

  /// Pesan sukses aksi terakhir (untuk dialog sukses); `null` bila tidak ada.
  final String? actionSuccessMessage;
  final String? errorMessage;
  final bool canViewSubordinates;

  const ResignationListState({
    this.currentTabIndex = 0,
    this.isMyStatusLoading = false,
    this.myStatus,
    this.isSubordinatesLoading = false,
    this.isSubordinatesLoadingMore = false,
    this.subordinates = const [],
    this.subordinatesPage = 1,
    this.subordinatesTotalPages = 1,
    this.subordinatesTotal = 0,
    this.subordinatesStatusFilter = 'pending',
    this.searchQuery = '',
    this.filterData = const AppRequestFilterData(),
    this.isCancelling = false,
    this.cancelSuccess = false,
    this.isActionSubmitting = false,
    this.actionSuccessMessage,
    this.errorMessage,
    this.canViewSubordinates = false,
  });

  bool get hasActiveResignation => myStatus?.hasActiveResignation ?? false;

  bool get canLoadMoreSubordinates =>
      !isSubordinatesLoading &&
      !isSubordinatesLoadingMore &&
      subordinatesPage < subordinatesTotalPages;

  ResignationListState copyWith({
    int? currentTabIndex,
    bool? isMyStatusLoading,
    MyResignationStatusModel? myStatus,
    bool? isSubordinatesLoading,
    bool? isSubordinatesLoadingMore,
    List<SubordinateResignationItemModel>? subordinates,
    int? subordinatesPage,
    int? subordinatesTotalPages,
    int? subordinatesTotal,
    String? subordinatesStatusFilter,
    String? searchQuery,
    AppRequestFilterData? filterData,
    bool? isCancelling,
    bool? cancelSuccess,
    bool? isActionSubmitting,
    String? actionSuccessMessage,
    bool clearActionSuccessMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? canViewSubordinates,
  }) {
    return ResignationListState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      isMyStatusLoading: isMyStatusLoading ?? this.isMyStatusLoading,
      myStatus: myStatus ?? this.myStatus,
      isSubordinatesLoading:
          isSubordinatesLoading ?? this.isSubordinatesLoading,
      isSubordinatesLoadingMore:
          isSubordinatesLoadingMore ?? this.isSubordinatesLoadingMore,
      subordinates: subordinates ?? this.subordinates,
      subordinatesPage: subordinatesPage ?? this.subordinatesPage,
      subordinatesTotalPages:
          subordinatesTotalPages ?? this.subordinatesTotalPages,
      subordinatesTotal: subordinatesTotal ?? this.subordinatesTotal,
      subordinatesStatusFilter:
          subordinatesStatusFilter ?? this.subordinatesStatusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      filterData: filterData ?? this.filterData,
      isCancelling: isCancelling ?? this.isCancelling,
      cancelSuccess: cancelSuccess ?? this.cancelSuccess,
      isActionSubmitting: isActionSubmitting ?? this.isActionSubmitting,
      actionSuccessMessage: clearActionSuccessMessage
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      canViewSubordinates: canViewSubordinates ?? this.canViewSubordinates,
    );
  }

  @override
  List<Object?> get props => [
        currentTabIndex,
        isMyStatusLoading,
        myStatus,
        isSubordinatesLoading,
        isSubordinatesLoadingMore,
        subordinates,
        subordinatesPage,
        subordinatesTotalPages,
        subordinatesTotal,
        subordinatesStatusFilter,
        searchQuery,
        filterData,
        isCancelling,
        cancelSuccess,
        isActionSubmitting,
        actionSuccessMessage,
        errorMessage,
        canViewSubordinates,
      ];
}
