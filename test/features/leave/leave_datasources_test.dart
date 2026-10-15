import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/leave/data/datasources/leave_remote_datasource.dart';

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
  group('LeaveRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late LeaveRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = LeaveRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getLeaveRequests builds query parameters and parses list response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'leave-1',
            'leaveType': {'id': 'type-1', 'name': 'Cuti Tahunan'},
            'startDate': '2026-10-15',
            'endDate': '2026-10-17',
            'totalDays': 3,
            'reason': 'Acara keluarga',
            'status': 'REQUESTED',
          }
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      };

      final result = await dataSource.getLeaveRequests(
        page: 1,
        size: 20,
        status: 'pending',
        search: 'Budi',
        companyId: 'comp-1',
        approver: true,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.leaveRequest));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(20));
      expect(mockApiClient.lastQueryParams?['approver'], isTrue);
      expect(mockApiClient.lastQueryParams?['search'], equals('Budi'));
      expect(mockApiClient.lastQueryParams?['status'], equals('requested'));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('leave-1'));
    });

    test('getLeaveRequestDetail returns detail data from endpoint', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'leave-detail-1',
          'leaveType': {'id': 'type-1', 'name': 'Cuti Sakit'},
          'startDate': '2026-10-15',
          'endDate': '2026-10-16',
          'totalDays': 2,
          'reason': 'Demam tinggi',
          'status': 'APPROVED',
        },
      };

      final result = await dataSource.getLeaveRequestDetail('leave-detail-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.leaveRequestDetail('leave-detail-1')));
      expect(result.id, equals('leave-detail-1'));
      expect(result.totalDays, equals(2));
    });

    test('approveLeaveRequest sends PATCH with isApproved and approverNotes', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.approveLeaveRequest(
        'leave-1',
        isApproved: true,
        approverNotes: 'Disetujui silakan istirahat',
      );

      expect(mockApiClient.lastMethod, equals('PATCH'));
      expect(mockApiClient.lastPath, equals(ApiEndpoints.leaveRequestApprove('leave-1')));
      expect(mockApiClient.lastData['isApproved'], isTrue);
      expect(mockApiClient.lastData['approverNotes'], equals('Disetujui silakan istirahat'));
    });

    test('deleteLeaveRequest sends DELETE to endpoint', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.deleteLeaveRequest('leave-1');

      expect(mockApiClient.lastMethod, equals('DELETE'));
      expect(mockApiClient.lastPath, equals(ApiEndpoints.leaveRequestDetail('leave-1')));
    });

    test('getLeaveTypes returns parsed list of leave type options', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {'id': 'type-1', 'name': 'Cuti Tahunan', 'quota': 12},
          {'id': 'type-2', 'name': 'Cuti Sakit', 'quota': 14},
        ],
      };

      final result = await dataSource.getLeaveTypes();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.leaveTypes));
      expect(result.length, equals(2));
      expect(result.first.name, equals('Cuti Tahunan'));
    });

    test('createLeaveRequest sends multipart POST and parses result', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Pengajuan cuti berhasil diajukan',
        'data': {'id': 'leave-new-1'},
      };

      final result = await dataSource.createLeaveRequest(
        leaveTypeId: 'type-1',
        startDate: '2026-10-20',
        totalDays: 2,
        notes: 'Keperluan keluarga',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.leaveRequest));
      expect(result.id, equals('leave-new-1'));
      expect(result.message, equals('Pengajuan cuti berhasil diajukan'));
    });
  });
}
