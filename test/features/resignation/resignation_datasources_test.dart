import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/resignation/data/datasources/resignation_remote_datasource.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';

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
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'DELETE';
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
  group('ResignationRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late ResignationRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = ResignationRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getMyResignationStatus parses my resignation status response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'hasActiveResignation': true,
          'daysRemaining': 20,
          'canCancel': true,
          'resignation': {
            'id': 'res-01',
            'companyId': 'comp-1',
            'employeeId': 'emp-1',
            'status': 'submitted',
          },
        },
      };

      final status = await dataSource.getMyResignationStatus();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.myResignationStatus));
      expect(status.hasActiveResignation, isTrue);
      expect(status.daysRemaining, equals(20));
      expect(status.canCancel, isTrue);
      expect(status.resignation?.id, equals('res-01'));
    });

    test('getSubordinateResignations sends query params and parses response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'res-sub-1',
            'companyId': 'comp-1',
            'employeeId': 'emp-2',
            'status': 'submitted',
            'employee': {
              'id': 'emp-2',
              'name': 'Budi',
              'email': 'budi@example.com',
            },
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getSubordinateResignations(
        status: 'submitted',
        page: 1,
        size: 10,
        search: 'Budi',
        companyId: 'comp-1',
        departmentId: 'dept-1',
        positionId: 'pos-1',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.subordinateResignations));
      expect(mockApiClient.lastQueryParams?['status'], equals('submitted'));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(10));
      expect(mockApiClient.lastQueryParams?['search'], equals('Budi'));
      expect(mockApiClient.lastQueryParams?['companyId'], equals('comp-1'));
      expect(mockApiClient.lastQueryParams?['departmentId'], equals('dept-1'));
      expect(mockApiClient.lastQueryParams?['positionId'], equals('pos-1'));
      expect(mockApiClient.lastQueryParams?['startDate'], equals('2026-10-01'));
      expect(mockApiClient.lastQueryParams?['endDate'], equals('2026-10-31'));
      expect(response.data.length, equals(1));
      expect(response.data.first.id, equals('res-sub-1'));
    });

    test('cancelMyResignation sends DELETE to /resignations/my', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Pengajuan dibatalkan',
      };

      await dataSource.cancelMyResignation();

      expect(mockApiClient.lastPath, equals('/resignations/my'));
    });

    test('cancelMyResignation throws ApiException when success is false', () async {
      mockApiClient.mockResponseData = {
        'success': false,
        'message': 'Gagal membatalkan',
      };

      expect(
        () => dataSource.cancelMyResignation(),
        throwsA(isA<ApiException>()),
      );
    });


    test('getInitialFormData parses form metadata', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'companyPolicy': {
            'isNoticePeriodRequired': true,
            'defaultNoticePeriodDays': 30,
          },
          'employee': {
            'id': 'emp-1',
            'name': 'Budi',
          },
          'minSuggestedDate': '2026-11-15',
          'colleagues': [],
        },
      };

      final form = await dataSource.getInitialFormData();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.resignationInitialForm));
      expect(form.minSuggestedDate, equals('2026-11-15'));
      expect(form.companyPolicy.defaultNoticePeriodDays, equals(30));
    });

    test('submitResignation sends POST with FormData to resignations endpoint', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Pengajuan resign berhasil dikirim',
      };

      const request = SubmitResignationRequestModel(
        effectiveDate: '2026-11-30',
        reasonCategory: 'PERSONAL',
        reasonNotes: 'Alasan keluarga',
      );

      await dataSource.submitResignation(request);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.resignations));
      expect(mockApiClient.lastData, isA<FormData>());
    });

    test('submitResignation throws ApiException when success is false', () async {
      mockApiClient.mockResponseData = {
        'success': false,
        'message': 'Pengajuan ditolak server',
      };

      const request = SubmitResignationRequestModel(
        effectiveDate: '2026-11-30',
        reasonCategory: 'PERSONAL',
        reasonNotes: 'Alasan keluarga',
      );

      expect(
        () => dataSource.submitResignation(request),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException on invalid payload structure', () async {
      mockApiClient.mockResponseData = 'non-map string';

      expect(
        () => dataSource.getMyResignationStatus(),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => dataSource.getSubordinateResignations(),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => dataSource.getInitialFormData(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
