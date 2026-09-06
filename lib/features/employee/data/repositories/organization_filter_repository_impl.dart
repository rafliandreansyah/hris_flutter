import 'package:hris_flutter/features/employee/data/datasources/organization_filter_remote_datasource.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';

class OrganizationFilterRepositoryImpl implements OrganizationFilterRepository {
  final OrganizationFilterRemoteDataSource _remoteDataSource;

  OrganizationFilterRepositoryImpl({
    OrganizationFilterRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? OrganizationFilterRemoteDataSourceImpl();

  @override
  Future<List<CompanyItem>> getCompanies({String? search}) {
    return _remoteDataSource.getCompanies(search: search);
  }

  @override
  Future<List<DepartmentItem>> getDepartments({
    String? companyId,
    String? search,
  }) {
    return _remoteDataSource.getDepartments(
      companyId: companyId,
      search: search,
    );
  }

  @override
  Future<List<PositionItem>> getPositions({
    String? companyId,
    String? departmentId,
    String? search,
  }) {
    return _remoteDataSource.getPositions(
      companyId: companyId,
      departmentId: departmentId,
      search: search,
    );
  }
}
