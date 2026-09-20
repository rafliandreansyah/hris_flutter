import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/features/warning_letter/data/repositories/warning_letter_repository_impl.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_state.dart';

class WarningLetterListBloc
    extends Bloc<WarningLetterListEvent, WarningLetterListState> {
  final WarningLetterRepository _repository;

  static const int defaultPageSize = 10;

  WarningLetterListBloc({WarningLetterRepository? repository})
      : _repository = repository ?? WarningLetterRepositoryImpl(),
        super(const WarningLetterListState()) {
    on<WarningLetterListStarted>(_onStarted);
    on<WarningLetterListTabChanged>(_onTabChanged);
    on<WarningLetterListSearchChanged>(_onSearchChanged, transformer: debounceRestartable());
    on<WarningLetterListFilterApplied>(_onFilterApplied);
    on<WarningLetterListFetchRequested>(_onFetchRequested);
    on<WarningLetterListLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onStarted(
    WarningLetterListStarted event,
    Emitter<WarningLetterListState> emit,
  ) async {
    emit(state.copyWith(
      isMyLoading: true,
      isTeamLoading: true,
      isTeamForbidden: false,
      clearMyError: true,
      clearTeamError: true,
      isLetterTypesLoading: true,
    ));

    // 1. Prefetch master data tipe SP untuk filter bottom sheet
    unawaited(_loadWarningLetterTypes(emit));

    // 2. Muat Tab 0: Surat Diterima (approver: false)
    await _fetchMyLetters(emit, page: 1, isRefresh: true);

    // 3. Muat Tab 1: Diterbitkan (approver: true)
    await _fetchTeamLetters(emit, page: 1, isRefresh: true);
  }

  Future<void> _loadWarningLetterTypes(
    Emitter<WarningLetterListState> emit,
  ) async {
    try {
      final types = await _repository.getWarningLetterTypes();
      emit(state.copyWith(
        letterTypes: types,
        isLetterTypesLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLetterTypesLoading: false));
    }
  }

  Future<void> _onTabChanged(
    WarningLetterListTabChanged event,
    Emitter<WarningLetterListState> emit,
  ) async {
    if (state.currentTabIndex == event.tabIndex) return;
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  Future<void> _onSearchChanged(
    WarningLetterListSearchChanged event,
    Emitter<WarningLetterListState> emit,
  ) async {
    if (state.searchQuery == event.query) return;
    emit(state.copyWith(searchQuery: event.query));

    // Search hanya berlaku untuk tab 1 (Diterbitkan)
    emit(state.copyWith(isTeamLoading: true, clearTeamError: true));
    await _fetchTeamLetters(emit, page: 1, isRefresh: true);
  }

  Future<void> _onFilterApplied(
    WarningLetterListFilterApplied event,
    Emitter<WarningLetterListState> emit,
  ) async {
    emit(state.copyWith(
      filterCriteria: event.filterCriteria,
      isMyLoading: true,
      isTeamLoading: true,
      clearMyError: true,
      clearTeamError: true,
    ));

    await Future.wait([
      _fetchMyLetters(emit, page: 1, isRefresh: true),
      _fetchTeamLetters(emit, page: 1, isRefresh: true),
    ]);
  }

  Future<void> _onFetchRequested(
    WarningLetterListFetchRequested event,
    Emitter<WarningLetterListState> emit,
  ) async {
    if (event.isTeam) {
      emit(state.copyWith(isTeamLoading: true, clearTeamError: true));
      await _fetchTeamLetters(emit, page: 1, isRefresh: true);
    } else {
      emit(state.copyWith(isMyLoading: true, clearMyError: true));
      await _fetchMyLetters(emit, page: 1, isRefresh: true);
    }
  }

  Future<void> _onLoadMoreRequested(
    WarningLetterListLoadMoreRequested event,
    Emitter<WarningLetterListState> emit,
  ) async {
    if (event.isTeam) {
      if (state.isTeamLoadingMore ||
          !state.hasTeamNextPage ||
          state.isTeamForbidden) {
        return;
      }
      emit(state.copyWith(isTeamLoadingMore: true));
      await _fetchTeamLetters(
        emit,
        page: state.teamCurrentPage + 1,
        isRefresh: false,
      );
    } else {
      if (state.isMyLoadingMore || !state.hasMyNextPage) {
        return;
      }
      emit(state.copyWith(isMyLoadingMore: true));
      await _fetchMyLetters(
        emit,
        page: state.myCurrentPage + 1,
        isRefresh: false,
      );
    }
  }

  // ── Fetch Tab 0 (Surat Diterima) ───────────────────────────────────
  Future<void> _fetchMyLetters(
    Emitter<WarningLetterListState> emit, {
    required int page,
    required bool isRefresh,
  }) async {
    try {
      final response = await _repository.getWarningLetters(
        page: page,
        size: defaultPageSize,
        letterTypeId: state.filterCriteria.letterTypeId,
        status: state.filterCriteria.status,
        approver: false,
        startDate: state.filterCriteria.startDateParam,
        endDate: state.filterCriteria.endDateParam,
      );

      final updatedList = isRefresh
          ? response.data
          : [...state.myLetters, ...response.data];

      emit(state.copyWith(
        isMyLoading: false,
        isMyLoadingMore: false,
        myLetters: updatedList,
        myCurrentPage: response.meta.page,
        myTotalPages: response.meta.totalPages,
        myTotal: response.meta.total,
        clearMyError: true,
      ));
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(
        isMyLoading: false,
        isMyLoadingMore: false,
        myError: errorMsg,
      ));
    }
  }

  // ── Fetch Tab 1 (Diterbitkan - Pegawai Lain) ────────────────────────
  Future<void> _fetchTeamLetters(
    Emitter<WarningLetterListState> emit, {
    required int page,
    required bool isRefresh,
  }) async {
    try {
      final search = state.searchQuery.trim().isNotEmpty
          ? state.searchQuery.trim()
          : null;

      final response = await _repository.getWarningLetters(
        page: page,
        size: defaultPageSize,
        letterTypeId: state.filterCriteria.letterTypeId,
        status: state.filterCriteria.status,
        search: search,
        approver: true,
        startDate: state.filterCriteria.startDateParam,
        endDate: state.filterCriteria.endDateParam,
      );

      final updatedList = isRefresh
          ? response.data
          : [...state.teamLetters, ...response.data];

      emit(state.copyWith(
        isTeamLoading: false,
        isTeamLoadingMore: false,
        isTeamForbidden: false,
        teamLetters: updatedList,
        teamCurrentPage: response.meta.page,
        teamTotalPages: response.meta.totalPages,
        teamTotal: response.meta.total,
        clearTeamError: true,
      ));
    } catch (e) {
      final is403 = (e is ApiException && e.statusCode == 403) ||
          e.toString().contains('403');

      if (is403) {
        emit(state.copyWith(
          isTeamLoading: false,
          isTeamLoadingMore: false,
          isTeamForbidden: true,
          teamLetters: const [],
          clearTeamError: true,
        ));
      } else {
        final errorMsg = e is ApiException ? e.message : e.toString();
        emit(state.copyWith(
          isTeamLoading: false,
          isTeamLoadingMore: false,
          teamError: errorMsg,
        ));
      }
    }
  }
}
