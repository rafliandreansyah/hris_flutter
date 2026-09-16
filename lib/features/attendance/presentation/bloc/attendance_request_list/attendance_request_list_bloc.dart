import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_request_repository_impl.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_filter_bottom_sheet.dart';

class AttendanceRequestListBloc
    extends Bloc<AttendanceRequestListEvent, AttendanceRequestListState> {
  final AttendanceRequestRepository _repository;

  static const int defaultPageSize = 20;

  AttendanceRequestListBloc({AttendanceRequestRepository? repository})
      : _repository = repository ?? AttendanceRequestRepositoryImpl(),
        super(const AttendanceRequestListState()) {
    on<AttendanceRequestListStarted>(_onStarted);
    on<AttendanceRequestListFetchRequested>(_onFetchRequested);
    on<AttendanceRequestListLoadMoreRequested>(_onLoadMoreRequested);
    on<AttendanceRequestListTabChanged>(_onTabChanged);
    on<AttendanceRequestListSearchChanged>(_onSearchChanged);
    on<AttendanceRequestListFilterApplied>(_onFilterApplied);
    on<AttendanceRequestListFilterReset>(_onFilterReset);
  }

  Future<void> _onStarted(
    AttendanceRequestListStarted event,
    Emitter<AttendanceRequestListState> emit,
  ) async {
    emit(state.copyWith(
      status: AttendanceRequestListStatus.loading,
      isMyLoading: true,
      isTeamLoading: true,
      isTeamForbidden: false,
      clearErrorMessage: true,
    ));

    // Muat data Tab 0 (Pengajuan Saya)
    try {
      final myResponse = await _repository.getAttendanceRequests(
        page: 1,
        size: defaultPageSize,
        companyId: state.filterCriteria.companyId,
        departmentId: state.filterCriteria.departmentId,
        positionId: state.filterCriteria.positionId,
        status: state.filterCriteria.status,
        startDate: state.filterCriteria.startDateParam,
        endDate: state.filterCriteria.endDateParam,
        approver: false,
      );

      emit(state.copyWith(
        status: AttendanceRequestListStatus.success,
        isMyLoading: false,
        myRequests: myResponse.data,
        myCurrentPage: myResponse.meta.page,
        myTotalPages: myResponse.meta.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestListStatus.failure,
        isMyLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }

    // Muat data Tab 1 (Persetujuan Tim)
    try {
      final search = state.searchQuery.trim().isNotEmpty
          ? state.searchQuery.trim()
          : null;

      final teamResponse = await _repository.getAttendanceRequests(
        page: 1,
        size: defaultPageSize,
        companyId: state.filterCriteria.companyId,
        departmentId: state.filterCriteria.departmentId,
        positionId: state.filterCriteria.positionId,
        search: search,
        status: state.filterCriteria.status,
        startDate: state.filterCriteria.startDateParam,
        endDate: state.filterCriteria.endDateParam,
        approver: true,
      );

      emit(state.copyWith(
        isTeamLoading: false,
        isTeamForbidden: false,
        hasLoadedTeam: true,
        teamRequests: teamResponse.data,
        teamCurrentPage: teamResponse.meta.page,
        teamTotalPages: teamResponse.meta.totalPages,
      ));
    } catch (e) {
      final is403 = (e is ApiException && e.statusCode == 403) ||
          e.toString().contains('403');

      if (is403) {
        emit(state.copyWith(
          isTeamLoading: false,
          isTeamForbidden: true,
          hasLoadedTeam: true,
          teamRequests: const [],
        ));
      } else {
        emit(state.copyWith(
          isTeamLoading: false,
          hasLoadedTeam: true,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ));
      }
    }
  }

  Future<void> _onFetchRequested(
    AttendanceRequestListFetchRequested event,
    Emitter<AttendanceRequestListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    if (!event.isTeam) {
      // ── Tab 0: Pengajuan Saya (approver=false) ────────────────────────
      emit(state.copyWith(
        isMyLoading: true,
        clearErrorMessage: true,
      ));

      try {
        final response = await _repository.getAttendanceRequests(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          status: state.filterCriteria.status,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
        );

        emit(state.copyWith(
          status: AttendanceRequestListStatus.success,
          isMyLoading: false,
          myRequests: response.data,
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: AttendanceRequestListStatus.failure,
          isMyLoading: false,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ));
      }
    } else {
      // ── Tab 1: Persetujuan Tim (approver=true, bisa 403) ──────────────
      emit(state.copyWith(
        isTeamLoading: true,
        isTeamForbidden: false,
        clearErrorMessage: true,
      ));

      try {
        final response = await _repository.getAttendanceRequests(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          status: state.filterCriteria.status,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
        );

        emit(state.copyWith(
          status: AttendanceRequestListStatus.success,
          isTeamLoading: false,
          isTeamForbidden: false,
          hasLoadedTeam: true,
          teamRequests: response.data,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        final is403 = (e is ApiException && e.statusCode == 403) ||
            e.toString().contains('403');

        if (is403) {
          emit(state.copyWith(
            status: AttendanceRequestListStatus.failure,
            isTeamLoading: false,
            isTeamForbidden: true,
            hasLoadedTeam: true,
            teamRequests: const [],
          ));
        } else {
          emit(state.copyWith(
            status: AttendanceRequestListStatus.failure,
            isTeamLoading: false,
            hasLoadedTeam: true,
            errorMessage: e is ApiException ? e.message : e.toString(),
          ));
        }
      }
    }
  }

  Future<void> _onLoadMoreRequested(
    AttendanceRequestListLoadMoreRequested event,
    Emitter<AttendanceRequestListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    if (!event.isTeam) {
      if (state.isMyLoading ||
          state.isMyLoadingMore ||
          state.myCurrentPage >= state.myTotalPages) {
        return;
      }

      emit(state.copyWith(isMyLoadingMore: true));

      try {
        final nextPage = state.myCurrentPage + 1;
        final response = await _repository.getAttendanceRequests(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          status: state.filterCriteria.status,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
        );

        emit(state.copyWith(
          isMyLoadingMore: false,
          myRequests: [...state.myRequests, ...response.data],
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (_) {
        emit(state.copyWith(isMyLoadingMore: false));
      }
    } else {
      if (state.isTeamLoading ||
          state.isTeamLoadingMore ||
          state.isTeamForbidden ||
          state.teamCurrentPage >= state.teamTotalPages) {
        return;
      }

      emit(state.copyWith(isTeamLoadingMore: true));

      try {
        final nextPage = state.teamCurrentPage + 1;
        final response = await _repository.getAttendanceRequests(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          status: state.filterCriteria.status,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
        );

        emit(state.copyWith(
          isTeamLoadingMore: false,
          teamRequests: [...state.teamRequests, ...response.data],
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (_) {
        emit(state.copyWith(isTeamLoadingMore: false));
      }
    }
  }

  void _onTabChanged(
    AttendanceRequestListTabChanged event,
    Emitter<AttendanceRequestListState> emit,
  ) {
    if (state.currentTabIndex == event.tabIndex) return;

    emit(state.copyWith(currentTabIndex: event.tabIndex));

    // Jika tab tim belum pernah dimuat dan tidak forbidden, muat sekarang
    if (event.tabIndex == 1 && !state.hasLoadedTeam && !state.isTeamForbidden) {
      add(const AttendanceRequestListFetchRequested(
        isRefresh: false,
        isTeam: true,
      ));
    }
  }

  void _onSearchChanged(
    AttendanceRequestListSearchChanged event,
    Emitter<AttendanceRequestListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    // Refetch tab tim dengan query pencarian baru
    add(const AttendanceRequestListFetchRequested(
      isRefresh: true,
      isTeam: true,
    ));
  }

  void _onFilterApplied(
    AttendanceRequestListFilterApplied event,
    Emitter<AttendanceRequestListState> emit,
  ) {
    emit(state.copyWith(filterCriteria: event.criteria));
    // Refetch kedua tab dengan kriteria filter baru
    add(const AttendanceRequestListFetchRequested(
      isRefresh: true,
      isTeam: false,
    ));
    add(const AttendanceRequestListFetchRequested(
      isRefresh: true,
      isTeam: true,
    ));
  }

  void _onFilterReset(
    AttendanceRequestListFilterReset event,
    Emitter<AttendanceRequestListState> emit,
  ) {
    emit(state.copyWith(
      filterCriteria: const AttendanceRequestFilterCriteria(),
    ));
    add(const AttendanceRequestListFetchRequested(
      isRefresh: true,
      isTeam: false,
    ));
    add(const AttendanceRequestListFetchRequested(
      isRefresh: true,
      isTeam: true,
    ));
  }
}
