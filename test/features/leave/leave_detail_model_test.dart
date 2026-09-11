import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

void main() {
  group('LeaveRequestDetailModel Tests', () {
    final sampleJson = {
      "success": true,
      "message": "Detail leave request retrieved",
      "data": {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "startDate": "2026-09-11",
        "endDate": "2026-09-15",
        "totalDays": 5,
        "notes": "Medical checkup and dental treatment",
        "status": "requested",
        "leaveType": {
          "id": "lt-001",
          "name": "Sick Leave",
        },
        "employee": {
          "id": "emp-001",
          "firstName": "Sarah",
          "lastName": "Jenkins",
          "email": "sarah.j@oasish.com",
          "phone": "08123456789",
          "idNumber": "3171234567890001",
          "employeeNumber": "EMP-001",
          "company": {
            "id": "comp-001",
            "name": "Oasish Tech",
          },
          "department": {
            "id": "dept-001",
            "name": "Engineering",
            "code": "ENG",
          },
          "position": {
            "id": "pos-001",
            "name": "Frontend Engineer",
            "code": "FE",
          },
          "photoUrl": "https://example.com/avatar.jpg",
        },
        "approver": {
          "id": "app-001",
          "firstName": "Alex",
          "lastName": "Rivera",
          "email": "alex.r@oasish.com",
          "phone": "08198765432",
          "idNumber": null,
          "employeeNumber": "EMP-002",
          "company": {
            "id": "comp-001",
            "name": "Oasish Tech",
          },
          "department": {
            "id": "dept-001",
            "name": "Engineering",
            "code": "ENG",
          },
          "position": {
            "id": "pos-002",
            "name": "Engineering Manager",
            "code": "EM",
          },
          "photoUrl": null,
        },
        "filePath": "/uploads/doctor_note.jpg",
        "approverNotes": "Approved by manager",
      }
    };

    test('LeaveRequestDetailResponse parses valid JSON with all fields', () {
      final response = LeaveRequestDetailResponse.fromJson(sampleJson);

      expect(response.success, isTrue);
      expect(response.message, 'Detail leave request retrieved');

      final data = response.data;
      expect(data.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(data.totalDays, 5);
      expect(data.notes, 'Medical checkup and dental treatment');
      expect(data.status, 'requested');
      expect(data.isPending, isTrue);
      expect(data.isApproved, isFalse);
      expect(data.isRejected, isFalse);
      expect(data.statusLabel, 'Pending Approval');
      expect(data.durationLabel, '5 Work Day(s)');

      // Leave Type
      expect(data.leaveType.id, 'lt-001');
      expect(data.leaveType.name, 'Sick Leave');

      // Employee
      expect(data.employee.id, 'emp-001');
      expect(data.employee.fullName, 'Sarah Jenkins');
      expect(data.employee.initials, 'SJ');
      expect(data.employee.email, 'sarah.j@oasish.com');
      expect(data.employee.company?.name, 'Oasish Tech');
      expect(data.employee.department?.name, 'Engineering');
      expect(data.employee.position?.name, 'Frontend Engineer');

      // Approver
      expect(data.approver, isNotNull);
      expect(data.approver?.id, 'app-001');
      expect(data.approver?.fullName, 'Alex Rivera');
      expect(data.approver?.initials, 'AR');
      expect(data.approver?.position?.name, 'Engineering Manager');
      expect(data.approverNotes, 'Approved by manager');

      // File
      expect(data.filePath, '/uploads/doctor_note.jpg');
    });

    test('Parses correctly when approver, filePath, and notes are null', () {
      final jsonWithNulls = {
        "success": true,
        "message": "OK",
        "data": {
          "id": "123e4567",
          "startDate": "2026-09-11",
          "endDate": "2026-09-11",
          "totalDays": 1,
          "notes": null,
          "status": "approved",
          "leaveType": {"id": "lt-1", "name": "Annual Leave"},
          "employee": {
            "id": "emp-1",
            "firstName": "Budi",
            "lastName": null,
            "email": "budi@oasish.com",
            "company": {"id": "c1", "name": "PT Maju"},
          },
          "approver": null,
          "filePath": null,
          "approverNotes": null,
        }
      };

      final response = LeaveRequestDetailResponse.fromJson(jsonWithNulls);
      final data = response.data;

      expect(data.approver, isNull);
      expect(data.filePath, isNull);
      expect(data.notes, isNull);
      expect(data.employee.fullName, 'Budi');
      expect(data.employee.initials, 'BU');
      expect(data.isApproved, isTrue);
      expect(data.statusLabel, 'Approved');
      expect(data.durationLabel, '1 Work Day(s)');
      expect(data.formattedDateRange, contains('11'));
      expect(data.formattedDateRange, contains('2026'));
    });

    test('Status rejection mapping and copyWith works correctly', () {
      final model = LeaveRequestDetailData(
        id: '123',
        status: 'rejected',
        leaveType: const LeaveTypeDetailModel(id: '1', name: 'Sick'),
        employee: const LeaveEmployeeDetailModel(id: '1', firstName: 'John'),
      );

      expect(model.isRejected, isTrue);
      expect(model.statusLabel, 'Rejected');

      final updated = model.copyWith(
        status: 'approved',
        approverNotes: 'Updated notes',
      );
      expect(updated.isApproved, isTrue);
      expect(updated.statusLabel, 'Approved');
      expect(updated.approverNotes, 'Updated notes');
    });
  });
}
