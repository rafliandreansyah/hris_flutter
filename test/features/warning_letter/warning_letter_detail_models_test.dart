import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';

void main() {
  group('WarningLetterDetailModel Tests', () {
    final sampleJson = {
      'success': true,
      'message': 'Detail SP berhasil dimuat',
      'data': {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'warningLetterType': {
          'level': 1,
          'name': 'Surat Peringatan I (SP 1)',
        },
        'referenceNumber': 'SP/2026/08/0019',
        'attachmentUrl':
            'https://example.com/files/Surat_Peringatan_Resmi_123E4567.pdf',
        'infractionReason': 'Indisipliner Keterlambatan & Kehadiran (SP 1)',
        'sanction': 'Pemotongan tunjangan kehadiran 10%',
        'employee': {
          'id': 'emp-101',
          'firstName': 'Sarah',
          'lastName': 'Jenkins',
          'email': 'sarah.j@oasish.com',
          'phone': '+62812345678',
          'idNumber': '3271000000000001',
          'employeeNumber': 'EMP-2024-019',
          'company': {
            'id': 'c-1',
            'name': 'PT Oasish Tech Nusantara',
          },
          'department': {
            'id': 'd-1',
            'name': 'Engineering',
            'code': 'ENG',
          },
          'position': {
            'id': 'p-1',
            'name': 'Frontend Engineer',
            'code': 'FE',
          },
          'photoUrl': 'https://example.com/sarah.jpg',
        },
        'issuedDate': '2026-08-29',
        'expiredDate': '2027-02-28',
        'timezone': 'WIB',
        'isActive': true,
        'issuedByEmployee': {
          'id': 'emp-202',
          'firstName': 'Alex',
          'lastName': 'Rivera',
          'email': 'alex.r@oasish.com',
          'phone': '+62812345679',
          'idNumber': null,
          'employeeNumber': 'EMP-2020-001',
          'company': {
            'id': 'c-1',
            'name': 'PT Oasish Tech Nusantara',
          },
          'department': {
            'id': 'd-1',
            'name': 'Engineering',
            'code': 'ENG',
          },
          'position': {
            'id': 'p-2',
            'name': 'Engineering Manager',
            'code': 'EM',
          },
          'photoUrl': null,
        },
        'createdAt': '2026-08-29T12:47:00.000Z',
      },
    };

    test('parses full API response correctly', () {
      final response = WarningLetterDetailResponse.fromJson(sampleJson);

      expect(response.success, isTrue);
      expect(response.message, 'Detail SP berhasil dimuat');

      final detail = response.data;
      expect(detail.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(detail.warningLetterType.level, 1);
      expect(detail.warningLetterType.name, 'Surat Peringatan I (SP 1)');
      expect(detail.referenceNumber, 'SP/2026/08/0019');
      expect(detail.infractionReason,
          'Indisipliner Keterlambatan & Kehadiran (SP 1)');
      expect(detail.sanction, 'Pemotongan tunjangan kehadiran 10%');
      expect(detail.timezone, 'WIB');
      expect(detail.isActive, isTrue);

      expect(detail.employee?.fullName, 'Sarah Jenkins');
      expect(detail.employee?.position?.name, 'Frontend Engineer');
      expect(detail.employee?.department?.name, 'Engineering');
      expect(detail.employee?.company?.name, 'PT Oasish Tech Nusantara');
      expect(detail.employee?.employeeNumber, 'EMP-2024-019');

      expect(detail.issuedByEmployee?.fullName, 'Alex Rivera');
      expect(detail.issuedByEmployee?.position?.name, 'Engineering Manager');
      expect(detail.issuedByEmployee?.initials, 'AR');

      expect(detail.isAttachmentPdf, isTrue);
      expect(detail.attachmentFileName,
          'Surat_Peringatan_Resmi_123E4567.pdf');
      expect(detail.displayTitle,
          'Indisipliner Keterlambatan & Kehadiran (SP 1)');
      expect(detail.levelBadgeLabel, 'Surat Peringatan 1 (SP 1)');
      expect(detail.formattedPeriod, isNotEmpty);
    });

    test('handles null and optional fields gracefully', () {
      final minimalJson = {
        'id': 'wl-minimal-1',
        'warningLetterType': {
          'level': 2,
          'name': 'Surat Peringatan II',
        },
        'referenceNumber': null,
        'attachmentUrl': null,
        'infractionReason': null,
        'sanction': null,
        'employee': null,
        'issuedDate': null,
        'expiredDate': null,
        'timezone': 'WIB',
        'isActive': false,
        'issuedByEmployee': null,
        'createdAt': null,
      };

      final detail = WarningLetterDetail.fromJson(minimalJson);

      expect(detail.id, 'wl-minimal-1');
      expect(detail.referenceNumber, isNull);
      expect(detail.attachmentUrl, isNull);
      expect(detail.infractionReason, isNull);
      expect(detail.sanction, isNull);
      expect(detail.employee, isNull);
      expect(detail.issuedByEmployee, isNull);
      expect(detail.issuedDate, isNull);
      expect(detail.expiredDate, isNull);
      expect(detail.isActive, isFalse);

      expect(detail.displayTitle, 'Surat Peringatan II');
      expect(detail.levelBadgeLabel, 'Surat Peringatan 2 (SP 2)');
      expect(detail.formattedPeriod, '-');
      expect(detail.formattedCreatedAt, '-');
      expect(detail.attachmentFileName, 'Surat_Peringatan_wl-minimal-1.pdf');
      expect(detail.isAttachmentPdf, isFalse);
    });

    test('toJson produces valid serializable map', () {
      final detail = WarningLetterDetail(
        id: 'wl-test-1',
        warningLetterType:
            const WarningLetterTypeSummary(level: 3, name: 'SP 3 Terakhir'),
        referenceNumber: 'REF-001',
        attachmentUrl: 'https://cdn.example.com/doc.pdf',
        infractionReason: 'Pelanggaran Berat',
        sanction: 'PHK',
        employee: const WarningLetterEmployee(
          id: 'e1',
          firstName: 'Dimas',
        ),
        issuedDate: DateTime(2026, 9, 1),
        expiredDate: DateTime(2027, 3, 1),
        timezone: 'WIB',
        isActive: true,
        issuedByEmployee: null,
        createdAt: DateTime(2026, 9, 1, 10, 0),
      );

      final map = detail.toJson();
      expect(map['id'], 'wl-test-1');
      expect(map['referenceNumber'], 'REF-001');
      expect(map['isActive'], isTrue);
      expect(map['infractionReason'], 'Pelanggaran Berat');

      final roundtrip = WarningLetterDetail.fromJson(map);
      expect(roundtrip.id, detail.id);
      expect(roundtrip.displayTitle, detail.displayTitle);
      expect(roundtrip.levelBadgeLabel, detail.levelBadgeLabel);
    });

    test('correctly identifies image and photo attachments', () {
      const imageDetail = WarningLetterDetail(
        id: 'wl-img-1',
        warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
        attachmentUrl: 'https://example.com/uploads/bukti_pelanggaran.jpg?token=abc',
        referenceNumber: 'SP/2026/08/0020',
        timezone: 'WIB',
        isActive: true,
      );

      expect(imageDetail.hasAttachment, isTrue);
      expect(imageDetail.isAttachmentImage, isTrue);
      expect(imageDetail.isAttachmentPdf, isFalse);
      expect(imageDetail.attachmentFileName, 'bukti_pelanggaran.jpg');

      const pngDetail = WarningLetterDetail(
        id: 'wl-img-2',
        warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
        attachmentUrl: 'https://example.com/uploads/photo.PNG',
        timezone: 'WIB',
        isActive: true,
      );
      expect(pngDetail.isAttachmentImage, isTrue);
      expect(pngDetail.isAttachmentPdf, isFalse);

      const pdfDetail = WarningLetterDetail(
        id: 'wl-doc-1',
        warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
        attachmentUrl: 'https://example.com/uploads/surat.pdf',
        timezone: 'WIB',
        isActive: true,
      );
      expect(pdfDetail.isAttachmentImage, isFalse);
      expect(pdfDetail.isAttachmentPdf, isTrue);
    });
  });
}
