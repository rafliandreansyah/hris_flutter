import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';

abstract class PayrollRepository {
  Future<PayrollListResponseModel> getMyPayslips({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
  });

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
  });

  Future<PayrollEmployeeListResponseModel> getPayrollEmployees({
    int page = 1,
    int size = 20,
    String? search,
    String? companyId,
    String? departmentId,
    String? status,
  });

  Future<List<PayrollPeriodModel>> getPayrollPeriods({
    String? companyId,
    String? status,
    int? year,
  });

  Future<PayrollDetailModel> getPayrollDetail(String id);

  Future<PayrollDownloadResponseModel> downloadPayslip(
    String id, {
    bool force = false,
  });
}
