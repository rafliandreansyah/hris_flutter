import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/datasources/activity_remote_datasource.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ActivityRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late ActivityRemoteDataSourceImpl dataSource;
    late Directory tempDir;
    late File testFile;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = ActivityRemoteDataSourceImpl(apiClient: mockApiClient);
      tempDir = Directory.systemTemp.createTempSync('activity_test_');
      testFile = File('${tempDir.path}/test_image.jpg')..writeAsStringSync('dummy content');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getActivities builds query params and parses ActivityListResponse', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'act-1',
            'employeeId': 'emp-1',
            'activityTypeId': 'type-1',
            'locationName': 'Site A',
            'description': 'Inspection',
            'status': 'ongoing',
            'createdAt': '2026-10-15T08:00:00Z',
          }
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getActivities(
        page: 1,
        size: 10,
        companyId: 'comp-1',
        departmentId: 'dept-1',
        positionId: 'pos-1',
        search: 'Inspection',
        status: 'ongoing',
        startDate: '2026-10-01',
        endDate: '2026-10-15',
        approver: true,
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activity));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(10));
      expect(mockApiClient.lastQueryParams?['companyId'], equals('comp-1'));
      expect(mockApiClient.lastQueryParams?['departmentId'], equals('dept-1'));
      expect(mockApiClient.lastQueryParams?['positionId'], equals('pos-1'));
      expect(mockApiClient.lastQueryParams?['search'], equals('Inspection'));
      expect(mockApiClient.lastQueryParams?['status'], equals('ongoing'));
      expect(mockApiClient.lastQueryParams?['startDate'], equals('2026-10-01'));
      expect(mockApiClient.lastQueryParams?['endDate'], equals('2026-10-15'));
      expect(mockApiClient.lastQueryParams?['approver'], isTrue);
      expect(response.success, isTrue);
      expect(response.data.length, equals(1));
      expect(response.data.first.id, equals('act-1'));
    });

    test('getActivityDetail fetches detail by ID', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'act-1',
          'employeeId': 'emp-1',
          'activityTypeId': 'type-1',
          'locationName': 'Site A',
          'description': 'Inspection Detail',
          'status': 'ongoing',
          'createdAt': '2026-10-15T08:00:00Z',
        },
      };

      final response = await dataSource.getActivityDetail('act-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activityDetail('act-1')));
      expect(response.success, isTrue);
      expect(response.data.id, equals('act-1'));
      expect(response.data.locationName, equals('Site A'));
    });

    test('finishActivity sends patch with notes and optional file', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Aktivitas berhasil diselesaikan',
      };

      final response = await dataSource.finishActivity(
        id: 'act-1',
        notes: 'Pekerjaan rampung',
        file: XFile(testFile.path),
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activityFinish('act-1')));
      expect(mockApiClient.lastData, isA<FormData>());
      final formData = mockApiClient.lastData as FormData;
      expect(formData.fields.any((f) => f.key == 'notes' && f.value == 'Pekerjaan rampung'), isTrue);
      expect(formData.files.any((f) => f.key == 'file'), isTrue);
      expect(response.success, isTrue);
    });

    test('cancelActivity sends patch with cancellation notes', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Aktivitas dibatalkan',
      };

      final response = await dataSource.cancelActivity(
        id: 'act-1',
        notes: 'Hujan lebat',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activityCancel('act-1')));
      expect(mockApiClient.lastData, isA<FormData>());
      final formData = mockApiClient.lastData as FormData;
      expect(formData.fields.any((f) => f.key == 'notes' && f.value == 'Hujan lebat'), isTrue);
      expect(response.success, isTrue);
    });

    test('getActivityTypes fetches types from endpoint', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {'id': 'type-1', 'name': 'Inspeksi Lapangan'},
          {'id': 'type-2', 'name': 'Meeting Klien'},
        ],
      };

      final response = await dataSource.getActivityTypes();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activityTypes));
      expect(response.success, isTrue);
      expect(response.data.length, equals(2));
      expect(response.data.first.name, equals('Inspeksi Lapangan'));
    });

    test('createActivity sends post with coordinates and location', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Aktivitas berhasil dibuat',
        'data': {
          'id': 'new-act-1',
        },
      };

      final response = await dataSource.createActivity(
        activityTypeId: 'type-1',
        latitude: -6.2,
        longitude: 106.8,
        locationName: 'SCBD Tower',
        locationAddress: 'Jl. Sudirman No. 1',
        description: 'Audit mingguan',
        file: XFile(testFile.path),
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activity));
      expect(mockApiClient.lastData, isA<FormData>());
      final formData = mockApiClient.lastData as FormData;
      expect(formData.fields.any((f) => f.key == 'activityTypeId' && f.value == 'type-1'), isTrue);
      expect(formData.fields.any((f) => f.key == 'locationName' && f.value == 'SCBD Tower'), isTrue);
      expect(response.success, isTrue);
    });

    test('createPlanActivity sends post with employeeId and plan time', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Rencana aktivitas berhasil dibuat',
        'data': {
          'id': 'plan-act-1',
        },
      };

      final response = await dataSource.createPlanActivity(
        employeeId: 'emp-2',
        activityTypeId: 'type-2',
        startTime: '2026-10-16 09:00:00',
        locationName: 'Kantor Cabang',
        locationAddress: 'Jl. Gatot Subroto',
        description: 'Instalasi server',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activityPlan));
      expect(mockApiClient.lastData, isA<FormData>());
      final formData = mockApiClient.lastData as FormData;
      expect(formData.fields.any((f) => f.key == 'employeeId' && f.value == 'emp-2'), isTrue);
      expect(response.success, isTrue);
    });

    test('startActivity sends patch with start coordinates and address', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Aktivitas berhasil dimulai',
      };

      final response = await dataSource.startActivity(
        id: 'plan-act-1',
        latitude: -6.21,
        longitude: 106.81,
        locationAddress: 'Jl. Gatot Subroto No. 5',
        file: XFile(testFile.path),
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.activityStart('plan-act-1')));
      expect(mockApiClient.lastData, isA<FormData>());
      final formData = mockApiClient.lastData as FormData;
      expect(formData.fields.any((f) => f.key == 'locationAddress' && f.value == 'Jl. Gatot Subroto No. 5'), isTrue);
      expect(response.success, isTrue);
    });

    test('throws ApiException when API returns non-map response', () async {
      mockApiClient.mockResponseData = 'Unexpected Error';

      expect(
        () => dataSource.getActivities(page: 1, size: 10),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => dataSource.getActivityDetail('act-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
