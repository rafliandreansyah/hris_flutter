import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';

class _FakeApiClient implements ApiClient {
  late final Dio _dio;
  String? lastGetPath;
  Map<String, dynamic>? lastGetQueryParams;
  dynamic mockGetData;
  DioException? getErrorToThrow;

  String? lastPostPath;
  dynamic lastPostData;
  dynamic mockPostData;
  DioException? postErrorToThrow;

  _FakeApiClient() {
    _dio = Dio(BaseOptions());
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          lastPostPath = options.path;
          lastPostData = options.data;
          if (postErrorToThrow != null) {
            handler.reject(postErrorToThrow!);
          } else {
            handler.resolve(
              Response(
                requestOptions: options,
                data: mockPostData ?? {'success': true},
                statusCode: 200,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Dio get dio => _dio;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastGetQueryParams = queryParameters;
    if (getErrorToThrow != null) throw getErrorToThrow!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockGetData as T,
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
    lastPostPath = path;
    lastPostData = data;
    if (postErrorToThrow != null) throw postErrorToThrow!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockPostData as T,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TrackingRemoteDataSourceImpl Tests', () {
    late _FakeApiClient fakeApiClient;
    late TrackingRemoteDataSourceImpl dataSource;

    setUp(() {
      fakeApiClient = _FakeApiClient();
      dataSource = TrackingRemoteDataSourceImpl(apiClient: fakeApiClient);
    });

    test('getTrackingConfig fetches and parses config model', () async {
      fakeApiClient.mockGetData = {
        'success': true,
        'data': {
          'hasAccess': true,
          'isTrackingEnabled': true,
          'attendance': {
            'enabled': true,
            'intervalMinutes': 5,
            'activeSessionId': 'att-123',
          },
          'activity': {
            'enabled': false,
            'intervalMinutes': 15,
          },
        },
      };

      final config = await dataSource.getTrackingConfig();

      expect(fakeApiClient.lastGetPath, equals(ApiEndpoints.trackingConfig));
      expect(config.hasAccess, isTrue);
      expect(config.isTrackingEnabled, isTrue);
      expect(config.attendance.enabled, isTrue);
      expect(config.attendance.intervalMinutes, equals(5));
      expect(config.attendance.activeSessionId, equals('att-123'));
      expect(config.activity.enabled, isFalse);
    });

    test('getTrackingConfig throws ApiException when payload is invalid', () async {
      fakeApiClient.mockGetData = {'success': true, 'data': 'invalid'};

      expect(
        () => dataSource.getTrackingConfig(),
        throwsA(isA<ApiException>()),
      );
    });

    test('uploadBatch posts tracking batch payload', () async {
      final payload = TrackingBatchPayload(
        sourceType: 'attendance',
        referenceId: 'att-100',
        locations: [
          TrackingLocationPoint(
            id: 'pt-1',
            latitude: -6.2,
            longitude: 106.8,
            accuracy: 10.0,
            recordedAt: DateTime.utc(2026, 10, 14, 8, 0, 0),
          ),
        ],
      );

      await dataSource.uploadBatch(payload);

      expect(fakeApiClient.lastPostPath, equals(ApiEndpoints.trackingBatch));
      expect(fakeApiClient.lastPostData['sourceType'], equals('attendance'));
      expect(fakeApiClient.lastPostData['referenceId'], equals('att-100'));
      expect((fakeApiClient.lastPostData['locations'] as List).length, equals(1));
    });

    test('uploadBatch throws SessionClosedException when response is 400 SESSION_CLOSED', () async {
      final requestOptions = RequestOptions(path: ApiEndpoints.trackingBatch);
      fakeApiClient.postErrorToThrow = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'code': 'SESSION_CLOSED',
            'message': 'Sesi presensi sudah berakhir',
          },
        ),
      );

      const payload = TrackingBatchPayload(
        sourceType: 'attendance',
        referenceId: 'att-100',
        locations: [],
      );

      expect(
        () => dataSource.uploadBatch(payload),
        throwsA(isA<SessionClosedException>().having(
          (e) => e.message,
          'message',
          contains('Sesi presensi sudah berakhir'),
        )),
      );
    });

    test('uploadBatch throws ApiException on generic DioException', () async {
      final requestOptions = RequestOptions(path: ApiEndpoints.trackingBatch);
      fakeApiClient.postErrorToThrow = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 500,
          data: {'message': 'Server error'},
        ),
      );

      const payload = TrackingBatchPayload(
        sourceType: 'activity',
        referenceId: 'act-100',
        locations: [],
      );

      await expectLater(
        dataSource.uploadBatch(payload),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Server error'),
        ),
      );
    });

    test('getTrackingLogs queries logs with parameters and parses list', () async {
      fakeApiClient.mockGetData = {
        'success': true,
        'data': [
          {
            'id': 'log-1',
            'employeeId': 'emp-1',
            'sourceType': 'attendance',
            'latitude': -6.2088,
            'longitude': 106.8456,
            'recordedAt': '2026-10-14T08:00:00Z',
          },
        ],
      };

      final logs = await dataSource.getTrackingLogs(
        sourceType: 'attendance',
        referenceId: 'att-100',
        employeeId: 'emp-1',
        limit: 50,
      );

      expect(fakeApiClient.lastGetPath, equals(ApiEndpoints.trackingLogs));
      expect(fakeApiClient.lastGetQueryParams?['sourceType'], equals('attendance'));
      expect(fakeApiClient.lastGetQueryParams?['referenceId'], equals('att-100'));
      expect(fakeApiClient.lastGetQueryParams?['employeeId'], equals('emp-1'));
      expect(fakeApiClient.lastGetQueryParams?['limit'], equals(50));
      expect(logs.length, equals(1));
      expect(logs.first.latitude, equals(-6.2088));
    });

    test('getTrackingLogs returns empty list when data is not a list', () async {
      fakeApiClient.mockGetData = {'success': true, 'data': null};

      final logs = await dataSource.getTrackingLogs(
        sourceType: 'attendance',
        referenceId: 'att-100',
      );

      expect(logs, isEmpty);
    });

    test('getLiveTracking sends filters and parses LiveTrackingResponse', () async {
      fakeApiClient.mockGetData = {
        'success': true,
        'data': {
          'summary': {
            'totalTracked': 1,
            'attendanceCount': 1,
            'activityCount': 0,
            'onlineCount': 1,
            'gpsOffCount': 0,
          },
          'employees': [
            {
              'employeeId': 'emp-1',
              'name': 'John Doe',
              'role': 'Staff',
              'department': 'IT',
              'status': 'online',
              'latitude': -6.2,
              'longitude': 106.8,
            },
          ],
        },
      };

      final response = await dataSource.getLiveTracking(
        companyId: 'comp-1',
        departmentId: 'dept-1',
        status: 'online',
        activeOnly: true,
        search: 'John',
      );

      expect(fakeApiClient.lastGetPath, equals(ApiEndpoints.trackingLive));
      expect(fakeApiClient.lastGetQueryParams?['companyId'], equals('comp-1'));
      expect(fakeApiClient.lastGetQueryParams?['departmentId'], equals('dept-1'));
      expect(fakeApiClient.lastGetQueryParams?['status'], equals('online'));
      expect(fakeApiClient.lastGetQueryParams?['activeOnly'], isTrue);
      expect(fakeApiClient.lastGetQueryParams?['search'], equals('John'));
      expect(response.summary.totalTracked, equals(1));
      expect(response.employees.length, equals(1));
      expect(response.employees.first.name, equals('John Doe'));
    });

    test('getLiveTracking returns empty model when data is not map', () async {
      fakeApiClient.mockGetData = {'success': true, 'data': null};

      final response = await dataSource.getLiveTracking();

      expect(response.summary.totalTracked, equals(0));
      expect(response.employees, isEmpty);
    });
  });
}
