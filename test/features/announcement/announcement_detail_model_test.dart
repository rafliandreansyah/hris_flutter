import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';

void main() {
  group('AnnouncementDetailModel Tests', () {
    const jsonSample = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'title': 'Kebijakan Kerja Fleksibel (WFA) & Protokol Kehadiran Q3 2026',
      'summary': null,
      'content': '<p>Diberitahukan kepada seluruh karyawan...</p>',
      'imageUrl': 'https://example.com/cover.jpg',
      'priority': 'urgent',
      'category': 'hr_policy',
      'isPinned': true,
      'requiresAcknowledgment': true,
      'scope': 'company',
      'userReadStatus': {
        'isRead': true,
        'readAt': '2026-08-28T03:11:00.000Z',
        'isAcknowledged': false,
        'acknowledgedAt': null,
      },
      'attachments': [
        {
          'id': 'att-1',
          'fileName': 'Pedoman_Resmi_WFA_Q3_2026.pdf',
          'fileUrl': 'https://example.com/pedoman.pdf',
          'fileSize': 2516582, // ~2.4 MB
          'fileType': 'application/pdf',
          'createdAt': '2026-08-28T03:11:00.000Z',
        },
        {
          'id': 'att-2',
          'fileName': 'Data_Terkait.xlsx',
          'fileUrl': 'https://example.com/data.xlsx',
          'fileSize': 512000, // 500 KB
          'fileType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'createdAt': '2026-08-28T03:11:00.000Z',
        }
      ],
      'author': {
        'id': 'author-1',
        'firstName': 'Jessica',
        'lastName': 'Pranata',
        'email': 'jessica@oasish.com',
        'phone': '08123456789',
        'idNumber': null,
        'employeeNumber': 'EMP-HR-002',
        'company': {
          'id': 'comp-1',
          'name': 'Oasish Tech',
        },
        'department': {
          'id': 'dept-1',
          'name': 'Human Resources',
          'code': 'HR',
        },
        'position': {
          'id': 'pos-1',
          'name': 'Head of People & Culture',
          'code': 'HPC',
        },
        'photoUrl': 'https://example.com/jessica.jpg',
      },
      'publishedAt': '2026-08-28T03:11:00.000Z',
      'createdAt': '2026-08-28T03:11:00.000Z',
    };

    test('fromJson correctly parses complete detail payload', () {
      final detail = AnnouncementDetailModel.fromJson(jsonSample);

      expect(detail.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(detail.title, contains('Kebijakan Kerja Fleksibel'));
      expect(detail.isPinned, isTrue);
      expect(detail.requiresAcknowledgment, isTrue);
      expect(detail.categoryBadgeText, 'POLICY');
      expect(detail.priorityDisplayName, 'URGENT NOTICE');
      expect(detail.scopeDisplayName, 'Company-Wide');
      expect(detail.scopeAndCategorySubtitle, 'SCOPE: COMPANY • POLICY');
      expect(detail.userReadStatus?.isAcknowledged, isFalse);
      expect(detail.attachments.length, 2);
      expect(detail.author?.fullName, 'Jessica Pranata');
      expect(detail.author?.positionAndDeptLabel, 'Head of People & Culture • Human Resources');
      expect(detail.author?.companyAndEmpNoLabel, 'Oasish Tech • EMP-HR-002');
    });

    test('AnnouncementAttachment correctly identifies PDF and formats size', () {
      final detail = AnnouncementDetailModel.fromJson(jsonSample);
      final pdfAtt = detail.attachments[0];
      final excelAtt = detail.attachments[1];

      expect(pdfAtt.isPdf, isTrue);
      expect(pdfAtt.formattedSize, '2.4 MB');
      expect(pdfAtt.subtitleLabel, '2.4 MB • PDF');

      expect(excelAtt.isPdf, isFalse);
      expect(excelAtt.formattedSize, '500.0 KB');
    });

    test('AnnouncementAcknowledgeResponse parses response properly', () {
      const ackJson = {
        'success': true,
        'message': 'Pengumuman berhasil dikonfirmasi',
        'data': {
          'message': 'OK',
          'acknowledgedAt': '2026-09-18T11:31:23.515Z',
        },
      };

      final resp = AnnouncementAcknowledgeResponse.fromJson(ackJson);
      expect(resp.success, isTrue);
      expect(resp.message, 'Pengumuman berhasil dikonfirmasi');
      expect(resp.data.acknowledgedAt, '2026-09-18T11:31:23.515Z');
    });
  });
}
