import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/dashboard/data/datasources/dashboard_remote_datasource.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;
  bool shouldThrow = false;
  ApiException? errorToThrow;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (shouldThrow) {
      throw errorToThrow ??
          const ApiException(message: 'Request failed', statusCode: 500);
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
  group('DashboardRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late DashboardRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = DashboardRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getEmployeeDashboard calls correct endpoint and deserializes response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Dashboard loaded',
        'data': {
          'id': 'emp-101',
          'firstName': 'Budi',
          'lastName': 'Santoso',
          'email': 'budi@example.com',
          'timeServer': '2026-09-06T08:00:00.000Z',
          'employeeDevice': {
            'id': 'dev-1',
            'deviceId': 'pixel-9-pro',
          },
          'latestAnnouncement': [],
        },
      };

      final result = await dataSource.getEmployeeDashboard();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeDashboard));
      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.firstName, equals('Budi'));
      expect(result.data!.employeeDevice?.deviceId, equals('pixel-9-pro'));
    });

    test('getEmployeeDashboard propagates ApiException when ApiClient throws', () async {
      mockApiClient.shouldThrow = true;
      mockApiClient.errorToThrow =
          const ApiException(message: 'Timeout connecting to server', statusCode: 408);

      expect(
        () => dataSource.getEmployeeDashboard(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Timeout connecting to server')
              .having((e) => e.statusCode, 'statusCode', 408),
        ),
      );
      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeDashboard));
    });

    test('getAuthMenus calls correct endpoint and deserializes menus list', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Menus retrieved',
        'data': [
          {
            'id': 'menu-1',
            'name': 'Pegawai',
            'code': 'employee',
          },
          {
            'id': 'menu-2',
            'name': 'Presensi',
            'code': 'attendance',
          },
        ],
      };

      final result = await dataSource.getAuthMenus();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.authMenus));
      expect(result.success, isTrue);
      expect(result.data.length, equals(2));
      expect(result.data.first.code, equals('employee'));
      expect(result.data.last.code, equals('attendance'));
    });

    test('getAuthMenus propagates ApiException when ApiClient throws', () async {
      mockApiClient.shouldThrow = true;
      mockApiClient.errorToThrow =
          const ApiException(message: 'Unauthorized access', statusCode: 401);

      expect(
        () => dataSource.getAuthMenus(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Unauthorized access')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(mockApiClient.lastPath, equals(ApiEndpoints.authMenus));
    });
  });
}
