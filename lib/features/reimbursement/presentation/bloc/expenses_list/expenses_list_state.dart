import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';

enum ExpensesListStatus { initial, loading, success, failure }

class ExpensesListState extends Equatable {
  final ExpensesListStatus status;
  final int currentTabIndex; // 0: Pengajuan Saya, 1: Bawahan
  final String currentTypeFilter; // 'all', 'reimbursement', 'cash_advance'
  final String searchQuery;
  final AppRequestFilterData filterCriteria;

  // Tab 0: My Expenses
  final List<ExpenseFeedItemModel> myExpenses;
  final bool isMyLoading;
  final bool isMyLoadingMore;
  final int myCurrentPage;
  final int myTotalPages;

  // Tab 1: Team Expenses
  final List<ExpenseFeedItemModel> teamExpenses;
  final bool isTeamLoading;
  final bool isTeamLoadingMore;
  final bool isTeamForbidden; // HTTP 403 (bukan approver)
  final int teamCurrentPage;
  final int teamTotalPages;

  final String? errorMessage;

  const ExpensesListState({
    this.status = ExpensesListStatus.initial,
    this.currentTabIndex = 0,
    this.currentTypeFilter = 'all',
    this.searchQuery = '',
    this.filterCriteria = const AppRequestFilterData(status: 'requested'),
    this.myExpenses = const [],
    this.isMyLoading = false,
    this.isMyLoadingMore = false,
    this.myCurrentPage = 1,
    this.myTotalPages = 1,
    this.teamExpenses = const [],
    this.isTeamLoading = false,
    this.isTeamLoadingMore = false,
    this.isTeamForbidden = false,
    this.teamCurrentPage = 1,
    this.teamTotalPages = 1,
    this.errorMessage,
  });

  bool get myHasReachedMax => myCurrentPage >= myTotalPages;
  bool get teamHasReachedMax => teamCurrentPage >= teamTotalPages;

  List<ExpenseFeedItemModel> get currentList =>
      currentTabIndex == 0 ? myExpenses : teamExpenses;

  bool get isCurrentLoading =>
      currentTabIndex == 0 ? isMyLoading : isTeamLoading;

  bool get isCurrentLoadingMore =>
      currentTabIndex == 0 ? isMyLoadingMore : isTeamLoadingMore;

  ExpensesListState copyWith({
    ExpensesListStatus? status,
    int? currentTabIndex,
    String? currentTypeFilter,
    String? searchQuery,
    AppRequestFilterData? filterCriteria,
    List<ExpenseFeedItemModel>? myExpenses,
    bool? isMyLoading,
    bool? isMyLoadingMore,
    int? myCurrentPage,
    int? myTotalPages,
    List<ExpenseFeedItemModel>? teamExpenses,
    bool? isTeamLoading,
    bool? isTeamLoadingMore,
    bool? isTeamForbidden,
    int? teamCurrentPage,
    int? teamTotalPages,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ExpensesListState(
      status: status ?? this.status,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      currentTypeFilter: currentTypeFilter ?? this.currentTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      myExpenses: myExpenses ?? this.myExpenses,
      isMyLoading: isMyLoading ?? this.isMyLoading,
      isMyLoadingMore: isMyLoadingMore ?? this.isMyLoadingMore,
      myCurrentPage: myCurrentPage ?? this.myCurrentPage,
      myTotalPages: myTotalPages ?? this.myTotalPages,
      teamExpenses: teamExpenses ?? this.teamExpenses,
      isTeamLoading: isTeamLoading ?? this.isTeamLoading,
      isTeamLoadingMore: isTeamLoadingMore ?? this.isTeamLoadingMore,
      isTeamForbidden: isTeamForbidden ?? this.isTeamForbidden,
      teamCurrentPage: teamCurrentPage ?? this.teamCurrentPage,
      teamTotalPages: teamTotalPages ?? this.teamTotalPages,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTabIndex,
        currentTypeFilter,
        searchQuery,
        filterCriteria,
        myExpenses,
        isMyLoading,
        isMyLoadingMore,
        myCurrentPage,
        myTotalPages,
        teamExpenses,
        isTeamLoading,
        isTeamLoadingMore,
        isTeamForbidden,
        teamCurrentPage,
        teamTotalPages,
        errorMessage,
      ];
}
