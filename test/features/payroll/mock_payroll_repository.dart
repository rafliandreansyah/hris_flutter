import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';

class MockPayrollRepository implements PayrollRepository {
  PayrollListResponseModel? mockMySlips;
  PayrollListResponseModel? mockPayrolls;
  PayrollEmployeeListResponseModel? mockEmployees;
  List<PayrollPeriodModel>? mockPeriods;
  PayrollDetailModel? mockPayrollDetail;
  PayrollDownloadResponseModel? mockDownloadResult;
  ApiException? errorToThrow;

  @override
  Future<PayrollListResponseModel> getMyPayslips({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockMySlips ??
        const PayrollListResponseModel(
          data: [],
          meta: PayrollPaginationMeta(
            page: 1,
            size: 10,
            total: 0,
            totalPages: 1,
          ),
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
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockPayrolls ??
        const PayrollListResponseModel(
          data: [],
          meta: PayrollPaginationMeta(
            page: 1,
            size: 10,
            total: 0,
            totalPages: 1,
          ),
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
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockEmployees ??
        const PayrollEmployeeListResponseModel(
          data: [],
          meta: PayrollPaginationMeta(
            page: 1,
            size: 20,
            total: 0,
            totalPages: 1,
          ),
        );
  }

  @override
  Future<List<PayrollPeriodModel>> getPayrollPeriods({
    String? companyId,
    String? status,
    int? year,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockPeriods ?? [];
  }

  @override
  Future<PayrollDetailModel> getPayrollDetail(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    if (mockPayrollDetail != null) return mockPayrollDetail!;
    throw const ApiException(message: 'Slip gaji tidak ditemukan');
  }

  @override
  Future<PayrollDownloadResponseModel> downloadPayslip(
    String id, {
    bool force = false,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockDownloadResult ??
        PayrollDownloadResponseModel(
          payrollId: id,
          payslipUrl: 'https://storage.googleapis.com/test/slip_$id.pdf',
          isNewlyGenerated: true,
        );
  }
}
