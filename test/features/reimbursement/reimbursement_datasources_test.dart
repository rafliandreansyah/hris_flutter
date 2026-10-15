import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/reimbursement/data/datasources/reimbursement_remote_datasource.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  dynamic lastData;
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
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'POST';
    lastData = data;
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
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'PATCH';
    lastData = data;
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
  group('ReimbursementRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late ReimbursementRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = ReimbursementRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getExpensesFeed builds query parameters and parses feed response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {
            'id': 'exp-1',
            'referenceNumber': 'CLM-001',
            'expenseType': 'reimbursement',
            'title': 'Bensin operasional',
            'requestedAmount': 150000.0,
            'status': 'requested',
            'createdAt': '2026-10-15T08:00:00Z',
            'employee': {
              'id': 'emp-1',
              'firstName': 'Budi',
              'email': 'budi@example.com',
            },
          }
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPages': 1},
      };

      final result = await dataSource.getExpensesFeed(
        page: 1,
        size: 10,
        type: 'reimbursement',
        status: 'requested',
        search: 'Bensin',
        approver: false,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.expensesFeed));
      expect(mockApiClient.lastQueryParams?['page'], equals('1'));
      expect(mockApiClient.lastQueryParams?['size'], equals('10'));
      expect(mockApiClient.lastQueryParams?['type'], equals('reimbursement'));
      expect(result.items.length, equals(1));
      expect(result.items.first.referenceNumber, equals('CLM-001'));
    });

    test('getCategories parses category list', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {'id': 'cat-1', 'name': 'Transportasi', 'code': 'TRN'},
          {'id': 'cat-2', 'name': 'Konsumsi', 'code': 'MEAL'},
        ],
      };

      final result = await dataSource.getCategories();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.reimbursementCategories));
      expect(result.length, equals(2));
      expect(result.first.name, equals('Transportasi'));
    });

    test('getReimbursementDetail parses detail model', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'reimb-1',
          'claimNumber': 'CLM-001',
          'type': 'transport',
          'title': 'Transportasi Kunjungan',
          'totalRequestedAmount': 200000.0,
          'status': 'requested',
          'createdAt': '2026-10-15T08:00:00Z',
          'employee': {
            'id': 'emp-1',
            'firstName': 'Budi',
            'email': 'budi@example.com',
          },
        },
      };

      final result = await dataSource.getReimbursementDetail('reimb-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.reimbursementDetail('reimb-1')));
      expect(result.id, equals('reimb-1'));
      expect(result.title, equals('Transportasi Kunjungan'));
    });

    test('createReimbursement sends multipart form and returns claimNumber', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'reimb-new-1',
          'claimNumber': 'CLM-2026-001',
        },
      };

      final result = await dataSource.createReimbursement(
        title: 'Bensin Dinas',
        type: 'transport',
        items: [
          {'categoryId': 'cat-1', 'amount': 150000, 'description': 'Bensin'}
        ],
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.reimbursements));
      expect(result, equals('CLM-2026-001'));
    });

    test('approveReimbursement sends PATCH with isApproved and notes', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.approveReimbursement(
        id: 'reimb-1',
        isApproved: true,
        approverNotes: 'Klaim disetujui',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.reimbursementApprove('reimb-1')));
      expect(mockApiClient.lastData['isApproved'], isTrue);
      expect(mockApiClient.lastData['approverNotes'], equals('Klaim disetujui'));
    });

    test('getCashAdvanceDetail parses cash advance detail', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'ca-1',
          'advanceNumber': 'CA-001',
          'title': 'Kasbon Dinas Luar',
          'purpose': 'Perjalanan dinas ke Surabaya',
          'requestedAmount': 1500000.0,
          'status': 'requested',
          'createdAt': '2026-10-15T08:00:00Z',
          'employee': {
            'id': 'emp-1',
            'firstName': 'Budi',
            'email': 'budi@example.com',
          },
        },
      };

      final result = await dataSource.getCashAdvanceDetail('ca-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.cashAdvanceDetail('ca-1')));
      expect(result.id, equals('ca-1'));
      expect(result.advanceNumber, equals('CA-001'));
    });

    test('createCashAdvance sends POST and returns advance number', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'ca-new-1',
          'advanceNumber': 'CA-2026-001',
        },
      };

      final result = await dataSource.createCashAdvance(
        title: 'Kasbon Dinas',
        purpose: 'Biaya hotel dan tiket',
        requestedAmount: 2000000.0,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.cashAdvances));
      expect(result, equals('CA-2026-001'));
    });

    test('approveCashAdvance sends PATCH with decision and approved amount', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.approveCashAdvance(
        id: 'ca-1',
        isApproved: true,
        approvedAmount: 1800000.0,
        approverNotes: 'Disetujui sebagian',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.cashAdvanceApprove('ca-1')));
      expect(mockApiClient.lastData['isApproved'], isTrue);
      expect(mockApiClient.lastData['approvedAmount'], equals(1800000.0));
    });

    test('disburseReimbursement sends PATCH with disbursement method and details', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.disburseReimbursement(
        id: 'reimb-1',
        disbursementMethod: 'bank_transfer',
        paymentReference: 'TRX-12345',
        bankName: 'BCA',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.reimbursementDisburse('reimb-1')));
    });

    test('refundCashAdvance sends POST with refund amount and method', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.refundCashAdvance(
        id: 'ca-1',
        amount: 200000.0,
        method: 'transfer',
        notes: 'Sisa uang bensin',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.cashAdvanceRefund('ca-1')));
    });
  });
}
