import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/data/models/notification_settings_model.dart';
import 'package:hris_flutter/features/notification/data/repositories/notification_repository_impl.dart';

class _MockNotificationRemoteDataSource implements NotificationRemoteDataSource {
  int getUnreadCountCallCount = 0;
  int getNotificationsCallCount = 0;
  int markAllAsReadCallCount = 0;
  int markAsReadCallCount = 0;
  int getNotificationSettingsCallCount = 0;
  int updateNotificationSettingsCallCount = 0;

  dynamic mockUnreadCountResult;
  dynamic mockNotificationsResult;
  dynamic mockMarkReadAllResult;
  dynamic mockMarkReadResult;
  dynamic mockSettingsResult;
  dynamic mockUpdateSettingsResult;

  @override
  Future<NotificationUnreadCountResponse> getUnreadCount() async {
    getUnreadCountCallCount++;
    return mockUnreadCountResult as NotificationUnreadCountResponse;
  }

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    getNotificationsCallCount++;
    return mockNotificationsResult as NotificationListResponse;
  }

  @override
  Future<NotificationMarkReadAllResponse> markAllAsRead() async {
    markAllAsReadCallCount++;
    return mockMarkReadAllResult as NotificationMarkReadAllResponse;
  }

  @override
  Future<NotificationMarkReadResponse> markAsRead(String id) async {
    markAsReadCallCount++;
    return mockMarkReadResult as NotificationMarkReadResponse;
  }

  @override
  Future<NotificationSettingsResponse> getNotificationSettings() async {
    getNotificationSettingsCallCount++;
    return mockSettingsResult as NotificationSettingsResponse;
  }

  @override
  Future<NotificationSettingsResponse> updateNotificationSettings(
    Map<String, dynamic> body,
  ) async {
    updateNotificationSettingsCallCount++;
    return mockUpdateSettingsResult as NotificationSettingsResponse;
  }
}

void main() {
  group('NotificationRepositoryImpl Tests', () {
    late _MockNotificationRemoteDataSource mockRemoteDataSource;
    late NotificationRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockNotificationRemoteDataSource();
      repository = NotificationRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getUnreadCount delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockUnreadCountResult = NotificationUnreadCountResponse.fromJson(const {
        'success': true,
        'data': {'unreadCount': 3},
      });

      final result = await repository.getUnreadCount();

      expect(mockRemoteDataSource.getUnreadCountCallCount, equals(1));
      expect(result.unreadCount, equals(3));
    });

    test('getNotifications delegates to remote data source', () async {
      mockRemoteDataSource.mockNotificationsResult = NotificationListResponse.fromJson(const {
        'success': true,
        'data': [
          {
            'id': 'notif-1',
            'title': 'Pengumuman Baru',
            'message': 'Libur bersama',
            'isRead': false,
            'createdAt': '2026-10-15T08:00:00Z',
          }
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getNotifications(page: 1, limit: 20);

      expect(mockRemoteDataSource.getNotificationsCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.title, equals('Pengumuman Baru'));
    });

    test('markAllAsRead delegates to remote data source', () async {
      mockRemoteDataSource.mockMarkReadAllResult = NotificationMarkReadAllResponse.fromJson(const {
        'success': true,
        'message': 'Semua telah dibaca',
      });

      final result = await repository.markAllAsRead();

      expect(mockRemoteDataSource.markAllAsReadCallCount, equals(1));
      expect(result.success, isTrue);
    });

    test('markAsRead delegates to remote data source', () async {
      mockRemoteDataSource.mockMarkReadResult = NotificationMarkReadResponse.fromJson(const {
        'success': true,
        'message': 'Dibaca',
      });

      final result = await repository.markAsRead('notif-1');

      expect(mockRemoteDataSource.markAsReadCallCount, equals(1));
      expect(result.success, isTrue);
    });

    test('getNotificationSettings delegates to remote data source', () async {
      mockRemoteDataSource.mockSettingsResult = NotificationSettingsResponse.fromJson(const {
        'success': true,
        'data': {
          'id': 'ns-1',
          'employeeId': 'emp-1',
          'pushLeave': true,
        },
      });

      final result = await repository.getNotificationSettings();

      expect(mockRemoteDataSource.getNotificationSettingsCallCount, equals(1));
      expect(result.data?.pushLeave, isTrue);
    });

    test('updateNotificationSettings delegates to remote data source', () async {
      mockRemoteDataSource.mockUpdateSettingsResult = NotificationSettingsResponse.fromJson(const {
        'success': true,
        'data': {
          'id': 'ns-1',
          'employeeId': 'emp-1',
          'pushLeave': false,
        },
      });

      final result = await repository.updateNotificationSettings({'pushLeave': false});

      expect(mockRemoteDataSource.updateNotificationSettingsCallCount, equals(1));
      expect(result.data?.pushLeave, isFalse);
    });
  });
}
