import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_state.dart';

class ExpensesListBloc extends Bloc<ExpensesListEvent, ExpensesListState> {
  final ReimbursementRepository _repository;
  static const int defaultPageSize = 20;

  ExpensesListBloc({ReimbursementRepository? repository})
      : _repository = repository ?? ReimbursementRepositoryImpl(),
        super(const ExpensesListState()) {
    on<ExpensesListStarted>(_onStarted);
    on<ExpensesListTabChanged>(_onTabChanged);
    on<ExpensesListTypeFilterChanged>(_onTypeFilterChanged);
    on<ExpensesListFetchRequested>(_onFetchRequested);
    on<ExpensesListLoadMoreRequested>(_onLoadMoreRequested);
    on<ExpensesListSearchChanged>(
      _onSearchChanged,
      transformer: debounceRestartable(),
    );
    on<ExpensesListFilterApplied>(_onFilterApplied);
    on<ExpensesListFilterReset>(_onFilterReset);
  }

  void _onStarted(
    ExpensesListStarted event,
    Emitter<ExpensesListState> emit,
  ) {
    add(const ExpensesListFetchRequested(isRefresh: true, isTeam: false));
    add(const ExpensesListFetchRequested(isRefresh: true, isTeam: true));
  }

  void _onTabChanged(
    ExpensesListTabChanged event,
    Emitter<ExpensesListState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
    // Jika tab belum pernah dimuat datanya, picu fetch
    if (event.tabIndex == 1 &&
        state.teamExpenses.isEmpty &&
        !state.isTeamLoading &&
        !state.isTeamForbidden) {
      add(const ExpensesListFetchRequested(isRefresh: true, isTeam: true));
    }
  }

  void _onTypeFilterChanged(
    ExpensesListTypeFilterChanged event,
    Emitter<ExpensesListState> emit,
  ) {
    if (state.currentTypeFilter == event.type) return;
    emit(state.copyWith(currentTypeFilter: event.type));
    add(ExpensesListFetchRequested(
      isRefresh: true,
      isTeam: state.currentTabIndex == 1,
    ));
  }

  void _onSearchChanged(
    ExpensesListSearchChanged event,
    Emitter<ExpensesListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    add(ExpensesListFetchRequested(
      isRefresh: true,
      isTeam: state.currentTabIndex == 1,
    ));
  }

  void _onFilterApplied(
    ExpensesListFilterApplied event,
    Emitter<ExpensesListState> emit,
  ) {
    emit(state.copyWith(filterCriteria: event.criteria));
    add(const ExpensesListFetchRequested(isRefresh: true, isTeam: false));
    add(const ExpensesListFetchRequested(isRefresh: true, isTeam: true));
  }

  void _onFilterReset(
    ExpensesListFilterReset event,
    Emitter<ExpensesListState> emit,
  ) {
    emit(state.copyWith(
      filterCriteria: const AppRequestFilterData(status: 'requested'),
    ));
    add(const ExpensesListFetchRequested(isRefresh: true, isTeam: false));
    add(const ExpensesListFetchRequested(isRefresh: true, isTeam: true));
  }

  Future<void> _onFetchRequested(
    ExpensesListFetchRequested event,
    Emitter<ExpensesListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    final startDate = state.filterCriteria.dateRange?.start
        .toIso8601String()
        .substring(0, 10);
    final endDate = state.filterCriteria.dateRange?.end
        .toIso8601String()
        .substring(0, 10);

    final effectiveStatus = state.filterCriteria.status.isNotEmpty &&
            state.filterCriteria.status != 'all'
        ? state.filterCriteria.status
        : null;

    if (!event.isTeam) {
      // ── Tab 0: My Expenses (approver=false) ──────────────────────────
      emit(state.copyWith(isMyLoading: true, clearErrorMessage: true));
      try {
        final response = await _repository.getExpensesFeed(
          page: 1,
          size: defaultPageSize,
          approver: false,
          type: state.currentTypeFilter,
          status: effectiveStatus,
          search: search,
          startDate: startDate,
          endDate: endDate,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
        );

        emit(state.copyWith(
          status: ExpensesListStatus.success,
          isMyLoading: false,
          myExpenses: response.items,
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: ExpensesListStatus.failure,
          isMyLoading: false,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ));
      }
    } else {
      // ── Tab 1: Team Expenses (approver=true, penanganan 403) ─────────
      emit(state.copyWith(
        isTeamLoading: true,
        isTeamForbidden: false,
        clearErrorMessage: true,
      ));
      try {
        final response = await _repository.getExpensesFeed(
          page: 1,
          size: defaultPageSize,
          approver: true,
          type: state.currentTypeFilter,
          status: effectiveStatus,
          search: search,
          startDate: startDate,
          endDate: endDate,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
        );

        emit(state.copyWith(
          status: ExpensesListStatus.success,
          isTeamLoading: false,
          isTeamForbidden: false,
          teamExpenses: response.items,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        final is403 = (e is ApiException && e.statusCode == 403) ||
            e.toString().contains('403');

        if (is403) {
          emit(state.copyWith(
            status: ExpensesListStatus.failure,
            isTeamLoading: false,
            isTeamForbidden: true,
            teamExpenses: const [],
            errorMessage: e is ApiException
                ? e.message
                : 'Anda tidak memiliki wewenang approval pengeluaran',
          ));
        } else {
          emit(state.copyWith(
            status: ExpensesListStatus.failure,
            isTeamLoading: false,
            errorMessage: e is ApiException ? e.message : e.toString(),
          ));
        }
      }
    }
  }

  Future<void> _onLoadMoreRequested(
    ExpensesListLoadMoreRequested event,
    Emitter<ExpensesListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    final startDate = state.filterCriteria.dateRange?.start
        .toIso8601String()
        .substring(0, 10);
    final endDate = state.filterCriteria.dateRange?.end
        .toIso8601String()
        .substring(0, 10);

    final effectiveStatus = state.filterCriteria.status.isNotEmpty &&
            state.filterCriteria.status != 'all'
        ? state.filterCriteria.status
        : null;

    if (!event.isTeam) {
      if (state.isMyLoadingMore || state.myHasReachedMax) return;
      emit(state.copyWith(isMyLoadingMore: true));
      try {
        final nextPage = state.myCurrentPage + 1;
        final response = await _repository.getExpensesFeed(
          page: nextPage,
          size: defaultPageSize,
          approver: false,
          type: state.currentTypeFilter,
          status: effectiveStatus,
          search: search,
          startDate: startDate,
          endDate: endDate,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
        );

        emit(state.copyWith(
          isMyLoadingMore: false,
          myExpenses: [...state.myExpenses, ...response.items],
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        emit(state.copyWith(isMyLoadingMore: false));
      }
    } else {
      if (state.isTeamLoadingMore ||
          state.teamHasReachedMax ||
          state.isTeamForbidden) {
        return;
      }
      emit(state.copyWith(isTeamLoadingMore: true));
      try {
        final nextPage = state.teamCurrentPage + 1;
        final response = await _repository.getExpensesFeed(
          page: nextPage,
          size: defaultPageSize,
          approver: true,
          type: state.currentTypeFilter,
          status: effectiveStatus,
          search: search,
          startDate: startDate,
          endDate: endDate,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
        );

        emit(state.copyWith(
          isTeamLoadingMore: false,
          teamExpenses: [...state.teamExpenses, ...response.items],
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        emit(state.copyWith(isTeamLoadingMore: false));
      }
    }
  }
}
