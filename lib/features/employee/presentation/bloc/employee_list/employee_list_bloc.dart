import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_state.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';

export 'employee_list_event.dart';
export 'employee_list_state.dart';

class EmployeeListBloc extends Bloc<EmployeeListEvent, EmployeeListState> {
  final EmployeeRepository _repository;
  final AttendanceRepository? attendanceRepository;
  bool isTeamAttendance;
  List<EmployeeDirectoryItem>? _teamEmployees;

  EmployeeListBloc({
    EmployeeRepository? repository,
    this.attendanceRepository,
    this.isTeamAttendance = false,
    List<EmployeeDirectoryItem>? initialCustomEmployees,
  })  : _repository = repository ?? EmployeeRepositoryImpl(),
        super(EmployeeListState(
          customEmployees: initialCustomEmployees,
          employees: initialCustomEmployees != null
              ? List.from(initialCustomEmployees)
              : const [],
          status: initialCustomEmployees != null
              ? EmployeeListStatus.success
              : EmployeeListStatus.initial,
          isTeamAttendance: isTeamAttendance,
        )) {
    on<EmployeeListStarted>(_onStarted);
    on<EmployeeListRefreshed>(_onRefreshed);
    on<EmployeeListLoadMore>(_onLoadMore);
    on<EmployeeListSearchChanged>(_onSearchChanged);
    on<EmployeeListFilterApplied>(_onFilterApplied);
  }

  Future<void> _onStarted(
    EmployeeListStarted event,
    Emitter<EmployeeListState> emit,
  ) async {
    if (event.isTeamAttendance != null) {
      isTeamAttendance = event.isTeamAttendance!;
    }

    if (event.customEmployees != null) {
      emit(state.copyWith(
        customEmployees: event.customEmployees,
        employees: List.from(event.customEmployees!),
        status: EmployeeListStatus.success,
        isLoading: false,
      ));
      return;
    }

    if (state.customEmployees != null) {
      return;
    }

    if (isTeamAttendance) {
      await _fetchTeamAttendance(emit: emit);
      return;
    }

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
  }

  Future<void> _onRefreshed(
    EmployeeListRefreshed event,
    Emitter<EmployeeListState> emit,
  ) async {
    if (event.isTeamAttendance != null) {
      isTeamAttendance = event.isTeamAttendance!;
    }

    if (state.customEmployees != null) {
      emit(state.copyWith(
        employees: List.from(state.customEmployees!),
        status: EmployeeListStatus.success,
        isLoading: false,
      ));
      return;
    }

    if (isTeamAttendance) {
      await _fetchTeamAttendance(emit: emit);
      return;
    }

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
  }

  Future<void> _onLoadMore(
    EmployeeListLoadMore event,
    Emitter<EmployeeListState> emit,
  ) async {
    if (isTeamAttendance) return;
    if (state.customEmployees != null) return;
    if (state.isLoading || state.isLoadingMore) return;
    if (state.currentPage >= state.totalPages) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getEmployees(
        page: nextPage,
        size: state.pageSize,
        companyId: state.filterCriteria.companyId,
        departmentId: state.filterCriteria.departmentId,
        positionId: state.filterCriteria.positionId,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
      );

      final combinedList = [...state.employees, ...response.data];
      emit(state.copyWith(
        employees: combinedList,
        currentPage: response.meta.page,
        totalPages: response.meta.totalPages,
        isLoadingMore: false,
        status: EmployeeListStatus.success,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSearchChanged(
    EmployeeListSearchChanged event,
    Emitter<EmployeeListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));

    if (state.customEmployees != null) {
      final filtered = _filterEmployees(
        state.customEmployees!,
        query: event.query,
        criteria: state.filterCriteria,
      );

      emit(state.copyWith(
        employees: filtered,
        status: EmployeeListStatus.success,
      ));
      return;
    }

    if (isTeamAttendance) {
      if (_teamEmployees != null) {
        final filtered = _filterEmployees(
          _teamEmployees!,
          query: event.query,
          criteria: state.filterCriteria,
        );
        emit(state.copyWith(
          employees: filtered,
          status: EmployeeListStatus.success,
        ));
      } else {
        await _fetchTeamAttendance(emit: emit);
      }
      return;
    }

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
  }

  Future<void> _onFilterApplied(
    EmployeeListFilterApplied event,
    Emitter<EmployeeListState> emit,
  ) async {
    emit(state.copyWith(filterCriteria: event.criteria));

    if (state.customEmployees != null) {
      final filtered = _filterEmployees(
        state.customEmployees!,
        query: state.searchQuery,
        criteria: event.criteria,
      );

      emit(state.copyWith(
        employees: filtered,
        status: EmployeeListStatus.success,
      ));
      return;
    }

    if (isTeamAttendance) {
      if (_teamEmployees != null) {
        final filtered = _filterEmployees(
          _teamEmployees!,
          query: state.searchQuery,
          criteria: event.criteria,
        );
        emit(state.copyWith(
          employees: filtered,
          status: EmployeeListStatus.success,
        ));
      } else {
        await _fetchTeamAttendance(emit: emit);
      }
      return;
    }

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
  }

  List<EmployeeDirectoryItem> _filterEmployees(
    List<EmployeeDirectoryItem> source, {
    required String query,
    required EmployeeFilterCriteria criteria,
  }) {
    var result = source;

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      result = result.where((emp) {
        return emp.name.toLowerCase().contains(q) ||
            emp.role.toLowerCase().contains(q) ||
            emp.department.toLowerCase().contains(q) ||
            (emp.company?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (criteria.company != null &&
        criteria.company != 'Semua Perusahaan') {
      result = result
          .where((e) =>
              e.company == null ||
              e.company!.toLowerCase() == criteria.company!.toLowerCase())
          .toList();
    }
    if (criteria.department != null &&
        criteria.department != 'Semua Departemen') {
      result = result
          .where((e) =>
              e.department.toLowerCase() ==
              criteria.department!.toLowerCase())
          .toList();
    }
    if (criteria.position != null &&
        criteria.position != 'Semua Jabatan') {
      result = result
          .where((e) =>
              e.role.toLowerCase() == criteria.position!.toLowerCase())
          .toList();
    }

    return result;
  }

  Future<void> _fetchTeamAttendance({
    required Emitter<EmployeeListState> emit,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      status: EmployeeListStatus.loading,
      clearError: true,
      isTeamAttendance: true,
    ));

    try {
      final repo = attendanceRepository ?? AttendanceRepositoryImpl();
      final list = await repo.getAttendanceEmployees();
      _teamEmployees = list;

      final filtered = _filterEmployees(
        list,
        query: state.searchQuery,
        criteria: state.filterCriteria,
      );

      emit(state.copyWith(
        employees: filtered,
        currentPage: 1,
        totalPages: 1,
        isLoading: false,
        status: EmployeeListStatus.success,
        isTeamAttendance: true,
      ));
    } on ApiException catch (e) {
      final msg = e.statusCode == 403 ? 'Tidak ada hak akses' : e.message;
      emit(state.copyWith(
        employees: const [],
        isLoading: false,
        status: EmployeeListStatus.failure,
        errorMessage: msg,
        statusCode: e.statusCode,
        isTeamAttendance: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        employees: const [],
        isLoading: false,
        status: EmployeeListStatus.failure,
        errorMessage: e.toString(),
        isTeamAttendance: true,
      ));
    }
  }

  Future<void> _fetchPage({
    required int page,
    required bool isRefresh,
    required Emitter<EmployeeListState> emit,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      status: isRefresh ? EmployeeListStatus.loading : state.status,
      clearError: true,
    ));

    try {
      final response = await _repository.getEmployees(
        page: page,
        size: state.pageSize,
        companyId: state.filterCriteria.companyId,
        departmentId: state.filterCriteria.departmentId,
        positionId: state.filterCriteria.positionId,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
      );

      emit(state.copyWith(
        employees: response.data,
        currentPage: response.meta.page,
        totalPages: response.meta.totalPages,
        isLoading: false,
        status: EmployeeListStatus.success,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        status: EmployeeListStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      // Graceful fallback ke sample data jika unauthenticated atau offline
      final fallbackEmployees = state.employees.isEmpty
          ? List<EmployeeDirectoryItem>.from(
              EmployeeDirectoryItem.sampleEmployees,
            )
          : state.employees;

      emit(state.copyWith(
        employees: fallbackEmployees,
        isLoading: false,
        status: EmployeeListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
