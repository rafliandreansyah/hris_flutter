import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';

void main() {
  group('LeaveTypeOptionModel', () {
    test('fromJson parses complete json correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'code': 'SICK',
        'name': 'Cuti Sakit',
        'description': 'Izin sakit dengan surat dokter',
        'status': true,
        'fixedDays': 2,
        'isDeducted': false,
        'requiresApprove': true,
        'requiresFile': true,
        'maxDays': 5,
      };

      final model = LeaveTypeOptionModel.fromJson(json);

      expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.code, 'SICK');
      expect(model.name, 'Cuti Sakit');
      expect(model.description, 'Izin sakit dengan surat dokter');
      expect(model.status, true);
      expect(model.fixedDays, 2);
      expect(model.isDeducted, false);
      expect(model.requiresApprove, true);
      expect(model.requiresFile, true);
      expect(model.maxDays, 5);
    });

    test('fromJson handles null optional fields and defaults', () {
      final json = {
        'id': '123',
        'code': 'ANNUAL',
        'name': 'Cuti Tahunan',
      };

      final model = LeaveTypeOptionModel.fromJson(json);

      expect(model.id, '123');
      expect(model.code, 'ANNUAL');
      expect(model.name, 'Cuti Tahunan');
      expect(model.description, isNull);
      expect(model.status, true);
      expect(model.fixedDays, isNull);
      expect(model.isDeducted, false);
      expect(model.requiresApprove, true);
      expect(model.requiresFile, false);
      expect(model.maxDays, isNull);
    });

    test('toJson serializes correctly', () {
      const model = LeaveTypeOptionModel(
        id: '123',
        code: 'SICK',
        name: 'Cuti Sakit',
        fixedDays: 1,
        requiresFile: true,
      );

      final json = model.toJson();

      expect(json['id'], '123');
      expect(json['code'], 'SICK');
      expect(json['name'], 'Cuti Sakit');
      expect(json['fixedDays'], 1);
      expect(json['requiresFile'], true);
    });

    test('Equatable props work correctly', () {
      const m1 = LeaveTypeOptionModel(id: '1', code: 'A', name: 'Alpha');
      const m2 = LeaveTypeOptionModel(id: '1', code: 'A', name: 'Alpha');
      const m3 = LeaveTypeOptionModel(id: '2', code: 'B', name: 'Beta');

      expect(m1, equals(m2));
      expect(m1 == m3, isFalse);
    });
  });

  group('CreateLeaveResultModel', () {
    test('fromJson parses object data format correctly', () {
      final json = {
        'success': true,
        'message': 'Pengajuan berhasil',
        'data': {
          'id': 'uuid-12345',
        },
      };

      final model = CreateLeaveResultModel.fromJson(json);

      expect(model.success, true);
      expect(model.message, 'Pengajuan berhasil');
      expect(model.id, 'uuid-12345');
    });

    test('fromJson parses string data format correctly', () {
      final json = {
        'success': true,
        'message': 'Created',
        'data': 'uuid-67890',
      };

      final model = CreateLeaveResultModel.fromJson(json);

      expect(model.success, true);
      expect(model.id, 'uuid-67890');
    });

    test('toJson serializes correctly', () {
      const model = CreateLeaveResultModel(
        success: true,
        message: 'Sukses',
        id: '123',
      );

      final json = model.toJson();

      expect(json['success'], true);
      expect(json['message'], 'Sukses');
      expect(json['data'], {'id': '123'});
    });
  });
}
