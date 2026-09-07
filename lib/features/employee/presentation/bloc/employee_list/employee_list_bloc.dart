import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_state.dart';

export 'employee_list_event.dart';
export 'employee_list_state.dart';

class EmployeeListBloc extends Bloc<EmployeeListEvent, EmployeeListState> {
  final EmployeeRepository _repository;

  EmployeeListBloc({
    EmployeeRepository? repository,
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

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
  }

  Future<void> _onRefreshed(
    EmployeeListRefreshed event,
    Emitter<EmployeeListState> emit,
  ) async {
    if (state.customEmployees != null) {
      emit(state.copyWith(
        employees: List.from(state.customEmployees!),
        status: EmployeeListStatus.success,
        isLoading: false,
      ));
      return;
    }

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
  }

  Future<void> _onLoadMore(
    EmployeeListLoadMore event,
    Emitter<EmployeeListState> emit,
  ) async {
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
      final filtered = state.customEmployees!.where((emp) {
        if (event.query.trim().isEmpty) return true;
        final q = event.query.toLowerCase().trim();
        return emp.name.toLowerCase().contains(q) ||
            emp.role.toLowerCase().contains(q) ||
            emp.department.toLowerCase().contains(q) ||
            (emp.company?.toLowerCase().contains(q) ?? false);
      }).toList();

      emit(state.copyWith(
        employees: filtered,
        status: EmployeeListStatus.success,
      ));
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
      var filtered = List<EmployeeDirectoryItem>.from(state.customEmployees!);

      if (event.criteria.company != null &&
          event.criteria.company != 'Semua Perusahaan') {
        filtered = filtered
            .where((e) =>
                e.company == null ||
                e.company!.toLowerCase() ==
                    event.criteria.company!.toLowerCase())
            .toList();
      }
      if (event.criteria.department != null &&
          event.criteria.department != 'Semua Departemen') {
        filtered = filtered
            .where((e) =>
                e.department.toLowerCase() ==
                event.criteria.department!.toLowerCase())
            .toList();
      }
      if (event.criteria.position != null &&
          event.criteria.position != 'Semua Jabatan') {
        filtered = filtered
            .where((e) =>
                e.role.toLowerCase() ==
                event.criteria.position!.toLowerCase())
            .toList();
      }

      emit(state.copyWith(
        employees: filtered,
        status: EmployeeListStatus.success,
      ));
      return;
    }

    await _fetchPage(page: 1, isRefresh: true, emit: emit);
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
    } catch (e) {
      // Graceful fallback ke sample data jika unauthenticated atau offline
      final fallbackEmployees = state.employees.isEmpty
          ? List<EmployeeDirectoryItem>.from(EmployeeDirectoryItem.sampleEmployees)
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
