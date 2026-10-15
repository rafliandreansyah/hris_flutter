import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/datasources/payroll_remote_datasource.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;
  DioException? dioErrorToThrow;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'GET';
    lastQueryParams = queryParameters;
    if (dioErrorToThrow != null) {
      throw dioErrorToThrow!;
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockResponseData as T,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PayrollRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late PayrollRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = PayrollRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getMyPayslips sends query params and parses response', () async {
      mockApiClient.mockResponseData = {
        'data': [
          {
            'id': 'slip-01',
            'employeeId': 'emp-01',
            'employee': {
              'id': 'emp-01',
              'firstName': 'John',
              'lastName': 'Doe',
              'employeeNumber': 'EMP-001',
            },
            'period': {
              'id': 'prd-01',
              'month': 10,
              'year': 2026,
              'label': 'Oktober 2026',
              'startDate': '2026-09-26',
              'endDate': '2026-10-25',
              'payDate': '2026-10-25',
              'status': 'open',
            },
            'grossSalary': 15000000.0,
            'deductions': 1500000.0,
            'netSalary': 13500000.0,
            'status': 'paid',
            'createdAt': '2026-10-25T00:00:00.000Z',
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getMyPayslips(
        page: 1,
        size: 10,
        year: 2026,
        month: 10,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.myPayslips));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(10));
      expect(mockApiClient.lastQueryParams?['year'], equals(2026));
      expect(mockApiClient.lastQueryParams?['month'], equals(10));
      expect(response.data.length, equals(1));
      expect(response.data.first.id, equals('slip-01'));
      expect(response.data.first.netSalary, equals(13500000.0));
    });

    test('getPayrolls sends filters and parses response', () async {
      mockApiClient.mockResponseData = {
        'data': [
          {
            'id': 'slip-02',
            'employeeId': 'emp-02',
            'employee': {
              'id': 'emp-02',
              'firstName': 'Jane',
              'lastName': 'Smith',
              'employeeNumber': 'EMP-002',
            },
            'period': {
              'id': 'prd-01',
              'month': 10,
              'year': 2026,
              'label': 'Oktober 2026',
              'startDate': '2026-09-26',
              'endDate': '2026-10-25',
              'payDate': '2026-10-25',
              'status': 'open',
            },
            'grossSalary': 10000000.0,
            'deductions': 1000000.0,
            'netSalary': 9000000.0,
            'status': 'paid',
            'createdAt': '2026-10-25T00:00:00.000Z',
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getPayrolls(
        page: 1,
        size: 10,
        employeeId: 'emp-02',
        companyId: 'comp-1',
        departmentId: 'dept-1',
        payrollPeriodId: 'prd-01',
        year: 2026,
        month: 10,
        status: 'paid',
        search: 'Jane',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.payrolls));
      expect(mockApiClient.lastQueryParams?['employeeId'], equals('emp-02'));
      expect(mockApiClient.lastQueryParams?['companyId'], equals('comp-1'));
      expect(mockApiClient.lastQueryParams?['departmentId'], equals('dept-1'));
      expect(mockApiClient.lastQueryParams?['payrollPeriodId'], equals('prd-01'));
      expect(mockApiClient.lastQueryParams?['status'], equals('paid'));
      expect(mockApiClient.lastQueryParams?['search'], equals('Jane'));
      expect(response.data.length, equals(1));
      expect(response.data.first.id, equals('slip-02'));
    });

    test('getPayrollEmployees sends params and parses response', () async {
      mockApiClient.mockResponseData = {
        'data': [
          {
            'id': 'emp-101',
            'name': 'Ahmad Dahlan',
            'firstName': 'Ahmad',
            'lastName': 'Dahlan',
            'employeeNumber': 'EMP-101',
            'email': 'ahmad@example.com',
            'phone': '08123456789',
            'status': true,
            'company': {'id': 'comp-1', 'name': 'PT Muratech'},
            'department': {'id': 'dept-1', 'name': 'IT Engineering'},
            'position': {'id': 'pos-1', 'name': 'Tech Lead'},
          }
        ],
        'meta': {'page': 1, 'size': 20, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getPayrollEmployees(
        page: 1,
        size: 20,
        search: 'Ahmad',
        companyId: 'comp-1',
        departmentId: 'dept-1',
        status: 'active',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.payrollEmployees));
      expect(mockApiClient.lastQueryParams?['search'], equals('Ahmad'));
      expect(mockApiClient.lastQueryParams?['companyId'], equals('comp-1'));
      expect(mockApiClient.lastQueryParams?['departmentId'], equals('dept-1'));
      expect(mockApiClient.lastQueryParams?['status'], equals('active'));
      expect(response.data.length, equals(1));
      expect(response.data.first.displayName, equals('Ahmad Dahlan'));
    });

    test('getPayrollPeriods fetches periods list', () async {
      mockApiClient.mockResponseData = {
        'data': [
          {
            'id': 'prd-01',
            'month': 10,
            'year': 2026,
            'label': 'Oktober 2026',
            'startDate': '2026-09-26',
            'endDate': '2026-10-25',
            'payDate': '2026-10-25',
            'status': 'open',
          }
        ]
      };

      final periods = await dataSource.getPayrollPeriods(
        companyId: 'comp-1',
        status: 'open',
        year: 2026,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.payrollPeriods));
      expect(mockApiClient.lastQueryParams?['companyId'], equals('comp-1'));
      expect(mockApiClient.lastQueryParams?['status'], equals('open'));
      expect(mockApiClient.lastQueryParams?['year'], equals(2026));
      expect(periods.length, equals(1));
      expect(periods.first.id, equals('prd-01'));
      expect(periods.first.label, equals('Oktober 2026'));
    });

    test('getPayrollDetail fetches slip detail by id', () async {
      mockApiClient.mockResponseData = {
        'data': {
          'id': 'slip-01',
          'company': {
            'id': 'comp-1',
            'name': 'PT Muratech',
          },
          'employee': {
            'id': 'emp-01',
            'name': 'John Doe',
          },
          'period': {
            'id': 'prd-01',
            'name': 'Oktober 2026',
            'month': 10,
            'year': 2026,
            'startDate': '2026-09-26',
            'endDate': '2026-10-25',
            'paymentDate': '2026-10-25',
          },
          'earnings': [],
          'deductionsList': [],
          'companyContributions': [],
          'grossSalary': 15000000.0,
          'deductions': 1500000.0,
          'netSalary': 13500000.0,
          'status': 'paid',
        }
      };

      final detail = await dataSource.getPayrollDetail('slip-01');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.payrollDetail('slip-01')));
      expect(detail.id, equals('slip-01'));
      expect(detail.netSalary, equals(13500000.0));
      expect(detail.status, equals('paid'));
    });

    test('downloadPayslip fetches download url with force parameter', () async {
      mockApiClient.mockResponseData = {
        'data': {
          'payrollId': 'slip-01',
          'payslipUrl': 'https://storage.googleapis.com/test.pdf',
          'isNewlyGenerated': true,
        }
      };

      final download = await dataSource.downloadPayslip('slip-01', force: true);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.payrollDownload('slip-01')));
      expect(mockApiClient.lastQueryParams?['force'], isTrue);
      expect(download.payrollId, equals('slip-01'));
      expect(download.payslipUrl, equals('https://storage.googleapis.com/test.pdf'));
    });

    test('throws ApiException on DioException', () async {
      mockApiClient.dioErrorToThrow = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: ApiEndpoints.myPayslips),
        response: Response(
          requestOptions: RequestOptions(path: ApiEndpoints.myPayslips),
          statusCode: 500,
          data: {'message': 'Server Error'},
        ),
      );

      await expectLater(
        dataSource.getMyPayslips(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Server Error'),
        ),
      );
    });
  });
}
