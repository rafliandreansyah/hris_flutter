import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';

void main() {
  group('Overtime API Models Tests', () {
    test('OvertimePaginationMeta fromJson and toJson', () {
      final json = {
        'page': 2,
        'limit': 15,
        'total': 45,
        'totalPages': 3,
      };

      final meta = OvertimePaginationMeta.fromJson(json);
      expect(meta.page, 2);
      expect(meta.limit, 15);
      expect(meta.total, 45);
      expect(meta.totalPages, 3);

      final outJson = meta.toJson();
      expect(outJson['page'], 2);
      expect(outJson['limit'], 15);
      expect(outJson['total'], 45);
      expect(outJson['totalPages'], 3);

      // Default fallback
      final emptyMeta = OvertimePaginationMeta.fromJson({});
      expect(emptyMeta.page, 1);
      expect(emptyMeta.limit, 30);
      expect(emptyMeta.total, 0);
      expect(emptyMeta.totalPages, 1);
    });

    test('Overtime Organization Models (Company, Department, Position)', () {
      final comp = OvertimeCompanyModel.fromJson({'id': 'c1', 'name': 'Oasish Corp'});
      expect(comp.id, 'c1');
      expect(comp.name, 'Oasish Corp');

      final dept = OvertimeDepartmentModel.fromJson({'id': 'd1', 'name': 'Engineering'});
      expect(dept.id, 'd1');
      expect(dept.name, 'Engineering');

      final pos = OvertimePositionModel.fromJson({'id': 'p1', 'name': 'Lead Dev'});
      expect(pos.id, 'p1');
      expect(pos.name, 'Lead Dev');

      // Null handling
      final emptyComp = OvertimeCompanyModel.fromJson({});
      expect(emptyComp.id, '');
      expect(emptyComp.name, '');
    });

    test('OvertimeEmployeeModel full fields and helper getters', () {
      final json = {
        'id': 'emp-101',
        'firstName': 'Budi',
        'lastName': 'Santoso',
        'email': 'budi@oasish.app',
        'phone': '081234567890',
        'idNumber': '3201010101',
        'employeeNumber': 'EMP-01',
        'photoUrl': 'uploads/avatar.jpg',
        'company': {'id': 'c1', 'name': 'Oasish Corp'},
        'department': {'id': 'd1', 'name': 'Engineering'},
        'position': {'id': 'p1', 'name': 'Mobile Engineer'},
      };

      final emp = OvertimeEmployeeModel.fromJson(json);
      expect(emp.id, 'emp-101');
      expect(emp.firstName, 'Budi');
      expect(emp.lastName, 'Santoso');
      expect(emp.fullName, 'Budi Santoso');
      expect(emp.initials, 'BS');
      expect(emp.company?.name, 'Oasish Corp');
      expect(emp.department?.name, 'Engineering');
      expect(emp.position?.name, 'Mobile Engineer');

      // Single word name initials
      final singleName = OvertimeEmployeeModel.fromJson({
        'id': 'emp-102',
        'firstName': 'Budi',
      });
      expect(singleName.fullName, 'Budi');
      expect(singleName.initials, 'BU');

      // Empty name initials
      final emptyName = OvertimeEmployeeModel.fromJson({
        'id': 'emp-103',
        'firstName': '',
      });
      expect(emptyName.fullName, '');
      expect(emptyName.initials, '?');
    });

    test('OvertimeApiModel and overtimeRequestItemFromApiJson mapping', () {
      final json = {
        'id': 'ot-100',
        'employee': {
          'id': 'emp-101',
          'firstName': 'Siti',
          'lastName': 'Rahma',
          'employeeNumber': 'EMP-02',
          'photoUrl': 'https://storage.googleapis.com/avatar.jpg',
          'company': {'id': 'c1', 'name': 'Oasish Tech'},
          'department': {'id': 'd1', 'name': 'Product'},
          'position': {'id': 'p1', 'name': 'Designer'},
        },
        'startOvertime': '2026-10-12T17:00:00Z',
        'endOvertime': '2026-10-12T20:00:00Z',
        'notes': 'Overtime to complete Sprint release UI design',
        'approverNotes': 'Approved for tonight',
        'timezone': 'WIB',
        'status': 'approved',
      };

      final itemApprover = overtimeRequestItemFromApiJson(json, isApprover: true);
      expect(itemApprover.id, 'ot-100');
      expect(itemApprover.employeeId, 'emp-101');
      expect(itemApprover.name, 'Siti Rahma');
      expect(itemApprover.role, 'Designer');
      expect(itemApprover.department, 'Product');
      expect(itemApprover.company, 'Oasish Tech');
      expect(itemApprover.status, OvertimeStatus.approved);
      expect(itemApprover.isSelf, false);
      expect(itemApprover.notes, 'Overtime to complete Sprint release UI design');
      expect(itemApprover.approverNotes, 'Approved for tonight');

      // Self request (isApprover = false) with rejected status
      final itemSelf = overtimeRequestItemFromApiJson(
        {
          'id': 'ot-101',
          'startOvertime': '2026-10-12T18:00:00Z',
          'endOvertime': '2026-10-12T21:00:00Z',
          'reason': 'Server maintenance',
          'status': 'rejected',
        },
        isApprover: false,
      );
      expect(itemSelf.name, 'Saya');
      expect(itemSelf.isSelf, true);
      expect(itemSelf.status, OvertimeStatus.rejected);
      expect(itemSelf.notes, 'Server maintenance');
    });

    test('OvertimeRequestListResponse fromJson and toJson', () {
      final json = {
        'success': true,
        'message': 'Overtime requests retrieved successfully',
        'data': [
          {
            'id': 'ot-01',
            'status': 'requested',
            'startOvertime': '2026-10-12T17:00:00Z',
            'endOvertime': '2026-10-12T20:00:00Z',
          }
        ],
        'meta': {
          'page': 1,
          'limit': 20,
          'total': 1,
          'totalPages': 1,
        }
      };

      final resp = OvertimeRequestListResponse.fromJson(json);
      expect(resp.success, true);
      expect(resp.message, 'Overtime requests retrieved successfully');
      expect(resp.data.length, 1);
      expect(resp.data.first.id, 'ot-01');
      expect(resp.data.first.status, OvertimeStatus.requested);
      expect(resp.meta.total, 1);

      final out = resp.toJson();
      expect(out['success'], true);
      expect((out['data'] as List).length, 1);
      expect(out['meta']['total'], 1);
    });
  });

  group('Overtime Presentation Models & Helpers Tests', () {
    test('OvertimeStatusExtension styling tokens and labels', () {
      for (final st in OvertimeStatus.values) {
        expect(st.label.isNotEmpty, true);
        expect(st.textColor, isNotNull);
        expect(st.backgroundColor, isNotNull);
        expect(st.dotColor, isNotNull);
      }
      expect(OvertimeStatus.pending.label, 'Pending');
      expect(OvertimeStatus.approved.label, 'Approved');
      expect(OvertimeStatus.rejected.label, 'Rejected');
    });

    test('OvertimeRequestItem duration, labels, and copyWith', () {
      final start = DateTime(2026, 10, 12, 17, 0);
      final end = DateTime(2026, 10, 12, 21, 30); // 4.5 hours

      final item = OvertimeRequestItem(
        id: 'ot-1',
        name: 'John Doe',
        initials: 'JD',
        startTime: start,
        endTime: end,
        notes: 'Testing sprint deadline',
        status: OvertimeStatus.pending,
      );

      expect(item.dateLabel, '12 Okt 2026');
      expect(item.timeRangeLabel, '17:00 - 21:30');
      expect(item.durationHours, 4.5);
      expect(item.durationLabel, '4.5 Jam Kerja');
      expect(item.note, 'Testing sprint deadline');

      final copied = item.copyWith(
        status: OvertimeStatus.approved,
        notes: 'Updated notes',
      );
      expect(copied.id, 'ot-1');
      expect(copied.status, OvertimeStatus.approved);
      expect(copied.notes, 'Updated notes');
      expect(copied.props, isNotEmpty);
    });
  });

  group('Overtime Create Models Tests', () {
    test('OvertimeShiftModel fromJson and toJson', () {
      final json = {
        'id': 'shift-01',
        'startTime': '08:00:00',
        'endTime': '17:00:00',
        'isFlexibleTime': false,
        'isFlexibleBreak': true,
        'breakStart': '12:00:00',
        'breakEnd': '13:00:00',
        'isNightShift': false,
        'color': '#0F766E',
      };

      final shift = OvertimeShiftModel.fromJson(json);
      expect(shift.id, 'shift-01');
      expect(shift.startTime, '08:00:00');
      expect(shift.endTime, '17:00:00');
      expect(shift.isFlexibleBreak, true);
      expect(shift.color, '#0F766E');

      final out = shift.toJson();
      expect(out['id'], 'shift-01');
      expect(out['startTime'], '08:00:00');
    });

    test('OvertimeScheduleInfoModel and OvertimeAttendanceInfoModel', () {
      final schedJson = {
        'id': 'sched-01',
        'workDate': '2026-10-12',
        'isDayOff': false,
        'shift': {
          'id': 'shift-01',
          'startTime': '08:00:00',
          'endTime': '17:00:00',
        },
      };

      final sched = OvertimeScheduleInfoModel.fromJson(schedJson);
      expect(sched.id, 'sched-01');
      expect(sched.workDate, '2026-10-12');
      expect(sched.isDayOff, false);
      expect(sched.shift?.id, 'shift-01');
      expect(sched.toJson()['id'], 'sched-01');

      final attJson = {
        'id': 'att-01',
        'checkIn': '07:55:00',
        'checkOut': '17:05:00',
      };
      final att = OvertimeAttendanceInfoModel.fromJson(attJson);
      expect(att.id, 'att-01');
      expect(att.checkIn, '07:55:00');
      expect(att.checkOut, '17:05:00');
      expect(att.toJson()['id'], 'att-01');
    });

    test('OvertimeScheduleData helper properties and time parsing', () {
      final baseDate = DateTime(2026, 10, 12);
      final json = {
        'isGenerated': true,
        'isDayOff': false,
        'requiresCheckOut': true,
        'workScheduleId': 'ws-101',
        'schedule': {
          'id': 'sched-01',
          'workDate': '2026-10-12',
          'shift': {
            'id': 'shift-01',
            'startTime': '08:00:00',
            'endTime': '17:00:00',
          },
        },
        'attendance': {
          'id': 'att-01',
          'checkIn': '08:00:00',
          'checkOut': '17:15:00',
        },
        'message': 'OK',
      };

      final data = OvertimeScheduleData.fromJson(json);
      expect(data.isGenerated, true);
      expect(data.hasSchedule, true);
      expect(data.isMissingCheckOut, false);
      expect(data.effectiveWorkScheduleId, 'ws-101');

      final parsedStart = data.parsedShiftStartTime(baseDate);
      expect(parsedStart?.hour, 8);
      expect(parsedStart?.minute, 0);

      final parsedEnd = data.parsedShiftEndTime(baseDate);
      expect(parsedEnd?.hour, 17);
      expect(parsedEnd?.minute, 0);

      final parsedCheckOut = data.parsedCheckOutDateTime(baseDate);
      expect(parsedCheckOut?.hour, 17);
      expect(parsedCheckOut?.minute, 15);

      // Missing check-out check
      const missingCheckoutData = OvertimeScheduleData(
        workScheduleId: 'ws-102',
        attendance: OvertimeAttendanceInfoModel(id: 'att-02', checkIn: '08:00:00', checkOut: null),
      );
      expect(missingCheckoutData.isMissingCheckOut, true);
    });

    test('OvertimeScheduleResponse and CreateOvertimeResultModel', () {
      final respJson = {
        'success': true,
        'message': 'Schedule loaded',
        'data': {
          'isDayOff': false,
          'workScheduleId': 'ws-01',
        },
      };

      final resp = OvertimeScheduleResponse.fromJson(respJson);
      expect(resp.success, true);
      expect(resp.data.workScheduleId, 'ws-01');

      final resultJson = {
        'success': true,
        'message': 'Overtime requested',
        'data': {'id': 'ot-999'},
      };
      final result = CreateOvertimeResultModel.fromJson(resultJson);
      expect(result.success, true);
      expect(result.id, 'ot-999');
      expect(result.message, 'Overtime requested');
    });
  });
}
