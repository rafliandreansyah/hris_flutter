import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_request.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;
  DioException? dioErrorToThrow;
  ApiException? apiErrorToThrow;

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
    if (apiErrorToThrow != null) {
      throw apiErrorToThrow!;
    }
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
    if (apiErrorToThrow != null) {
      throw apiErrorToThrow!;
    }
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
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'PUT';
    lastData = data;
    lastQueryParams = queryParameters;
    if (apiErrorToThrow != null) {
      throw apiErrorToThrow!;
    }
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
  group('AttendanceRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late AttendanceRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = AttendanceRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('fetchAttendanceInfo calls correct endpoint and returns map data', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'todayAttendance': {'status': 'PRESENT'},
        },
      };

      final result = await dataSource.fetchAttendanceInfo();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeAttendanceInfo));
      expect(result['success'], isTrue);
      expect((result['data'] as Map)['todayAttendance']['status'], equals('PRESENT'));
    });

    test('fetchDashboardAttendance calls employeeDashboard endpoint', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {'timeServer': '2026-10-13T08:00:00Z'},
      };

      final result = await dataSource.fetchDashboardAttendance();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeDashboard));
      expect(result['success'], isTrue);
    });




    test('getAttendanceLogs passes query parameters and deserializes response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {
            'id': 'att-1',
            'date': '2026-10-13',
            'status': 'PRESENT',
            'timeIn': '08:00',
            'timeOut': '17:00',
          }
        ],
        'pagination': {'total': 1, 'page': 1, 'size': 20},
      };

      final result = await dataSource.getAttendanceLogs(
        employeeId: 'emp-123',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        status: 'PRESENT',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.attendances));
      expect(mockApiClient.lastQueryParams?['employeeId'], equals('emp-123'));
      expect(mockApiClient.lastQueryParams?['startDate'], equals('2026-10-01'));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('att-1'));
    });

    test('getAttendanceEmployees parses employee directory items', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {
            'id': 'emp-1',
            'firstName': 'Budi',
            'lastName': 'Santoso',
            'email': 'budi@example.com',
          }
        ],
      };

      final result = await dataSource.getAttendanceEmployees();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.attendancesEmployees));
      expect(result.length, equals(1));
      expect(result.first.id, equals('emp-1'));
    });

    test('getAttendanceEmployees meneruskan ApiException 403 dari ApiClient apa adanya', () async {
      // ApiClient asli sudah mengubah DioException menjadi ApiException,
      // jadi pesan dari backend tidak boleh diubah/diganti datasource.
      mockApiClient.apiErrorToThrow = const ApiException(
        message: 'Anda tidak memiliki akses ke data tim',
        statusCode: 403,
      );

      await expectLater(
        dataSource.getAttendanceEmployees(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Anda tidak memiliki akses ke data tim'),
        ),
      );
    });

    test('getAttendanceEmployees memetakan DioException 403 ke pesan akses', () async {
      mockApiClient.dioErrorToThrow = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: ApiEndpoints.attendancesEmployees),
        response: Response(
          requestOptions: RequestOptions(path: ApiEndpoints.attendancesEmployees),
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      await expectLater(
        dataSource.getAttendanceEmployees(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Tidak ada hak akses'),
        ),
      );
    });


    test('getAttendanceDetail parses attendance detail model', () async {
      mockApiClient.mockResponseData = {
        'data': {
          'id': 'att-detail-1',
          'date': '2026-10-13',
          'timeIn': '08:00',
          'timeOut': '17:00',
          'status': 'PRESENT',
        },
      };

      final result = await dataSource.getAttendanceDetail('att-detail-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.attendanceDetail('att-detail-1')));
      expect(result.id, equals('att-detail-1'));
    });

    test('setDefaultWorkLocation sends PUT request with workLocationId', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Lokasi kantor default berhasil disimpan',
      };

      final result = await dataSource.setDefaultWorkLocation(
        workLocationId: 'loc-1',
        employeeWorkLocationId: 'ewl-1',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeDefaultWorkLocation));
      expect(mockApiClient.lastData['workLocationId'], equals('loc-1'));
      expect(mockApiClient.lastData['employeeWorkLocationId'], equals('ewl-1'));
      expect(result['success'], isTrue);
    });

    test('recordAttendance posts FormData and parses response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Absensi berhasil direkam',
        'data': {
          'id': 'att-new-1',
          'status': 'PRESENT',
        },
      };

      const req = CreateAttendanceRequest(
        workLocationId: 'loc-1',
        attendanceMethod: 'photo',
        latitude: -6.2088,
        longitude: 106.8456,
        attendanceType: 'in',
      );

      final result = await dataSource.recordAttendance(req);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.attendances));
      expect(result.success, isTrue);
      expect(result.message, equals('Absensi berhasil direkam'));
    });
  });
}
