import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_event.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_state.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_filter_bottom_sheet.dart';

/// BLoC daftar pengajuan cuti/izin (Leave & Time Off).
///
/// Mengelola dua tab:
///  - Tab 0 "My Requests": `GET /leave-request?approver=false`.
///  - Tab 1 "Team Requests": `GET /leave-request?approver=true` — lazy load
///    saat pertama kali dipilih; HTTP 403 (bukan approver) di-set menjadi
///    state `isTeamForbidden` khusus tanpa merusak tab My Requests.
///
/// Debounce search (300ms) dilakukan di UI layer sebelum mengirim event
/// [LeaveListSearchChanged], mengikuti pola ActivityScreen.
class LeaveListBloc extends Bloc<LeaveListEvent, LeaveListState> {
  final LeaveRepository _repository;

  /// Ukuran halaman sesuai spesifikasi backend (`size` default 30).
  static const int defaultPageSize = 30;

  LeaveListBloc({LeaveRepository? repository})
      : _repository = repository ?? LeaveRepositoryImpl(),
        super(const LeaveListState()) {
    on<LeaveListStarted>(_onStarted);
    on<LeaveListTabChanged>(_onTabChanged);
    on<LeaveListFetchRequested>(_onFetchRequested);
    on<LeaveListLoadMoreRequested>(_onLoadMoreRequested);
    on<LeaveListSearchChanged>(_onSearchChanged);
    on<LeaveListFilterApplied>(_onFilterApplied);
    on<LeaveListFilterReset>(_onFilterReset);
  }

  void _onStarted(
    LeaveListStarted event,
    Emitter<LeaveListState> emit,
  ) {
    add(const LeaveListFetchRequested(isRefresh: true, isTeam: false));
  }

  void _onTabChanged(
    LeaveListTabChanged event,
    Emitter<LeaveListState> emit,
  ) {
    final newIndex = event.tabIndex;
    emit(state.copyWith(currentTabIndex: newIndex));

    // Lazy load tab Team Requests saat pertama kali dipilih.
    if (newIndex == 1 && !state.hasLoadedTeam) {
      emit(state.copyWith(hasLoadedTeam: true));
      add(const LeaveListFetchRequested(isRefresh: true, isTeam: true));
    }

    // Tab My Requests bisa ter-invalidate oleh search/filter saat tab Team
    // aktif — fetch ulang saat kembali ke tab 0 jika list-nya kosong.
    if (newIndex == 0 &&
        state.myRequests.isEmpty &&
        !state.isMyLoading &&
        !state.isMyLoadingMore) {
      add(const LeaveListFetchRequested(isRefresh: true, isTeam: false));
    }
  }

  Future<void> _onFetchRequested(
    LeaveListFetchRequested event,
    Emitter<LeaveListState> emit,
  ) async {
    final search = state.searchQuery.trim().isNotEmpty
        ? state.searchQuery.trim()
        : null;

    if (!event.isTeam) {
      // ── Tab 0: My Requests (approver=false) ──────────────────────────
      emit(state.copyWith(isMyLoading: true, clearErrorMessage: true));
      try {
        final response = await _repository.getLeaveRequests(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          statusApprove: state.filterCriteria.statusApprove,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
        );

        emit(state.copyWith(
          status: LeaveListStatus.success,
          isMyLoading: false,
          myRequests: response.data,
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: LeaveListStatus.failure,
          isMyLoading: false,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ));
      }
    } else {
      // ── Tab 1: Team Requests (approver=true, bisa 403) ───────────────
      emit(state.copyWith(
        isTeamLoading: true,
        isTeamForbidden: false,
        clearErrorMessage: true,
      ));
      try {
        final response = await _repository.getLeaveRequests(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          statusApprove: state.filterCriteria.statusApprove,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
        );

        emit(state.copyWith(
          status: LeaveListStatus.success,
          isTeamLoading: false,
          isTeamForbidden: false,
          teamRequests: response.data,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        // Penanganan khusus HTTP 403 Forbidden (bukan approver):
        // set flag isTeamForbidden tanpa mengganggu data tab My Requests.
        final is403 = (e is ApiException && e.statusCode == 403) ||
            e.toString().contains('403');

        if (is403) {
          emit(state.copyWith(
            status: LeaveListStatus.failure,
            isTeamLoading: false,
            isTeamForbidden: true,
            teamRequests: const [],
            errorMessage: e is ApiException
                ? e.message
                : 'Tidak memiliki hak akses approver (403)',
          ));
        } else {
          emit(state.copyWith(
            status: LeaveListStatus.failure,
            isTeamLoading: false,
            errorMessage: e is ApiException ? e.message : e.toString(),
          ));
        }
      }
    }
  }

  Future<void> _onLoadMoreRequested(
    LeaveListLoadMoreRequested event,
    Emitter<LeaveListState> emit,
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
        final response = await _repository.getLeaveRequests(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          statusApprove: state.filterCriteria.statusApprove,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
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
        final response = await _repository.getLeaveRequests(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: search,
          statusApprove: state.filterCriteria.statusApprove,
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
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
    LeaveListSearchChanged event,
    Emitter<LeaveListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));

    // Invalidate kedua tab: data lama tidak relevan dengan kata kunci baru.
    _invalidateInactiveTabs(emit);

    // Refetch tab aktif dengan kata kunci baru (server-side search).
    final isTeam = state.currentTabIndex == 1;
    if (isTeam) {
      add(const LeaveListFetchRequested(isRefresh: true, isTeam: true));
    } else {
      add(const LeaveListFetchRequested(isRefresh: true, isTeam: false));
    }
  }

  Future<void> _onFilterApplied(
    LeaveListFilterApplied event,
    Emitter<LeaveListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: event.criteria));

    _invalidateInactiveTabs(emit);

    final isTeam = state.currentTabIndex == 1;
    add(LeaveListFetchRequested(isRefresh: true, isTeam: isTeam));
  }

  Future<void> _onFilterReset(
    LeaveListFilterReset event,
    Emitter<LeaveListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: const LeaveFilterCriteria()));

    _invalidateInactiveTabs(emit);

    final isTeam = state.currentTabIndex == 1;
    add(LeaveListFetchRequested(isRefresh: true, isTeam: isTeam));
  }

  /// Kosongkan data tab yang tidak aktif agar di-fetch ulang (lazy) saat
  /// tab tersebut dibuka — filter/search lama tidak boleh menempel.
  void _invalidateInactiveTabs(Emitter<LeaveListState> emit) {
    final isTeamActive = state.currentTabIndex == 1;
    if (isTeamActive) {
      emit(state.copyWith(myRequests: const []));
    } else {
      emit(state.copyWith(teamRequests: const [], hasLoadedTeam: false));
    }
  }
}
