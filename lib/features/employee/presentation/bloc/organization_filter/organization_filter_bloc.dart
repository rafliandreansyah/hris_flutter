import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';
import 'package:hris_flutter/features/employee/data/repositories/organization_filter_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_state.dart';

export 'organization_filter_event.dart';
export 'organization_filter_state.dart';

class OrganizationFilterBloc
    extends Bloc<OrganizationFilterEvent, OrganizationFilterState> {
  final OrganizationFilterRepository _repository;

  OrganizationFilterBloc({
    OrganizationFilterRepository? repository,
  })  : _repository = repository ?? OrganizationFilterRepositoryImpl(),
        super(const OrganizationFilterState()) {
    on<OrganizationFilterStarted>(_onStarted);
    on<OrganizationFilterCompanySelected>(_onCompanySelected);
    on<OrganizationFilterDepartmentSelected>(_onDepartmentSelected);
    on<OrganizationFilterRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    OrganizationFilterStarted event,
    Emitter<OrganizationFilterState> emit,
  ) async {
    if (state.companies.isNotEmpty && !event.forceRefresh) {
      return;
    }

    emit(state.copyWith(
      status: OrganizationFilterStatus.loadingCompanies,
      clearError: true,
    ));

    try {
      final companies = await _repository.getCompanies();
      emit(state.copyWith(
        status: OrganizationFilterStatus.loaded,
        companies: companies,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationFilterStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCompanySelected(
    OrganizationFilterCompanySelected event,
    Emitter<OrganizationFilterState> emit,
  ) async {
    final companyId = event.companyId;

    if (companyId == null || companyId.isEmpty) {
      emit(state.copyWith(
        clearSelectedCompany: true,
        clearSelectedDepartment: true,
        departments: const [],
        positions: const [],
      ));
      return;
    }

    emit(state.copyWith(
      selectedCompanyId: companyId,
      clearSelectedDepartment: true,
    ));

    final cachedDepts = state.cachedDepartmentsByCompany[companyId];
    final cachedPositions = state.cachedPositionsByCompany[companyId];

    if (cachedDepts != null && cachedPositions != null) {
      emit(state.copyWith(
        departments: cachedDepts,
        positions: cachedPositions,
        status: OrganizationFilterStatus.loaded,
      ));
      return;
    }

    emit(state.copyWith(status: OrganizationFilterStatus.loadingChildren));

    try {
      final depts = await _repository.getDepartments(companyId: companyId);
      final positions = await _repository.getPositions(companyId: companyId);

      final updatedCachedDepts =
          Map<String, List<DepartmentItem>>.from(state.cachedDepartmentsByCompany)
            ..[companyId] = depts;
      final updatedCachedPositions =
          Map<String, List<PositionItem>>.from(state.cachedPositionsByCompany)
            ..[companyId] = positions;

      emit(state.copyWith(
        status: OrganizationFilterStatus.loaded,
        departments: depts,
        positions: positions,
        cachedDepartmentsByCompany: updatedCachedDepts,
        cachedPositionsByCompany: updatedCachedPositions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrganizationFilterStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDepartmentSelected(
    OrganizationFilterDepartmentSelected event,
    Emitter<OrganizationFilterState> emit,
  ) async {
    emit(state.copyWith(
      selectedDepartmentId: event.departmentId,
    ));
  }

  Future<void> _onRefreshed(
    OrganizationFilterRefreshed event,
    Emitter<OrganizationFilterState> emit,
  ) async {
    add(const OrganizationFilterStarted(forceRefresh: true));
    if (event.currentCompanyId != null && event.currentCompanyId!.isNotEmpty) {
      add(OrganizationFilterCompanySelected(companyId: event.currentCompanyId));
    }
  }
}
