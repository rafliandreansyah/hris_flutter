import 'package:hris_flutter/features/employee/data/datasources/employee_remote_datasource.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource _remoteDataSource;

  EmployeeRepositoryImpl({EmployeeRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? EmployeeRemoteDataSourceImpl();

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) {
    return _remoteDataSource.getEmployees(
      page: page,
      size: size,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
      search: search,
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) {
    return _remoteDataSource.getEmployeeDetail(employeeId);
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() {
    return _remoteDataSource.getCoworkers();
  }

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
