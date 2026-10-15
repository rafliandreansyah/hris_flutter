import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/payroll/data/datasources/payroll_remote_datasource.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/data/repositories/payroll_repository_impl.dart';

class _MockPayrollRemoteDataSource implements PayrollRemoteDataSource {
  int getMyPayslipsCallCount = 0;
  int getPayrollsCallCount = 0;
  int getPayrollEmployeesCallCount = 0;
  int getPayrollPeriodsCallCount = 0;
  int getPayrollDetailCallCount = 0;
  int downloadPayslipCallCount = 0;
  String? lastDownloadId;
  bool? lastDownloadForce;

  dynamic mockMyPayslipsResult;
  dynamic mockPayrollsResult;
  dynamic mockEmployeesResult;
  List<PayrollPeriodModel> mockPeriodsResult = [];
  dynamic mockDetailResult;
  dynamic mockDownloadResult;

  @override
  Future<PayrollListResponseModel> getMyPayslips({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
  }) async {
    getMyPayslipsCallCount++;
    return mockMyPayslipsResult as PayrollListResponseModel;
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
    getPayrollsCallCount++;
    return mockPayrollsResult as PayrollListResponseModel;
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
    getPayrollEmployeesCallCount++;
    return mockEmployeesResult as PayrollEmployeeListResponseModel;
  }

  @override
  Future<List<PayrollPeriodModel>> getPayrollPeriods({
    String? companyId,
    String? status,
    int? year,
  }) async {
    getPayrollPeriodsCallCount++;
    return mockPeriodsResult;
  }

  @override
  Future<PayrollDetailModel> getPayrollDetail(String id) async {
    getPayrollDetailCallCount++;
    return mockDetailResult as PayrollDetailModel;
  }

  @override
  Future<PayrollDownloadResponseModel> downloadPayslip(
    String id, {
    bool force = false,
  }) async {
    downloadPayslipCallCount++;
    lastDownloadId = id;
    lastDownloadForce = force;
    return mockDownloadResult as PayrollDownloadResponseModel;
  }
}

void main() {
  group('PayrollRepositoryImpl Tests', () {
    late _MockPayrollRemoteDataSource mockRemoteDataSource;
    late PayrollRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockPayrollRemoteDataSource();
      repository = PayrollRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getMyPayslips delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockMyPayslipsResult = PayrollListResponseModel.fromJson({
        'data': [
          {
            'id': 'slip-1',
            'employeeId': 'emp-1',
            'grossSalary': 10000000.0,
            'deductions': 1000000.0,
            'netSalary': 9000000.0,
            'status': 'paid',
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getMyPayslips(page: 1, size: 10);

      expect(mockRemoteDataSource.getMyPayslipsCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('slip-1'));
    });

    test('getPayrolls delegates to remote data source', () async {
      mockRemoteDataSource.mockPayrollsResult = PayrollListResponseModel.fromJson({
        'data': [
          {
            'id': 'slip-2',
            'employeeId': 'emp-2',
            'grossSalary': 12000000.0,
            'deductions': 1200000.0,
            'netSalary': 10800000.0,
            'status': 'paid',
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getPayrolls(
        page: 1,
        size: 10,
        status: 'paid',
      );

      expect(mockRemoteDataSource.getPayrollsCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('slip-2'));
    });

    test('getPayrollEmployees delegates to remote data source', () async {
      mockRemoteDataSource.mockEmployeesResult = PayrollEmployeeListResponseModel.fromJson({
        'data': [
          {
            'id': 'emp-101',
            'name': 'Budi Santoso',
            'firstName': 'Budi',
            'lastName': 'Santoso',
            'company': {'id': 'comp-1', 'name': 'PT Muratech'},
            'department': {'id': 'dept-1', 'name': 'IT'},
            'position': {'id': 'pos-1', 'name': 'Dev'},
          }
        ],
        'meta': {'page': 1, 'size': 20, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getPayrollEmployees(page: 1, size: 20);

      expect(mockRemoteDataSource.getPayrollEmployeesCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.displayName, equals('Budi Santoso'));
    });

    test('getPayrollPeriods delegates to remote data source', () async {
      mockRemoteDataSource.mockPeriodsResult = [
        PayrollPeriodModel.fromJson({
          'id': 'prd-1',
          'month': 10,
          'year': 2026,
          'label': 'Oktober 2026',
          'startDate': '2026-09-26',
          'endDate': '2026-10-25',
          'payDate': '2026-10-25',
          'status': 'open',
        }),
      ];

      final result = await repository.getPayrollPeriods();

      expect(mockRemoteDataSource.getPayrollPeriodsCallCount, equals(1));
      expect(result.length, equals(1));
      expect(result.first.id, equals('prd-1'));
    });

    test('getPayrollDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockDetailResult = PayrollDetailModel.fromJson({
        'id': 'slip-1',
        'grossSalary': 10000000.0,
        'deductions': 1000000.0,
        'netSalary': 9000000.0,
        'status': 'paid',
      });

      final result = await repository.getPayrollDetail('slip-1');

      expect(mockRemoteDataSource.getPayrollDetailCallCount, equals(1));
      expect(result.id, equals('slip-1'));
      expect(result.netSalary, equals(9000000.0));
    });

    test('downloadPayslip delegates to remote data source', () async {
      mockRemoteDataSource.mockDownloadResult = const PayrollDownloadResponseModel(
        payrollId: 'slip-1',
        payslipUrl: 'https://example.com/slip.pdf',
        isNewlyGenerated: true,
      );

      final result = await repository.downloadPayslip('slip-1', force: true);

      expect(mockRemoteDataSource.downloadPayslipCallCount, equals(1));
      expect(mockRemoteDataSource.lastDownloadId, equals('slip-1'));
      expect(mockRemoteDataSource.lastDownloadForce, isTrue);
      expect(result.payrollId, equals('slip-1'));
      expect(result.payslipUrl, equals('https://example.com/slip.pdf'));
    });

    test('downloadPayslip memakai force=false secara default', () async {
      mockRemoteDataSource.mockDownloadResult = const PayrollDownloadResponseModel(
        payrollId: 'slip-2',
        payslipUrl: 'https://example.com/slip2.pdf',
        isNewlyGenerated: false,
      );

      await repository.downloadPayslip('slip-2');

      expect(mockRemoteDataSource.lastDownloadForce, isFalse);
    });
  });
}
