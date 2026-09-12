import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';

void main() {
  group('NotificationItemModel Tests', () {
    test('fromJson parses complete payload correctly', () {
      final json = {
        'id': 'notif-123',
        'title': 'Pengajuan Cuti Disetujui',
        'body': 'Permohonan Cuti Tahunan Anda telah disetujui oleh HRD.',
        'type': 'leave_request',
        'data': {'requestId': 'req-999', 'type': 'ANNUAL'},
        'isRead': false,
        'readAt': null,
        'createdAt': '2026-09-12T10:00:00Z',
      };

      final model = NotificationItemModel.fromJson(json);

      expect(model.id, 'notif-123');
      expect(model.title, 'Pengajuan Cuti Disetujui');
      expect(model.body, 'Permohonan Cuti Tahunan Anda telah disetujui oleh HRD.');
      expect(model.type, 'leave_request');
      expect(model.data?['requestId'], 'req-999');
      expect(model.isRead, false);
      expect(model.readAt, isNull);
      expect(model.createdAt, '2026-09-12T10:00:00Z');
      expect(model.createdAtDateTime, isNotNull);
      expect(model.readAtDateTime, isNull);
    });

    test('toJson serializes correctly', () {
      const model = NotificationItemModel(
        id: 'notif-123',
        title: 'Title',
        body: 'Body',
        type: 'attendance',
        isRead: true,
        readAt: '2026-09-12T12:00:00Z',
        createdAt: '2026-09-12T10:00:00Z',
      );

      final json = model.toJson();

      expect(json['id'], 'notif-123');
      expect(json['title'], 'Title');
      expect(json['isRead'], true);
      expect(json['readAt'], '2026-09-12T12:00:00Z');
    });

    test('copyWith works correctly', () {
      const model = NotificationItemModel(
        id: 'notif-1',
        title: 'Title',
        body: 'Body',
        type: 'overtime',
        isRead: false,
      );

      final updated = model.copyWith(isRead: true, title: 'New Title');

      expect(updated.id, 'notif-1');
      expect(updated.title, 'New Title');
      expect(updated.isRead, true);
      expect(updated.body, 'Body');
    });

    test('timeAgoLabel handles different relative times', () {
      final now = DateTime.now();

      final justNow = NotificationItemModel(
        id: '1',
        title: '',
        body: '',
        type: 'general',
        createdAt: now.subtract(const Duration(seconds: 15)).toIso8601String(),
      );
      expect(justNow.timeAgoLabel, 'Baru saja');

      final minutesAgo = NotificationItemModel(
        id: '2',
        title: '',
        body: '',
        type: 'general',
        createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      );
      expect(minutesAgo.timeAgoLabel, '5m lalu');

      final hoursAgo = NotificationItemModel(
        id: '3',
        title: '',
        body: '',
        type: 'general',
        createdAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
      );
      expect(hoursAgo.timeAgoLabel, '3j lalu');

      final daysAgo = NotificationItemModel(
        id: '4',
        title: '',
        body: '',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 4)).toIso8601String(),
      );
      expect(daysAgo.timeAgoLabel, '4h lalu');
    });
  });

  group('NotificationPaginationMeta Tests', () {
    test('fromJson and toJson work correctly', () {
      final json = {
        'page': 2,
        'limit': 20,
        'total': 45,
        'totalPages': 3,
      };

      final meta = NotificationPaginationMeta.fromJson(json);

      expect(meta.page, 2);
      expect(meta.limit, 20);
      expect(meta.total, 45);
      expect(meta.totalPages, 3);
      expect(meta.toJson(), json);
    });

    test('fromJson handles null safely', () {
      final meta = NotificationPaginationMeta.fromJson(null);

      expect(meta.page, 1);
      expect(meta.limit, 20);
      expect(meta.total, 0);
      expect(meta.totalPages, 1);
    });
  });

  group('Notification Responses Tests', () {
    test('NotificationListResponse parses full list', () {
      final json = {
        'success': true,
        'message': 'Success',
        'data': [
          {
            'id': 'n-1',
            'title': 'Test',
            'body': 'Body',
            'type': 'announcement',
            'isRead': true,
          }
        ],
        'meta': {
          'page': 1,
          'limit': 20,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = NotificationListResponse.fromJson(json);

      expect(response.success, true);
      expect(response.data.length, 1);
      expect(response.data.first.id, 'n-1');
      expect(response.meta.totalPages, 1);
    });

    test('NotificationUnreadCountResponse parses unread count', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': {
          'unreadCount': 5,
        }
      };

      final response = NotificationUnreadCountResponse.fromJson(json);

      expect(response.success, true);
      expect(response.unreadCount, 5);
    });

    test('NotificationMarkReadAllResponse parses updatedCount', () {
      final json = {
        'success': true,
        'message': 'Marked all read',
        'data': {
          'message': 'string',
          'updatedCount': 3,
        }
      };

      final response = NotificationMarkReadAllResponse.fromJson(json);

      expect(response.success, true);
      expect(response.updatedCount, 3);
    });

    test('NotificationMarkReadResponse parses notification ID', () {
      final json = {
        'success': true,
        'message': 'Marked read',
        'data': {
          'message': 'Success',
          'id': 'n-123',
        }
      };

      final response = NotificationMarkReadResponse.fromJson(json);

      expect(response.success, true);
      expect(response.id, 'n-123');
    });
  });
}
