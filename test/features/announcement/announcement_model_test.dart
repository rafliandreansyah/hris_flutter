import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';

void main() {
  group('AnnouncementItem Model Tests', () {
    const jsonSample = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'title': 'Townhall Meeting & Update Kebijakan',
      'summary': null,
      'content': '<p>Informasi detail mengenai jadwal townhall minggu ini.</p>',
      'imageUrl': null,
      'priority': 'urgent',
      'category': 'hr_policy',
      'isPinned': true,
      'requiresAcknowledgment': true,
      'isRead': false,
      'isAcknowledged': false,
      'publishedAt': null,
      'createdAt': '2026-09-18T10:08:24.635Z',
    };

    test('fromJson correctly parses fields and handles null values', () {
      final item = AnnouncementItem.fromJson(jsonSample);

      expect(item.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(item.title, 'Townhall Meeting & Update Kebijakan');
      expect(item.summary, isNull);
      expect(item.content, contains('Informasi detail'));
      expect(item.imageUrl, isNull);
      expect(item.priority, 'urgent');
      expect(item.category, 'hr_policy');
      expect(item.isPinned, isTrue);
      expect(item.requiresAcknowledgment, isTrue);
      expect(item.isRead, isFalse);
      expect(item.isAcknowledged, isFalse);
      expect(item.publishedAt, isNull);
      expect(item.createdAt, '2026-09-18T10:08:24.635Z');
    });

    test('toJson produces correct map', () {
      final item = AnnouncementItem.fromJson(jsonSample);
      final json = item.toJson();

      expect(json['id'], item.id);
      expect(json['title'], item.title);
      expect(json['priority'], 'urgent');
      expect(json['category'], 'hr_policy');
      expect(json['isPinned'], isTrue);
    });

    test('displayDescription strips html tags when summary is null', () {
      final item = AnnouncementItem.fromJson(jsonSample);
      expect(
        item.displayDescription,
        'Informasi detail mengenai jadwal townhall minggu ini.',
      );
    });

    test('displayDescription prioritizes summary over content', () {
      const item = AnnouncementItem(
        id: '1',
        title: 'Judul',
        summary: 'Ringkasan singkat',
        content: 'Isi konten lengkap',
      );
      expect(item.displayDescription, 'Ringkasan singkat');
    });

    test('categoryDisplayName and priorityDisplayName return correct labels', () {
      final item = AnnouncementItem.fromJson(jsonSample);
      expect(item.categoryDisplayName, 'Kebijakan HR');
      expect(item.categoryBadgeText, 'HR POLICY');
      expect(item.priorityDisplayName, 'Mendesak');
    });

    test('formattedDate formats date properly', () {
      final item = AnnouncementItem.fromJson(jsonSample);
      expect(item.formattedDate, '18 September 2026');
    });
  });

  group('AnnouncementListResponse Tests', () {
    const responseJson = {
      'success': true,
      'message': 'OK',
      'data': [
        {
          'id': 'a-1',
          'title': 'Pengumuman 1',
          'content': 'Konten',
          'isPinned': true,
        },
        {
          'id': 'a-2',
          'title': 'Pengumuman 2',
          'content': 'Konten 2',
          'isPinned': false,
        }
      ],
      'meta': {
        'page': 1,
        'limit': 10,
        'total': 2,
        'totalPages': 1,
      }
    };

    test('fromJson parses list and meta accurately', () {
      final resp = AnnouncementListResponse.fromJson(responseJson);

      expect(resp.success, isTrue);
      expect(resp.message, 'OK');
      expect(resp.data.length, 2);
      expect(resp.data[0].id, 'a-1');
      expect(resp.data[0].isPinned, isTrue);
      expect(resp.data[1].id, 'a-2');
      expect(resp.meta.page, 1);
      expect(resp.meta.total, 2);
      expect(resp.meta.totalPages, 1);
    });
  });
}
