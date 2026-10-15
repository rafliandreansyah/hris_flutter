import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/datasources/notification_remote_datasource.dart';

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
  group('NotificationRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late NotificationRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = NotificationRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getUnreadCount parses unread count response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': {'unreadCount': 5},
      };

      final response = await dataSource.getUnreadCount();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.notificationsUnreadCount));
      expect(response.unreadCount, equals(5));
    });

    test('getNotifications sends page/limit and parses notifications list', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'notif-1',
            'title': 'Cuti Disetujui',
            'message': 'Pengajuan cuti telah disetujui',
            'isRead': false,
            'createdAt': '2026-10-15T08:00:00Z',
          }
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getNotifications(page: 1, limit: 20);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.notifications));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['limit'], equals(20));
      expect(response.data.length, equals(1));
      expect(response.data.first.title, equals('Cuti Disetujui'));
    });

    test('markAllAsRead sends PATCH to notificationsReadAll', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Semua notifikasi ditandai dibaca',
      };

      final response = await dataSource.markAllAsRead();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.notificationsReadAll));
      expect(response.success, isTrue);
    });

    test('markAsRead sends PATCH to notificationRead endpoint', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Notifikasi ditandai dibaca',
      };

      final response = await dataSource.markAsRead('notif-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.notificationRead('notif-1')));
      expect(response.success, isTrue);
    });

    test('getNotificationSettings parses settings model', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'ns-1',
          'employeeId': 'emp-1',
          'pushAttendanceRequest': true,
          'pushLeave': true,
          'pushOvertime': true,
          'pushPayroll': true,
          'pushAnnouncement': true,
          'pushWarningLetter': true,
          'pushReimbursement': true,
          'pushResignation': true,
          'pushAsset': true,
          'pushActivity': true,
        },
      };

      final response = await dataSource.getNotificationSettings();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeNotificationSettings));
      expect(response.success, isTrue);
      expect(response.data?.pushLeave, isTrue);
    });

    test('updateNotificationSettings sends PUT with body and returns settings', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'ns-1',
          'employeeId': 'emp-1',
          'pushLeave': false,
        },
      };

      final response = await dataSource.updateNotificationSettings({'pushLeave': false});

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeNotificationSettings));
      expect(mockApiClient.lastData['pushLeave'], isFalse);
      expect(response.success, isTrue);
    });

    test('throws ApiException on invalid format or server error', () async {
      mockApiClient.mockResponseData = 'non-map';

      expect(() => dataSource.getUnreadCount(), throwsA(isA<ApiException>()));
      expect(() => dataSource.getNotifications(), throwsA(isA<ApiException>()));
      expect(() => dataSource.markAllAsRead(), throwsA(isA<ApiException>()));
      expect(() => dataSource.markAsRead('notif-1'), throwsA(isA<ApiException>()));
      expect(() => dataSource.getNotificationSettings(), throwsA(isA<ApiException>()));
    });
  });
}
