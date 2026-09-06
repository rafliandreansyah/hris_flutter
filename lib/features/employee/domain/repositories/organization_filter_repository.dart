import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';

abstract class OrganizationFilterRepository {
  Future<List<CompanyItem>> getCompanies({String? search});
  Future<List<DepartmentItem>> getDepartments({
    String? companyId,
    String? search,
  });
  Future<List<PositionItem>> getPositions({
    String? companyId,
    String? departmentId,
    String? search,
  });
}
