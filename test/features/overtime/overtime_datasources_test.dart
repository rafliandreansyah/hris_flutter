import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:image_picker/image_picker.dart';

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
  group('OvertimeRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late OvertimeRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = OvertimeRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getOvertimeRequests sends query parameters and parses list response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'ot-1',
            'startOvertime': '2026-10-15T18:00:00Z',
            'endOvertime': '2026-10-15T21:00:00Z',
            'notes': 'Fixing critical issue',
            'status': 'REQUESTED',
          }
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      };

      final result = await dataSource.getOvertimeRequests(
        page: 1,
        size: 20,
        status: 'pending',
        search: 'Budi',
        approver: true,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.overtime));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(20));
      expect(mockApiClient.lastQueryParams?['approver'], isTrue);
      expect(mockApiClient.lastQueryParams?['status'], equals('requested'));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('ot-1'));
    });

    test('getOvertimeSchedule calls overtimeSchedule endpoint with dateTimeStart', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'isGenerated': false,
          'isDayOff': false,
          'workScheduleId': 'sched-1',
        },
      };

      final result = await dataSource.getOvertimeSchedule(dateTimeStart: '2026-10-15T17:00:00Z');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.overtimeSchedule));
      expect(mockApiClient.lastQueryParams?['dateTimeStart'], equals('2026-10-15T17:00:00Z'));
      expect(result.workScheduleId, equals('sched-1'));
    });

    test('getOvertimeDetail returns detail data from endpoint', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'ot-100',
          'startOvertime': '2026-10-15T18:00:00Z',
          'endOvertime': '2026-10-15T21:00:00Z',
          'notes': 'Overtime work',
          'status': 'APPROVED',
          'employee': {
            'id': 'emp-1',
            'firstName': 'Budi',
          },
        },
      };

      final result = await dataSource.getOvertimeDetail('ot-100');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.overtimeDetail('ot-100')));
      expect(result.id, equals('ot-100'));
      expect(result.status, equals('APPROVED'));
    });

    test('approveOvertime sends PATCH with payload', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.approveOvertime(
        id: 'ot-100',
        isApproved: true,
        approverNotes: 'Disetujui lembur 3 jam',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.overtimeApprove('ot-100')));
      expect(mockApiClient.lastData['isApproved'], isTrue);
      expect(mockApiClient.lastData['approverNotes'], equals('Disetujui lembur 3 jam'));
    });

    test('deleteOvertime sends DELETE request', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.deleteOvertime('ot-100');

      expect(mockApiClient.lastMethod, equals('DELETE'));
      expect(mockApiClient.lastPath, equals(ApiEndpoints.overtimeDetail('ot-100')));
    });

    test('createOvertimeRequest sends multipart POST and parses result', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_overtime.jpg')..writeAsBytesSync([1, 2, 3]);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Lembur berhasil diajukan',
        'data': {'id': 'ot-new-1'},
      };

      final result = await dataSource.createOvertimeRequest(
        startOvertime: '2026-10-15T18:00:00Z',
        endOvertime: '2026-10-15T21:00:00Z',
        notes: 'Pekerjaan akhir bulan',
        file: XFile(tempFile.path),
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.overtime));
      expect(result.id, equals('ot-new-1'));
      expect(result.success, isTrue);
    });
  });
}
