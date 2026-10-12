import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';

void main() {
  group('WorkScheduleResponse Models Serialization & Helper Tests', () {
    final sampleResponseJson = {
      'success': true,
      'message': 'Jadwal kerja berhasil dimuat',
      'data': {
        'id': 'ws-data-001',
        'employee': {
          'id': 'emp-001',
          'firstName': 'Budi',
          'lastName': 'Pratama',
          'email': 'budi.p@oasish.com',
          'phone': '08123456789',
          'photoUrl': 'https://example.com/budi.jpg',
          'employeeNumber': 'EMP-001',
          'idNumber': '3171012345670001',
          'company': {'id': 'comp-1', 'name': 'PT Oasish Nusantara'},
          'department': {'id': 'dept-1', 'name': 'Information Technology'},
          'position': {'id': 'pos-1', 'name': 'Mobile Engineer'},
          'level': {'id': 'lvl-1', 'name': 'Senior'},
        },
        'workSchedules': [
          {
            'id': 'item-001',
            'workDate': '2026-10-12',
            'isDayOff': false,
            'dayOffNotes': null,
            'shift': {
              'id': 'shift-pagi',
              'name': 'Shift Reguler Pagi',
              'startTime': '08:00',
              'endTime': '17:00',
              'isFlexibleTime': false,
              'isFlexibleBreak': true,
              'breakStart': '12:00',
              'breakEnd': '13:00',
              'isNightShift': false,
              'color': '#0F766E',
            },
          },
          {
            'id': 'item-002',
            'workDate': '2026-10-18',
            'isDayOff': true,
            'dayOffNotes': 'Hari Libur Akhir Pekan',
            'shift': null,
          }
        ],
      },
    };

    test('WorkScheduleResponse fromJson and toJson maps completely', () {
      final response = WorkScheduleResponse.fromJson(sampleResponseJson);

      expect(response.success, isTrue);
      expect(response.message, 'Jadwal kerja berhasil dimuat');
      expect(response.data, isNotNull);
      expect(response.data!.id, 'ws-data-001');

      final serialized = response.toJson();
      expect(serialized['success'], isTrue);
      expect(serialized['message'], 'Jadwal kerja berhasil dimuat');
      expect(serialized['data'], isA<Map<String, dynamic>>());
      expect(response.props, equals([response.success, response.message, response.data]));
    });

    test('WorkScheduleEmployee helpers (fullName, initials, extractName) work properly', () {
      final response = WorkScheduleResponse.fromJson(sampleResponseJson);
      final employee = response.data!.employee!;

      expect(employee.id, 'emp-001');
      expect(employee.fullName, 'Budi Pratama');
      expect(employee.initials, 'BP');
      expect(employee.companyName, 'PT Oasish Nusantara');
      expect(employee.departmentName, 'Information Technology');
      expect(employee.positionName, 'Mobile Engineer');
      expect(employee.levelName, 'Senior');

      // Test without lastName
      const singleNameEmployee = WorkScheduleEmployee(
        id: 'emp-002',
        firstName: 'Suharto',
      );
      expect(singleNameEmployee.fullName, 'Suharto');
      expect(singleNameEmployee.initials, 'S');

      final serialized = employee.toJson();
      expect(serialized['firstName'], 'Budi');
      expect(serialized['company']['name'], 'PT Oasish Nusantara');
    });

    test('WorkScheduleItem date parsing and isSameDay logic works correctly', () {
      final response = WorkScheduleResponse.fromJson(sampleResponseJson);
      final activeItem = response.data!.workSchedules[0];
      final dayOffItem = response.data!.workSchedules[1];

      expect(activeItem.id, 'item-001');
      expect(activeItem.isDayOff, isFalse);
      expect(activeItem.parsedDate, DateTime(2026, 10, 12));
      expect(activeItem.isSameDay(DateTime(2026, 10, 12, 15, 30)), isTrue);
      expect(activeItem.isSameDay(DateTime(2026, 10, 13)), isFalse);

      expect(dayOffItem.isDayOff, isTrue);
      expect(dayOffItem.dayOffNotes, 'Hari Libur Akhir Pekan');
      expect(dayOffItem.shift, isNull);

      // Invalid date safety
      const invalidDateItem = WorkScheduleItem(id: 'inv-1', workDate: 'invalid-date');
      expect(invalidDateItem.parsedDate, isNull);
      expect(invalidDateItem.isSameDay(DateTime.now()), isFalse);
    });

    test('WorkScheduleShift properties and serialization work properly', () {
      final response = WorkScheduleResponse.fromJson(sampleResponseJson);
      final shift = response.data!.workSchedules[0].shift!;

      expect(shift.id, 'shift-pagi');
      expect(shift.name, 'Shift Reguler Pagi');
      expect(shift.startTime, '08:00');
      expect(shift.endTime, '17:00');
      expect(shift.isFlexibleTime, isFalse);
      expect(shift.isFlexibleBreak, isTrue);
      expect(shift.breakStart, '12:00');
      expect(shift.breakEnd, '13:00');
      expect(shift.isNightShift, isFalse);
      expect(shift.color, '#0F766E');

      final serializedShift = shift.toJson();
      expect(serializedShift['id'], 'shift-pagi');
      expect(serializedShift['isFlexibleBreak'], isTrue);
      expect(shift.props, contains('#0F766E'));
    });

    test('Handles empty and null JSON payloads safely', () {
      final emptyResponse = WorkScheduleResponse.fromJson(const {});
      expect(emptyResponse.success, isFalse);
      expect(emptyResponse.message, '');
      expect(emptyResponse.data, isNull);

      final emptyData = WorkScheduleData.fromJson(const {});
      expect(emptyData.id, '');
      expect(emptyData.employee, isNull);
      expect(emptyData.workSchedules, isEmpty);
    });
  });
}
