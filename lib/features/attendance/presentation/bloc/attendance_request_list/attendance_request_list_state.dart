import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_filter_bottom_sheet.dart';

enum AttendanceRequestListStatus { initial, loading, success, failure }

class AttendanceRequestListState extends Equatable {
  final AttendanceRequestListStatus status;
  final int currentTabIndex;
  final String searchQuery;
  final AttendanceRequestFilterCriteria filterCriteria;

  // Tab 0: Pengajuan Saya (approver=false)
  final List<AttendanceRequestItem> myRequests;
  final int myCurrentPage;
  final int myTotalPages;
  final bool isMyLoading;
  final bool isMyLoadingMore;

  // Tab 1: Persetujuan Tim / Pengajuan Pegawai Lain (approver=true)
  final List<AttendanceRequestItem> teamRequests;
  final int teamCurrentPage;
  final int teamTotalPages;
  final bool isTeamLoading;
  final bool isTeamLoadingMore;
  final bool isTeamForbidden;
  final bool hasLoadedTeam;

  final String? errorMessage;

  const AttendanceRequestListState({
    this.status = AttendanceRequestListStatus.initial,
    this.currentTabIndex = 0,
    this.searchQuery = '',
    this.filterCriteria = const AttendanceRequestFilterCriteria(),
    this.myRequests = const [],
    this.myCurrentPage = 1,
    this.myTotalPages = 1,
    this.isMyLoading = false,
    this.isMyLoadingMore = false,
    this.teamRequests = const [],
    this.teamCurrentPage = 1,
    this.teamTotalPages = 1,
    this.isTeamLoading = false,
    this.isTeamLoadingMore = false,
    this.isTeamForbidden = false,
    this.hasLoadedTeam = false,
    this.errorMessage,
  });

  AttendanceRequestListState copyWith({
    AttendanceRequestListStatus? status,
    int? currentTabIndex,
    String? searchQuery,
    AttendanceRequestFilterCriteria? filterCriteria,
    List<AttendanceRequestItem>? myRequests,
    int? myCurrentPage,
    int? myTotalPages,
    bool? isMyLoading,
    bool? isMyLoadingMore,
    List<AttendanceRequestItem>? teamRequests,
    int? teamCurrentPage,
    int? teamTotalPages,
    bool? isTeamLoading,
    bool? isTeamLoadingMore,
    bool? isTeamForbidden,
    bool? hasLoadedTeam,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AttendanceRequestListState(
      status: status ?? this.status,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      myRequests: myRequests ?? this.myRequests,
      myCurrentPage: myCurrentPage ?? this.myCurrentPage,
      myTotalPages: myTotalPages ?? this.myTotalPages,
      isMyLoading: isMyLoading ?? this.isMyLoading,
      isMyLoadingMore: isMyLoadingMore ?? this.isMyLoadingMore,
      teamRequests: teamRequests ?? this.teamRequests,
      teamCurrentPage: teamCurrentPage ?? this.teamCurrentPage,
      teamTotalPages: teamTotalPages ?? this.teamTotalPages,
      isTeamLoading: isTeamLoading ?? this.isTeamLoading,
      isTeamLoadingMore: isTeamLoadingMore ?? this.isTeamLoadingMore,
      isTeamForbidden: isTeamForbidden ?? this.isTeamForbidden,
      hasLoadedTeam: hasLoadedTeam ?? this.hasLoadedTeam,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTabIndex,
        searchQuery,
        filterCriteria,
        myRequests,
        myCurrentPage,
        myTotalPages,
        isMyLoading,
        isMyLoadingMore,
        teamRequests,
        teamCurrentPage,
        teamTotalPages,
        isTeamLoading,
        isTeamLoadingMore,
        isTeamForbidden,
        hasLoadedTeam,
        errorMessage,
      ];
}
