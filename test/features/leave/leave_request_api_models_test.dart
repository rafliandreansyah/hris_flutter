import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';

void main() {
  group('Leave Request API Models Tests', () {
    test('LeavePaginationMeta fromJson and toJson', () {
      final json = {
        'page': 3,
        'limit': 10,
        'total': 25,
        'totalPages': 3,
      };

      final meta = LeavePaginationMeta.fromJson(json);
      expect(meta.page, 3);
      expect(meta.limit, 10);
      expect(meta.total, 25);
      expect(meta.totalPages, 3);

      final out = meta.toJson();
      expect(out['page'], 3);
      expect(out['limit'], 10);
      expect(out['total'], 25);
      expect(out['totalPages'], 3);

      final defaultMeta = LeavePaginationMeta.fromJson({});
      expect(defaultMeta.page, 1);
      expect(defaultMeta.limit, 30);
      expect(defaultMeta.total, 0);
      expect(defaultMeta.totalPages, 1);
    });

    test('Leave Master Models (Company, Department, Position, LeaveType)', () {
      final comp = LeaveCompanyModel.fromJson({'id': 'c1', 'name': 'Oasish Corp'});
      expect(comp.id, 'c1');
      expect(comp.name, 'Oasish Corp');

      final dept = LeaveDepartmentModel.fromJson({'id': 'd1', 'name': 'Finance'});
      expect(dept.id, 'd1');
      expect(dept.name, 'Finance');

      final pos = LeavePositionModel.fromJson({'id': 'p1', 'name': 'Accountant'});
      expect(pos.id, 'p1');
      expect(pos.name, 'Accountant');

      final type = LeaveTypeModel.fromJson({'id': 'lt1', 'name': 'Annual Leave'});
      expect(type.id, 'lt1');
      expect(type.name, 'Annual Leave');

      // Empty fallbacks
      expect(LeaveCompanyModel.fromJson({}).id, '');
      expect(LeaveDepartmentModel.fromJson({}).name, '');
      expect(LeavePositionModel.fromJson({}).id, '');
      expect(LeaveTypeModel.fromJson({}).name, '');
    });

    test('LeaveEmployeeModel fields, fullName, and initials', () {
      final json = {
        'id': 'emp-01',
        'firstName': 'Dewi',
        'lastName': 'Lestari',
        'email': 'dewi@oasish.app',
        'phone': '081333444555',
        'idNumber': '3172000000',
        'employeeNumber': 'EMP-007',
        'photoUrl': 'uploads/dewi.jpg',
        'company': {'id': 'c1', 'name': 'Oasish Corp'},
        'department': {'id': 'd1', 'name': 'HR'},
        'position': {'id': 'p1', 'name': 'HR Specialist'},
      };

      final emp = LeaveEmployeeModel.fromJson(json);
      expect(emp.id, 'emp-01');
      expect(emp.firstName, 'Dewi');
      expect(emp.lastName, 'Lestari');
      expect(emp.fullName, 'Dewi Lestari');
      expect(emp.initials, 'DL');
      expect(emp.email, 'dewi@oasish.app');
      expect(emp.company?.name, 'Oasish Corp');
      expect(emp.department?.name, 'HR');
      expect(emp.position?.name, 'HR Specialist');

      // Single word name
      final single = LeaveEmployeeModel.fromJson({
        'id': 'emp-02',
        'firstName': 'Suharto',
      });
      expect(single.fullName, 'Suharto');
      expect(single.initials, 'SU');

      // Empty name
      final empty = LeaveEmployeeModel.fromJson({
        'id': 'emp-03',
        'firstName': '',
      });
      expect(empty.fullName, '');
      expect(empty.initials, '?');
    });

    test('LeaveRequestApiModel parsing and fallback fields', () {
      final json = {
        'id': 'lr-1',
        'employee': {
          'id': 'emp-01',
          'firstName': 'Rina',
          'lastName': 'Wati',
        },
        'leaveType': {
          'id': 'lt-1',
          'name': 'Sick Leave',
        },
        'startDate': '2026-10-15T00:00:00Z',
        'endDate': '2026-10-16T00:00:00Z',
        'totalDays': 2,
        'reason': 'Flu and fever',
        'status': 'approved',
        'timezone': 'WIB',
      };

      final model = LeaveRequestApiModel.fromJson(json);
      expect(model.id, 'lr-1');
      expect(model.employee?.fullName, 'Rina Wati');
      expect(model.leaveType?.name, 'Sick Leave');
      expect(model.startDate, isNotNull);
      expect(model.endDate, isNotNull);
      expect(model.days, 2);
      expect(model.note, 'Flu and fever');
      expect(model.statusApprove, 'approved');
      expect(model.timezone, 'WIB');

      // Fallback for null dates and empty fields
      final emptyModel = LeaveRequestApiModel.fromJson({
        'id': 'lr-2',
        'startDate': null,
        'endDate': '',
        'days': 1,
      });
      expect(emptyModel.startDate, isNull);
      expect(emptyModel.endDate, isNull);
      expect(emptyModel.days, 1);
      expect(emptyModel.note, '');
    });

    test('leaveRequestItemFromApiJson mapping for My Requests and Team Requests', () {
      final json = {
        'id': 'lr-10',
        'employee': {
          'id': 'emp-05',
          'firstName': 'Fajar',
          'lastName': 'Nugraha',
          'employeeNumber': 'EMP-05',
          'position': {'id': 'p1', 'name': 'Backend Engineer'},
          'department': {'id': 'd1', 'name': 'IT'},
          'company': {'id': 'c1', 'name': 'Oasish Tech'},
        },
        'leaveType': {'id': 'lt-1', 'name': 'Annual Leave'},
        'startDate': '2026-11-01',
        'endDate': '2026-11-03',
        'totalDays': 3,
        'notes': 'Family holiday',
        'status': 'approved',
      };

      // Approver perspective
      final itemApprover = leaveRequestItemFromApiJson(json, isApprover: true);
      expect(itemApprover.id, 'lr-10');
      expect(itemApprover.name, 'Fajar Nugraha');
      expect(itemApprover.role, 'Backend Engineer');
      expect(itemApprover.department, 'IT');
      expect(itemApprover.company, 'Oasish Tech');
      expect(itemApprover.leaveType, 'Annual Leave');
      expect(itemApprover.days, 3);
      expect(itemApprover.status, LeaveStatus.approved);
      expect(itemApprover.isSelf, false);

      // Self perspective without employee info (fallback to 'Saya')
      final itemSelf = leaveRequestItemFromApiJson(
        {
          'id': 'lr-11',
          'status': 'rejected',
          'notes': 'No quota left',
        },
        isApprover: false,
      );
      expect(itemSelf.name, 'Saya');
      expect(itemSelf.isSelf, true);
      expect(itemSelf.status, LeaveStatus.rejected);

      // Status variations
      final reqItem = leaveRequestItemFromApiJson({'id': '1', 'status': 'requested'});
      expect(reqItem.status, LeaveStatus.requested);

      final pendItem = leaveRequestItemFromApiJson({'id': '2', 'status': 'pending'});
      expect(pendItem.status, LeaveStatus.pending);
    });

    test('LeaveRequestListResponse fromJson and toJson', () {
      final json = {
        'success': true,
        'message': 'Success',
        'data': [
          {
            'id': 'lr-1',
            'status': 'approved',
          }
        ],
        'meta': {
          'page': 1,
          'limit': 10,
          'total': 1,
          'totalPages': 1,
        }
      };

      final resp = LeaveRequestListResponse.fromJson(json);
      expect(resp.success, true);
      expect(resp.data.length, 1);
      expect(resp.meta.total, 1);

      final out = resp.toJson();
      expect(out['success'], true);
      expect((out['data'] as List).length, 1);
      expect(out['meta']['total'], 1);
    });
  });

  group('Leave Presentation Models & Formatters Tests', () {
    test('LeaveStatusExtension token styling and labels', () {
      for (final s in LeaveStatus.values) {
        expect(s.label.isNotEmpty, true);
        expect(s.textColor, isNotNull);
        expect(s.backgroundColor, isNotNull);
        expect(s.dotColor, isNotNull);
      }
      expect(LeaveStatus.pending.label, 'Pending');
      expect(LeaveStatus.approved.label, 'Approved');
      expect(LeaveStatus.rejected.label, 'Rejected');
    });

    test('LeaveRequestItem formatters, durationLabel, dateRangeLabel, and copyWith', () {
      final itemSingleDay = LeaveRequestItem(
        id: 'item-1',
        name: 'Andi',
        initials: 'AN',
        leaveType: 'Annual Leave',
        days: 1,
        startDate: DateTime(2026, 10, 15),
        endDate: DateTime(2026, 10, 15),
      );

      expect(itemSingleDay.durationLabel, '1 Day');
      expect(itemSingleDay.dateRangeLabel, '15 Okt 2026');
      expect(itemSingleDay.note, '');

      final itemMultiDay = LeaveRequestItem(
        id: 'item-2',
        name: 'Andi',
        initials: 'AN',
        leaveType: 'Annual Leave',
        days: 3,
        startDate: DateTime(2026, 10, 15),
        endDate: DateTime(2026, 10, 17),
      );
      expect(itemMultiDay.durationLabel, '3 Days');
      expect(itemMultiDay.dateRangeLabel, '15 Okt 2026 - 17 Okt 2026');

      final copied = itemMultiDay.copyWith(
        days: 4,
        status: LeaveStatus.approved,
      );
      expect(copied.id, 'item-2');
      expect(copied.days, 4);
      expect(copied.status, LeaveStatus.approved);
      expect(copied.props, isNotEmpty);

      // Null dates check
      const itemNoDates = LeaveRequestItem(
        id: 'item-3',
        name: 'Budi',
        initials: 'BU',
        leaveType: 'Leave',
      );
      expect(itemNoDates.dateRangeLabel, '-');
    });
  });
}
