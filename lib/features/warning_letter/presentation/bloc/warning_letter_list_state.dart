import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_filter_criteria.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';

class WarningLetterListState extends Equatable {
  // Tab 0: Surat Diterima (My Letters, approver: false)
  final List<WarningLetterItem> myLetters;
  final bool isMyLoading;
  final bool isMyLoadingMore;
  final String? myError;
  final int myCurrentPage;
  final int myTotalPages;
  final int myTotal;

  // Tab 1: Diterbitkan (Team Letters, approver: true)
  final List<WarningLetterItem> teamLetters;
  final bool isTeamLoading;
  final bool isTeamLoadingMore;
  final String? teamError;
  final bool isTeamForbidden;
  final int teamCurrentPage;
  final int teamTotalPages;
  final int teamTotal;

  // Global Filter & Search
  final int currentTabIndex;
  final String searchQuery;
  final WarningLetterFilterCriteria filterCriteria;
  final List<WarningLetterTypeModel> letterTypes;
  final bool isLetterTypesLoading;

  const WarningLetterListState({
    this.myLetters = const [],
    this.isMyLoading = false,
    this.isMyLoadingMore = false,
    this.myError,
    this.myCurrentPage = 1,
    this.myTotalPages = 1,
    this.myTotal = 0,
    this.teamLetters = const [],
    this.isTeamLoading = false,
    this.isTeamLoadingMore = false,
    this.teamError,
    this.isTeamForbidden = false,
    this.teamCurrentPage = 1,
    this.teamTotalPages = 1,
    this.teamTotal = 0,
    this.currentTabIndex = 0,
    this.searchQuery = '',
    this.filterCriteria = const WarningLetterFilterCriteria(),
    this.letterTypes = const [],
    this.isLetterTypesLoading = false,
  });

  bool get hasMyNextPage => myCurrentPage < myTotalPages;
  bool get hasTeamNextPage => teamCurrentPage < teamTotalPages;

  WarningLetterListState copyWith({
    List<WarningLetterItem>? myLetters,
    bool? isMyLoading,
    bool? isMyLoadingMore,
    String? myError,
    bool clearMyError = false,
    int? myCurrentPage,
    int? myTotalPages,
    int? myTotal,
    List<WarningLetterItem>? teamLetters,
    bool? isTeamLoading,
    bool? isTeamLoadingMore,
    String? teamError,
    bool clearTeamError = false,
    bool? isTeamForbidden,
    int? teamCurrentPage,
    int? teamTotalPages,
    int? teamTotal,
    int? currentTabIndex,
    String? searchQuery,
    WarningLetterFilterCriteria? filterCriteria,
    List<WarningLetterTypeModel>? letterTypes,
    bool? isLetterTypesLoading,
  }) {
    return WarningLetterListState(
      myLetters: myLetters ?? this.myLetters,
      isMyLoading: isMyLoading ?? this.isMyLoading,
      isMyLoadingMore: isMyLoadingMore ?? this.isMyLoadingMore,
      myError: clearMyError ? null : (myError ?? this.myError),
      myCurrentPage: myCurrentPage ?? this.myCurrentPage,
      myTotalPages: myTotalPages ?? this.myTotalPages,
      myTotal: myTotal ?? this.myTotal,
      teamLetters: teamLetters ?? this.teamLetters,
      isTeamLoading: isTeamLoading ?? this.isTeamLoading,
      isTeamLoadingMore: isTeamLoadingMore ?? this.isTeamLoadingMore,
      teamError: clearTeamError ? null : (teamError ?? this.teamError),
      isTeamForbidden: isTeamForbidden ?? this.isTeamForbidden,
      teamCurrentPage: teamCurrentPage ?? this.teamCurrentPage,
      teamTotalPages: teamTotalPages ?? this.teamTotalPages,
      teamTotal: teamTotal ?? this.teamTotal,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      letterTypes: letterTypes ?? this.letterTypes,
      isLetterTypesLoading: isLetterTypesLoading ?? this.isLetterTypesLoading,
    );
  }

  @override
  List<Object?> get props => [
        myLetters,
        isMyLoading,
        isMyLoadingMore,
        myError,
        myCurrentPage,
        myTotalPages,
        myTotal,
        teamLetters,
        isTeamLoading,
        isTeamLoadingMore,
        teamError,
        isTeamForbidden,
        teamCurrentPage,
        teamTotalPages,
        teamTotal,
        currentTabIndex,
        searchQuery,
        filterCriteria,
        letterTypes,
        isLetterTypesLoading,
      ];
}
