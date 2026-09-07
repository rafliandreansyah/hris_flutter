import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';

enum OrganizationFilterStatus {
  initial,
  loadingCompanies,
  loaded,
  loadingChildren,
  failure,
}

class OrganizationFilterState extends Equatable {
  final OrganizationFilterStatus status;
  final List<CompanyItem> companies;
  final List<DepartmentItem> departments;
  final List<PositionItem> positions;
  final String? selectedCompanyId;
  final String? selectedDepartmentId;

  // In-memory cache per companyId
  final Map<String, List<DepartmentItem>> cachedDepartmentsByCompany;
  final Map<String, List<PositionItem>> cachedPositionsByCompany;

  final String? errorMessage;

  const OrganizationFilterState({
    this.status = OrganizationFilterStatus.initial,
    this.companies = const [],
    this.departments = const [],
    this.positions = const [],
    this.selectedCompanyId,
    this.selectedDepartmentId,
    this.cachedDepartmentsByCompany = const {},
    this.cachedPositionsByCompany = const {},
    this.errorMessage,
  });

  OrganizationFilterState copyWith({
    OrganizationFilterStatus? status,
    List<CompanyItem>? companies,
    List<DepartmentItem>? departments,
    List<PositionItem>? positions,
    String? selectedCompanyId,
    bool clearSelectedCompany = false,
    String? selectedDepartmentId,
    bool clearSelectedDepartment = false,
    Map<String, List<DepartmentItem>>? cachedDepartmentsByCompany,
    Map<String, List<PositionItem>>? cachedPositionsByCompany,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrganizationFilterState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      departments: departments ?? this.departments,
      positions: positions ?? this.positions,
      selectedCompanyId: clearSelectedCompany
          ? null
          : (selectedCompanyId ?? this.selectedCompanyId),
      selectedDepartmentId: clearSelectedDepartment
          ? null
          : (selectedDepartmentId ?? this.selectedDepartmentId),
      cachedDepartmentsByCompany:
          cachedDepartmentsByCompany ?? this.cachedDepartmentsByCompany,
      cachedPositionsByCompany:
          cachedPositionsByCompany ?? this.cachedPositionsByCompany,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isLoadingCompanies =>
      status == OrganizationFilterStatus.loadingCompanies;
  bool get isLoadingDepartments =>
      status == OrganizationFilterStatus.loadingChildren;
  bool get isLoadingPositions =>
      status == OrganizationFilterStatus.loadingChildren;

  @override
  List<Object?> get props => [
        status,
        companies,
        departments,
        positions,
        selectedCompanyId,
        selectedDepartmentId,
        cachedDepartmentsByCompany,
        cachedPositionsByCompany,
        errorMessage,
      ];
}
