import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/datasources/payroll_remote_datasource.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  final PayrollRemoteDataSource _remoteDataSource;

  PayrollRepositoryImpl({PayrollRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? PayrollRemoteDataSourceImpl();

  @override
  Future<PayrollListResponseModel> getMyPayslips({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
  }) {
    return _remoteDataSource.getMyPayslips(
      page: page,
      size: size,
      year: year,
      month: month,
    );
  }

  @override
  Future<PayrollListResponseModel> getPayrolls({
    int page = 1,
    int size = 10,
    String? employeeId,
    String? companyId,
    String? departmentId,
    String? payrollPeriodId,
    int? year,
    int? month,
    String? status,
    String? search,
  }) {
    return _remoteDataSource.getPayrolls(
      page: page,
      size: size,
      employeeId: employeeId,
      companyId: companyId,
      departmentId: departmentId,
      payrollPeriodId: payrollPeriodId,
      year: year,
      month: month,
      status: status,
      search: search,
    );
  }


  @override
  Future<PayrollEmployeeListResponseModel> getPayrollEmployees({
    int page = 1,
    int size = 20,
    String? search,
    String? companyId,
    String? departmentId,
    String? status,
  }) {
    return _remoteDataSource.getPayrollEmployees(
      page: page,
      size: size,
      search: search,
      companyId: companyId,
      departmentId: departmentId,
      status: status,
    );
  }
  @override
  Future<List<PayrollPeriodModel>> getPayrollPeriods({
    String? companyId,
    String? status,
    int? year,
  }) {
    return _remoteDataSource.getPayrollPeriods(
      companyId: companyId,
      status: status,
      year: year,
    );
  }

  @override
  Future<PayrollDetailModel> getPayrollDetail(String id) {
    return _remoteDataSource.getPayrollDetail(id);
  }

  @override
  Future<PayrollDownloadResponseModel> downloadPayslip(
    String id, {
    bool force = false,
  }) {
    return _remoteDataSource.downloadPayslip(id, force: force);
  }
}
