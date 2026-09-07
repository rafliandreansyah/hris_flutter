import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';

enum ActivityListStatus { initial, loading, success, failure }

class ActivityListState extends Equatable {
  final ActivityListStatus status;
  final int currentTabIndex;
  final String searchQuery;
  final ActivityFilterCriteria filterCriteria;
  final List<ActivityItem>? customActivities;

  // Tab 0: Aktivitasku
  final List<ActivityItem> myActivities;
  final int myCurrentPage;
  final int myTotalPages;
  final bool isMyLoading;
  final bool isMyLoadingMore;

  // Tab 1: Aktivitas Tim (Pegawai Lain)
  final List<ActivityItem> teamActivities;
  final int teamCurrentPage;
  final int teamTotalPages;
  final bool isTeamLoading;
  final bool isTeamLoadingMore;
  final bool isTeamForbidden;
  final bool hasLoadedTeam;

  final String? errorMessage;

  const ActivityListState({
    this.status = ActivityListStatus.initial,
    this.currentTabIndex = 0,
    this.searchQuery = '',
    this.filterCriteria = const ActivityFilterCriteria(),
    this.customActivities,
    this.myActivities = const [],
    this.myCurrentPage = 1,
    this.myTotalPages = 1,
    this.isMyLoading = false,
    this.isMyLoadingMore = false,
    this.teamActivities = const [],
    this.teamCurrentPage = 1,
    this.teamTotalPages = 1,
    this.isTeamLoading = false,
    this.isTeamLoadingMore = false,
    this.isTeamForbidden = false,
    this.hasLoadedTeam = false,
    this.errorMessage,
  });

  ActivityListState copyWith({
    ActivityListStatus? status,
    int? currentTabIndex,
    String? searchQuery,
    ActivityFilterCriteria? filterCriteria,
    List<ActivityItem>? customActivities,
    List<ActivityItem>? myActivities,
    int? myCurrentPage,
    int? myTotalPages,
    bool? isMyLoading,
    bool? isMyLoadingMore,
    List<ActivityItem>? teamActivities,
    int? teamCurrentPage,
    int? teamTotalPages,
    bool? isTeamLoading,
    bool? isTeamLoadingMore,
    bool? isTeamForbidden,
    bool? hasLoadedTeam,
    String? errorMessage,
  }) {
    return ActivityListState(
      status: status ?? this.status,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      customActivities: customActivities ?? this.customActivities,
      myActivities: myActivities ?? this.myActivities,
      myCurrentPage: myCurrentPage ?? this.myCurrentPage,
      myTotalPages: myTotalPages ?? this.myTotalPages,
      isMyLoading: isMyLoading ?? this.isMyLoading,
      isMyLoadingMore: isMyLoadingMore ?? this.isMyLoadingMore,
      teamActivities: teamActivities ?? this.teamActivities,
      teamCurrentPage: teamCurrentPage ?? this.teamCurrentPage,
      teamTotalPages: teamTotalPages ?? this.teamTotalPages,
      isTeamLoading: isTeamLoading ?? this.isTeamLoading,
      isTeamLoadingMore: isTeamLoadingMore ?? this.isTeamLoadingMore,
      isTeamForbidden: isTeamForbidden ?? this.isTeamForbidden,
      hasLoadedTeam: hasLoadedTeam ?? this.hasLoadedTeam,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTabIndex,
        searchQuery,
        filterCriteria,
        customActivities,
        myActivities,
        myCurrentPage,
        myTotalPages,
        isMyLoading,
        isMyLoadingMore,
        teamActivities,
        teamCurrentPage,
        teamTotalPages,
        isTeamLoading,
        isTeamLoadingMore,
        isTeamForbidden,
        hasLoadedTeam,
        errorMessage,
      ];
}
