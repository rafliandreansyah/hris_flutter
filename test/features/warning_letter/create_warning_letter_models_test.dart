import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('LastWarningLetterModel Tests', () {
    test('parses full JSON correctly', () {
      final json = {
        'id': 'wl-last-1',
        'warningLetterType': {
          'id': 'type-sp1',
          'name': 'Surat Peringatan I (SP 1)',
          'level': 1,
          'validityPeriodMonths': 6,
        },
        'employee': {
          'id': 'emp-101',
          'firstName': 'Budi',
          'lastName': 'Santoso',
          'email': 'budi@example.com',
          'phone': '08123456789',
          'idNumber': 'ID-12345',
          'employeeNumber': 'EMP-8492',
          'company': {'id': 'comp-1', 'name': 'PT Muratech'},
          'department': {'id': 'dept-1', 'name': 'Operations', 'code': 'OPS'},
          'position': {'id': 'pos-1', 'name': 'Site Supervisor', 'code': 'SS'},
          'photoUrl': 'https://example.com/avatar.png',
        },
        'referenceNumber': 'SP/MUR/2026/08/001',
        'issuedDate': '2026-08-01',
        'expiredDate': '2027-02-01',
        'infractionReason': 'Keterlambatan berulang',
        'sanction': 'Pemotongan tunjangan kehadiran',
        'isActive': true,
        'createdAt': '2026-08-01T08:00:00.000Z',
        'timezone': 'WIB',
      };

      final model = LastWarningLetterModel.fromJson(json);

      expect(model.id, 'wl-last-1');
      expect(model.referenceNumber, 'SP/MUR/2026/08/001');
      expect(model.warningLetterType.name, 'Surat Peringatan I (SP 1)');
      expect(model.warningLetterType.level, 1);
      expect(model.employee?.fullName, 'Budi Santoso');
      expect(model.employee?.company?.name, 'PT Muratech');
      expect(model.issuedDate, DateTime(2026, 8, 1));
      expect(model.expiredDate, DateTime(2027, 2, 1));
      expect(model.infractionReason, 'Keterlambatan berulang');
      expect(model.sanction, 'Pemotongan tunjangan kehadiran');
      expect(model.isActive, true);
    });

    test('handles null fields gracefully', () {
      final json = {
        'id': 'wl-null',
        'isActive': false,
      };

      final model = LastWarningLetterModel.fromJson(json);

      expect(model.id, 'wl-null');
      expect(model.referenceNumber, '-');
      expect(model.employee, isNull);
      expect(model.issuedDate, isNull);
      expect(model.expiredDate, isNull);
      expect(model.infractionReason, isNull);
      expect(model.sanction, isNull);
      expect(model.isActive, false);
    });
  });

  group('CreateWarningLetterRequest Tests', () {
    test('toFormData without file produces correct map', () async {
      const request = CreateWarningLetterRequest(
        employeeId: 'emp-101',
        warningLetterTypeId: 'type-sp2',
        reason: 'Pelanggaran SOP',
        sanction: 'Teguran tertulis',
        issuedDate: '2026-09-19',
      );

      final formData = await request.toFormData();

      expect(formData.fields.any((f) => f.key == 'employeeId' && f.value == 'emp-101'), isTrue);
      expect(formData.fields.any((f) => f.key == 'warningLetterTypeId' && f.value == 'type-sp2'), isTrue);
      expect(formData.fields.any((f) => f.key == 'reason' && f.value == 'Pelanggaran SOP'), isTrue);
      expect(formData.fields.any((f) => f.key == 'sanction' && f.value == 'Teguran tertulis'), isTrue);
      expect(formData.fields.any((f) => f.key == 'issuedDate' && f.value == '2026-09-19'), isTrue);
      expect(formData.files.isEmpty, isTrue);
    });

    test('toFormData with file includes multipart file', () async {
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'dummy.pdf',
        path: 'dummy.pdf',
      );
      final request = CreateWarningLetterRequest(
        employeeId: 'emp-101',
        warningLetterTypeId: 'type-sp1',
        reason: 'Alasan SP',
        issuedDate: '2026-09-19',
        file: file,
      );

      final formData = await request.toFormData();

      expect(formData.files.length, 1);
      expect(formData.files.first.key, 'file');
      expect(formData.files.first.value.filename, 'dummy.pdf');
    });
  });

  group('CreateWarningLetterResponse Tests', () {
    test('parses JSON response correctly', () {
      final json = {
        'success': true,
        'message': 'Surat peringatan berhasil dibuat',
        'data': {
          'id': 'wl-new-123',
          'referenceNumber': 'SP/2026/09/005',
        },
      };

      final response = CreateWarningLetterResponse.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Surat peringatan berhasil dibuat');
      expect(response.data?.id, 'wl-new-123');
      expect(response.data?.referenceNumber, 'SP/2026/09/005');
    });
  });
}
