import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_list/overtime_list_event.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_list/overtime_list_state.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_filter_bottom_sheet.dart';

/// BLoC daftar permintaan lembur (Overtime Requests).
///
/// Mengelola dua tab:
///  - Tab 0 "My Overtime": `GET /overtime?approver=false`.
///  - Tab 1 "Team Overtime": `GET /overtime?approver=true` — lazy load saat
///    pertama kali dipilih; HTTP 403 (bukan approver) di-set menjadi state
///    `isTeamForbidden` khusus tanpa merusak tab My Overtime.
///
/// Debounce search (300ms) dilakukan di UI layer sebelum mengirim event
/// [OvertimeListSearchChanged], mengikuti pola ActivityScreen.
class OvertimeListBloc extends Bloc<OvertimeListEvent, OvertimeListState> {
  final OvertimeRepository _repository;

  /// Ukuran halaman sesuai spesifikasi backend (`size` default 30).
  static const int defaultPageSize = 30;

  OvertimeListBloc({OvertimeRepository? repository})
      : _repository = repository ?? OvertimeRepositoryImpl(),
        super(const OvertimeListState()) {
    on<OvertimeListStarted>(_onStarted);
    on<OvertimeListTabChanged>(_onTabChanged);
    on<OvertimeListFetchRequested>(_onFetchRequested);
    on<OvertimeListLoadMoreRequested>(_onLoadMoreRequested);
    on<OvertimeListSearchChanged>(_onSearchChanged);
    on<OvertimeListFilterApplied>(_onFilterApplied);
    on<OvertimeListFilterReset>(_onFilterReset);
  }

  void _onStarted(
    OvertimeListStarted event,
    Emitter<OvertimeListState> emit,
  ) {
    emit(state.copyWith(hasLoadedTeam: true));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
  }

  void _onTabChanged(
    OvertimeListTabChanged event,
    Emitter<OvertimeListState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  Future<void> _onFetchRequested(
    OvertimeListFetchRequested event,
    Emitter<OvertimeListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    final effectiveStatus = state.filterCriteria.status ??
        state.filterCriteria.statusApprove ??
        'all';

    if (!event.isTeam) {
      // ── Tab 0: My Overtime (approver=false) ──────────────────────────
      emit(state.copyWith(isMyLoading: true, clearErrorMessage: true));
      try {
        final response = await _repository.getOvertimeRequests(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: null,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
          status: effectiveStatus,
          statusApprove: effectiveStatus,
        );

        emit(state.copyWith(
          status: OvertimeListStatus.success,
          isMyLoading: false,
          myRequests: response.data,
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: OvertimeListStatus.failure,
          isMyLoading: false,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ));
      }
    } else {
      // ── Tab 1: Team Overtime (approver=true, bisa 403) ──────────────
      emit(state.copyWith(
        isTeamLoading: true,
        isTeamForbidden: false,
        clearErrorMessage: true,
      ));
      try {
        final response = await _repository.getOvertimeRequests(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
          status: effectiveStatus,
          statusApprove: effectiveStatus,
        );

        emit(state.copyWith(
          status: OvertimeListStatus.success,
          isTeamLoading: false,
          isTeamForbidden: false,
          teamRequests: response.data,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        // Penanganan khusus HTTP 403 Forbidden (bukan approver):
        // set flag isTeamForbidden tanpa mengganggu data tab My Overtime.
        final is403 = (e is ApiException && e.statusCode == 403) ||
            e.toString().contains('403');

        if (is403) {
          emit(state.copyWith(
            status: OvertimeListStatus.failure,
            isTeamLoading: false,
            isTeamForbidden: true,
            teamRequests: const [],
            errorMessage: e is ApiException
                ? e.message
                : 'Tidak memiliki hak akses approver (403)',
          ));
        } else {
          emit(state.copyWith(
            status: OvertimeListStatus.failure,
            isTeamLoading: false,
            errorMessage: e is ApiException ? e.message : e.toString(),
          ));
        }
      }
    }
  }

  Future<void> _onLoadMoreRequested(
    OvertimeListLoadMoreRequested event,
    Emitter<OvertimeListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    final effectiveStatus = state.filterCriteria.status ??
        state.filterCriteria.statusApprove ??
        'all';

    if (!event.isTeam) {
      if (state.isMyLoading ||
          state.isMyLoadingMore ||
          state.myCurrentPage >= state.myTotalPages) {
        return;
      }
      emit(state.copyWith(isMyLoadingMore: true));

      try {
        final nextPage = state.myCurrentPage + 1;
        final response = await _repository.getOvertimeRequests(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: null,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
          status: effectiveStatus,
          statusApprove: effectiveStatus,
        );

        final updatedList = [...state.myRequests, ...response.data];

        emit(state.copyWith(
          isMyLoadingMore: false,
          myRequests: updatedList,
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
        final response = await _repository.getOvertimeRequests(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
          status: effectiveStatus,
          statusApprove: effectiveStatus,
        );

        final updatedList = [...state.teamRequests, ...response.data];

        emit(state.copyWith(
          isTeamLoadingMore: false,
          teamRequests: updatedList,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (_) {
        emit(state.copyWith(isTeamLoadingMore: false));
      }
    }
  }

  Future<void> _onSearchChanged(
    OvertimeListSearchChanged event,
    Emitter<OvertimeListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
  }

  Future<void> _onFilterApplied(
    OvertimeListFilterApplied event,
    Emitter<OvertimeListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: event.criteria));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
  }

  Future<void> _onFilterReset(
    OvertimeListFilterReset event,
    Emitter<OvertimeListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: const OvertimeFilterCriteria()));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
  }
}
