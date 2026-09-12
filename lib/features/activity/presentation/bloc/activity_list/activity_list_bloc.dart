import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_state.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';

class ActivityListBloc extends Bloc<ActivityListEvent, ActivityListState> {
  final ActivityRepository _repository;
  static const int defaultPageSize = 20;

  ActivityListBloc({ActivityRepository? repository})
      : _repository = repository ?? ActivityRepositoryImpl(),
        super(const ActivityListState()) {
    on<ActivityListStarted>(_onStarted);
    on<ActivityListTabChanged>(_onTabChanged);
    on<ActivityListFetchRequested>(_onFetchRequested);
    on<ActivityListLoadMoreRequested>(_onLoadMoreRequested);
    on<ActivityListSearchChanged>(_onSearchChanged);
    on<ActivityListFilterApplied>(_onFilterApplied);
    on<ActivityListActivityAdded>(_onActivityAdded);
  }

  void _onStarted(
    ActivityListStarted event,
    Emitter<ActivityListState> emit,
  ) {
    if (event.customActivities != null) {
      final custom = event.customActivities!;
      final filteredMy = _filterInMemory(
        baseList: custom,
        criteria: state.filterCriteria,
        searchQuery: '',
        myActivitiesOnly: true,
      );
      final filteredTeam = _filterInMemory(
        baseList: custom,
        criteria: state.filterCriteria,
        searchQuery: state.searchQuery,
        myActivitiesOnly: false,
      );

      emit(state.copyWith(
        status: ActivityListStatus.success,
        customActivities: custom,
        myActivities: filteredMy,
        teamActivities: filteredTeam,
        hasLoadedTeam: true,
      ));
    } else {
      emit(state.copyWith(hasLoadedTeam: true));
      add(const ActivityListFetchRequested(isRefresh: true, isTeam: false));
      add(const ActivityListFetchRequested(isRefresh: true, isTeam: true));
    }
  }

  void _onTabChanged(
    ActivityListTabChanged event,
    Emitter<ActivityListState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  Future<void> _onFetchRequested(
    ActivityListFetchRequested event,
    Emitter<ActivityListState> emit,
  ) async {
    // Jika menggunakan custom in-memory activities (mock / test)
    if (state.customActivities != null) {
      emit(state.copyWith(
        isMyLoading: !event.isTeam,
        isTeamLoading: event.isTeam,
      ));

      final myFiltered = _filterInMemory(
        baseList: state.customActivities!,
        criteria: state.filterCriteria,
        searchQuery: state.searchQuery,
        myActivitiesOnly: true,
      );
      final teamFiltered = _filterInMemory(
        baseList: state.customActivities!,
        criteria: state.filterCriteria,
        searchQuery: state.searchQuery,
        myActivitiesOnly: false,
      );

      emit(state.copyWith(
        status: ActivityListStatus.success,
        isMyLoading: false,
        isTeamLoading: false,
        myActivities: myFiltered,
        teamActivities: teamFiltered,
      ));
      return;
    }

    // Pemuatan via REST API
    if (!event.isTeam) {
      emit(state.copyWith(isMyLoading: true));
      try {
        final response = await _repository.getActivities(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: null,
          status: _resolveStatus(state.filterCriteria.status),
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
        );

        emit(state.copyWith(
          status: ActivityListStatus.success,
          isMyLoading: false,
          myActivities: response.data,
          myCurrentPage: response.meta.page,
          myTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        final fallback = state.myActivities.isEmpty
            ? ActivityItem.sampleActivities
                .where((a) => a.isMyActivity)
                .toList()
            : state.myActivities;

        emit(state.copyWith(
          status: ActivityListStatus.failure,
          isMyLoading: false,
          myActivities: fallback,
          errorMessage: e.toString(),
        ));
      }
    } else {
      emit(state.copyWith(
        isTeamLoading: true,
        isTeamForbidden: false,
      ));
      try {
        final response = await _repository.getActivities(
          page: 1,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: state.searchQuery.trim().isNotEmpty
              ? state.searchQuery.trim()
              : null,
          status: _resolveStatus(state.filterCriteria.status),
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
        );

        emit(state.copyWith(
          status: ActivityListStatus.success,
          isTeamLoading: false,
          isTeamForbidden: false,
          teamActivities: response.data,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (e) {
        final is403 = (e is ApiException && e.statusCode == 403) ||
            e.toString().contains('403') ||
            e.toString().toLowerCase().contains('hak akses');

        if (is403) {
          emit(state.copyWith(
            status: ActivityListStatus.failure,
            isTeamLoading: false,
            isTeamForbidden: true,
            teamActivities: const [],
            errorMessage: 'Tidak memiliki hak akses approver (403)',
          ));
        } else {
          final fallback = state.teamActivities.isEmpty
              ? List<ActivityItem>.from(ActivityItem.sampleActivities)
              : state.teamActivities;

          emit(state.copyWith(
            status: ActivityListStatus.failure,
            isTeamLoading: false,
            teamActivities: fallback,
            errorMessage: e.toString(),
          ));
        }
      }
    }
  }

  Future<void> _onLoadMoreRequested(
    ActivityListLoadMoreRequested event,
    Emitter<ActivityListState> emit,
  ) async {
    if (state.customActivities != null) return;

    if (!event.isTeam) {
      if (state.isMyLoading ||
          state.isMyLoadingMore ||
          state.myCurrentPage >= state.myTotalPages) {
        return;
      }
      emit(state.copyWith(isMyLoadingMore: true));

      try {
        final nextPage = state.myCurrentPage + 1;
        final response = await _repository.getActivities(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: null,
          status: _resolveStatus(state.filterCriteria.status),
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: false,
        );

        final updatedList = List<ActivityItem>.from(state.myActivities)
          ..addAll(response.data);

        emit(state.copyWith(
          isMyLoadingMore: false,
          myActivities: updatedList,
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
        final response = await _repository.getActivities(
          page: nextPage,
          size: defaultPageSize,
          companyId: state.filterCriteria.companyId,
          departmentId: state.filterCriteria.departmentId,
          positionId: state.filterCriteria.positionId,
          search: state.searchQuery.trim().isNotEmpty
              ? state.searchQuery.trim()
              : null,
          status: _resolveStatus(state.filterCriteria.status),
          startDate: state.filterCriteria.startDateParam,
          endDate: state.filterCriteria.endDateParam,
          approver: true,
        );

        final updatedList = List<ActivityItem>.from(state.teamActivities)
          ..addAll(response.data);

        emit(state.copyWith(
          isTeamLoadingMore: false,
          teamActivities: updatedList,
          teamCurrentPage: response.meta.page,
          teamTotalPages: response.meta.totalPages,
        ));
      } catch (_) {
        emit(state.copyWith(isTeamLoadingMore: false));
      }
    }
  }

  void _onSearchChanged(
    ActivityListSearchChanged event,
    Emitter<ActivityListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));

    if (state.customActivities != null) {
      final myFiltered = _filterInMemory(
        baseList: state.customActivities!,
        criteria: state.filterCriteria,
        searchQuery: '',
        myActivitiesOnly: true,
      );
      final teamFiltered = _filterInMemory(
        baseList: state.customActivities!,
        criteria: state.filterCriteria,
        searchQuery: event.query,
        myActivitiesOnly: false,
      );

      emit(state.copyWith(
        myActivities: myFiltered,
        teamActivities: teamFiltered,
      ));
    } else {
      add(const ActivityListFetchRequested(isRefresh: true, isTeam: true));
    }
  }

  void _onFilterApplied(
    ActivityListFilterApplied event,
    Emitter<ActivityListState> emit,
  ) {
    emit(state.copyWith(filterCriteria: event.criteria));

    if (state.customActivities != null) {
      final myFiltered = _filterInMemory(
        baseList: state.customActivities!,
        criteria: event.criteria,
        searchQuery: '',
        myActivitiesOnly: true,
      );
      final teamFiltered = _filterInMemory(
        baseList: state.customActivities!,
        criteria: event.criteria,
        searchQuery: state.searchQuery,
        myActivitiesOnly: false,
      );

      emit(state.copyWith(
        myActivities: myFiltered,
        teamActivities: teamFiltered,
      ));
    } else {
      add(const ActivityListFetchRequested(isRefresh: true, isTeam: false));
      add(const ActivityListFetchRequested(isRefresh: true, isTeam: true));
    }
  }

  void _onActivityAdded(
    ActivityListActivityAdded event,
    Emitter<ActivityListState> emit,
  ) {
    final updatedMy = List<ActivityItem>.from(state.myActivities)
      ..insert(0, event.activity);
    final updatedTeam = List<ActivityItem>.from(state.teamActivities)
      ..insert(0, event.activity);
    final updatedCustom = state.customActivities != null
        ? (List<ActivityItem>.from(state.customActivities!)
          ..insert(0, event.activity))
        : null;

    emit(state.copyWith(
      myActivities: updatedMy,
      teamActivities: updatedTeam,
      customActivities: updatedCustom,
    ));
  }

  /// Helper untuk menyaring data in-memory saat customActivities terpasang
  static List<ActivityItem> _filterInMemory({
    required List<ActivityItem> baseList,
    required ActivityFilterCriteria criteria,
    required String searchQuery,
    required bool myActivitiesOnly,
  }) {
    return baseList.where((item) {
      if (myActivitiesOnly && !item.isMyActivity) {
        return false;
      }

      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchUser = item.userName.toLowerCase().contains(q);
        final matchRole = item.userRole.toLowerCase().contains(q);
        final matchDept = item.department.toLowerCase().contains(q);
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        if (!matchUser &&
            !matchRole &&
            !matchDept &&
            !matchTitle &&
            !matchDesc) {
          return false;
        }
      }

      // Filter Status (ongoing, completed, canceled, all)
      final filterStatus = _resolveStatus(criteria.status);
      if (filterStatus != 'all' && filterStatus != 'ongoing') {
        final itemStatus = item.status.name.toLowerCase();
        if (filterStatus == 'completed' && itemStatus != 'completed') {
          return false;
        } else if ((filterStatus == 'canceled' || filterStatus == 'cancelled') &&
            itemStatus != 'canceled' &&
            itemStatus != 'cancelled') {
          return false;
        }
      }

      // Filter Tanggal
      if (criteria.dateRange != null) {
        final start = DateTime(
          criteria.dateRange!.start.year,
          criteria.dateRange!.start.month,
          criteria.dateRange!.start.day,
        );
        final end = DateTime(
          criteria.dateRange!.end.year,
          criteria.dateRange!.end.month,
          criteria.dateRange!.end.day,
          23,
          59,
          59,
        );
        if (item.date.isBefore(start) || item.date.isAfter(end)) {
          return false;
        }
      }

      // Filter Organisasi
      if (criteria.company != null &&
          criteria.company != 'Semua Perusahaan' &&
          criteria.company!.isNotEmpty) {
        if (!item.company.toLowerCase().contains(criteria.company!.toLowerCase())) {
          return false;
        }
      }
      if (criteria.department != null &&
          criteria.department != 'Semua Departemen' &&
          criteria.department!.isNotEmpty) {
        if (!item.department
            .toLowerCase()
            .contains(criteria.department!.toLowerCase())) {
          return false;
        }
      }
      if (criteria.position != null &&
          criteria.position != 'Semua Jabatan' &&
          criteria.position!.isNotEmpty) {
        if (!item.userRole
            .toLowerCase()
            .contains(criteria.position!.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Memastikan status bernilai valid enum ('ongoing', 'completed', 'canceled', 'all').
  /// Jika null, kosong, atau 'semua', mengembalikan 'all'.
  static String _resolveStatus(String? status) {
    if (status == null) return 'all';
    final trimmed = status.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'all' || trimmed == 'semua') {
      return 'all';
    }
    if (trimmed == 'canceled' || trimmed == 'cancelled') {
      return 'canceled';
    }
    return trimmed;
  }
}
