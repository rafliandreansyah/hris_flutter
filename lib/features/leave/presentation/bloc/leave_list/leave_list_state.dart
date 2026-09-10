import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_filter_bottom_sheet.dart';

enum LeaveListStatus { initial, loading, success, failure }

class LeaveListState extends Equatable {
  final LeaveListStatus status;
  final int currentTabIndex;
  final String searchQuery;
  final LeaveFilterCriteria filterCriteria;

  // Tab 0: My Requests (approver=false)
  final List<LeaveRequestItem> myRequests;
  final int myCurrentPage;
  final int myTotalPages;
  final bool isMyLoading;
  final bool isMyLoadingMore;

  // Tab 1: Team Requests (approver=true)
  final List<LeaveRequestItem> teamRequests;
  final int teamCurrentPage;
  final int teamTotalPages;
  final bool isTeamLoading;
  final bool isTeamLoadingMore;
  final bool isTeamForbidden;
  final bool hasLoadedTeam;

  final String? errorMessage;

  const LeaveListState({
    this.status = LeaveListStatus.initial,
    this.currentTabIndex = 0,
    this.searchQuery = '',
    this.filterCriteria = const LeaveFilterCriteria(),
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

  LeaveListState copyWith({
    LeaveListStatus? status,
    int? currentTabIndex,
    String? searchQuery,
    LeaveFilterCriteria? filterCriteria,
    List<LeaveRequestItem>? myRequests,
    int? myCurrentPage,
    int? myTotalPages,
    bool? isMyLoading,
    bool? isMyLoadingMore,
    List<LeaveRequestItem>? teamRequests,
    int? teamCurrentPage,
    int? teamTotalPages,
    bool? isTeamLoading,
    bool? isTeamLoadingMore,
    bool? isTeamForbidden,
    bool? hasLoadedTeam,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return LeaveListState(
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
