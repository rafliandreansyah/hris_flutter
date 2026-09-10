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
    add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
  }

  void _onTabChanged(
    OvertimeListTabChanged event,
    Emitter<OvertimeListState> emit,
  ) {
    final newIndex = event.tabIndex;
    emit(state.copyWith(currentTabIndex: newIndex));

    // Lazy load tab Team Overtime saat pertama kali dipilih.
    if (newIndex == 1 && !state.hasLoadedTeam) {
      emit(state.copyWith(hasLoadedTeam: true));
      add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
    }

    // Tab My Overtime bisa ter-invalidate oleh search/filter saat tab Team
    // aktif — fetch ulang saat kembali ke tab 0 jika list-nya kosong.
    if (newIndex == 0 &&
        state.myRequests.isEmpty &&
        !state.isMyLoading &&
        !state.isMyLoadingMore) {
      add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
    }
  }

  Future<void> _onFetchRequested(
    OvertimeListFetchRequested event,
    Emitter<OvertimeListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

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
          search: search,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
          status: state.filterCriteria.statusApprove,
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
          status: state.filterCriteria.statusApprove,
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
          search: search,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
          status: state.filterCriteria.statusApprove,
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
          status: state.filterCriteria.statusApprove,
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

    // Invalidate kedua tab: data lama tidak relevan dengan kata kunci baru.
    _invalidateInactiveTabs(emit);

    // Refetch tab aktif dengan kata kunci baru (server-side search).
    final isTeam = state.currentTabIndex == 1;
    if (isTeam) {
      add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
    } else {
      add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
    }
  }

  Future<void> _onFilterApplied(
    OvertimeListFilterApplied event,
    Emitter<OvertimeListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: event.criteria));

    _invalidateInactiveTabs(emit);

    final isTeam = state.currentTabIndex == 1;
    add(OvertimeListFetchRequested(isRefresh: true, isTeam: isTeam));
  }

  Future<void> _onFilterReset(
    OvertimeListFilterReset event,
    Emitter<OvertimeListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: const OvertimeFilterCriteria()));

    _invalidateInactiveTabs(emit);

    final isTeam = state.currentTabIndex == 1;
    add(OvertimeListFetchRequested(isRefresh: true, isTeam: isTeam));
  }

  /// Kosongkan data tab yang tidak aktif agar di-fetch ulang (lazy) saat
  /// tab tersebut dibuka — filter/search lama tidak boleh menempel.
  void _invalidateInactiveTabs(Emitter<OvertimeListState> emit) {
    final isTeamActive = state.currentTabIndex == 1;
    if (isTeamActive) {
      emit(state.copyWith(myRequests: const []));
    } else {
      emit(state.copyWith(teamRequests: const [], hasLoadedTeam: false));
    }
  }
}
