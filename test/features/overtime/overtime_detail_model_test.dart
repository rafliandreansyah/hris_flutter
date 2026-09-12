import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';

void main() {
  group('OvertimeDetailModel Tests', () {
    final sampleJson = {
      "success": true,
      "message": "Detail overtime request retrieved",
      "data": {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "startOvertime": "2026-08-28T17:00:00.000Z",
        "endOvertime": "2026-08-28T21:00:00.000Z",
        "notes": "Deploying critical microservice updates and running post-migration sanity tests.",
        "status": "requested",
        "employee": {
          "id": "emp-001",
          "firstName": "Sarah",
          "lastName": "Jenkins",
          "email": "sarah.j@oasish.com",
          "phone": "08123456789",
          "idNumber": "3171234567890001",
          "employeeNumber": "EMP-2024-019",
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
          "employeeNumber": "EMP-2024-002",
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
        "filePath": "/uploads/overtime_proof.jpg",
        "approverNotes": "Great work on deployment",
        "timezone": "WIB",
        "createdAt": "2026-08-28T09:33:00.000Z",
      }
    };

    test('OvertimeDetailResponse parses valid JSON correctly', () {
      final response = OvertimeDetailResponse.fromJson(sampleJson);

      expect(response.success, isTrue);
      expect(response.message, 'Detail overtime request retrieved');

      final data = response.data;
      expect(data.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(data.status, 'requested');
      expect(data.notes, contains('Deploying critical microservice updates'));
      expect(data.employee.fullName, 'Sarah Jenkins');
      expect(data.employee.position?.name, 'Frontend Engineer');
      expect(data.employee.department?.name, 'Engineering');
      expect(data.employee.employeeNumber, 'EMP-2024-019');
      expect(data.approver?.fullName, 'Alex Rivera');
      expect(data.approver?.position?.name, 'Engineering Manager');
      expect(data.approverNotes, 'Great work on deployment');
      expect(data.filePath, '/uploads/overtime_proof.jpg');
      expect(data.timezone, 'WIB');
    });

    test('Status helpers strictly handle requested, approved, rejected', () {
      final requestedData = OvertimeDetailData.fromJson({
        "id": "1",
        "status": "requested",
      });
      expect(requestedData.isRequested, isTrue);
      expect(requestedData.isPending, isTrue);
      expect(requestedData.isApproved, isFalse);
      expect(requestedData.isRejected, isFalse);
      expect(requestedData.statusLabel, 'Pending Approval');

      final approvedData = OvertimeDetailData.fromJson({
        "id": "2",
        "status": "approved",
      });
      expect(approvedData.isRequested, isFalse);
      expect(approvedData.isApproved, isTrue);
      expect(approvedData.isRejected, isFalse);
      expect(approvedData.statusLabel, 'Approved');

      final rejectedData = OvertimeDetailData.fromJson({
        "id": "3",
        "status": "rejected",
      });
      expect(rejectedData.isRequested, isFalse);
      expect(rejectedData.isApproved, isFalse);
      expect(rejectedData.isRejected, isTrue);
      expect(rejectedData.statusLabel, 'Rejected');
    });

    test('Duration calculations work accurately', () {
      final data = OvertimeDetailData(
        id: '1',
        startOvertime: DateTime(2026, 8, 28, 17, 0),
        endOvertime: DateTime(2026, 8, 28, 21, 0),
        status: 'requested',
        employee: const OvertimeEmployeeModel(
          id: 'emp-001',
          firstName: 'Sarah',
        ),
      );

      expect(data.durationHours, 4.0);
      expect(data.durationHoursLabel, '4 Jam Kerja');

      final halfHourData = OvertimeDetailData(
        id: '2',
        startOvertime: DateTime(2026, 8, 28, 17, 0),
        endOvertime: DateTime(2026, 8, 28, 20, 30),
        status: 'requested',
        employee: data.employee,
      );

      expect(halfHourData.durationHours, 3.5);
      expect(halfHourData.durationHoursLabel, '3.5 Jam Kerja');
    });

    test('Date and time range format helpers work correctly in Indonesian', () {
      final data = OvertimeDetailData(
        id: '1',
        startOvertime: DateTime(2026, 8, 28, 17, 0),
        endOvertime: DateTime(2026, 8, 28, 21, 0),
        status: 'requested',
        timezone: 'WIB',
        createdAt: DateTime(2026, 8, 28, 9, 33),
        employee: OvertimeDetailData.fromJson(sampleJson['data'] as Map<String, dynamic>).employee,
      );

      expect(data.formattedDate, '28 Agustus 2026');
      expect(data.formattedTimeRange, '17:00 - 21:00 WIB');
      expect(data.formattedCreatedAt, '28 Agustus 2026, 09:33 WIB');
    });

    test('OvertimeApprovePayload serializes correctly', () {
      const payloadApprove = OvertimeApprovePayload(
        isApproved: true,
        approverNotes: 'Approved by TL',
      );
      final jsonApprove = payloadApprove.toJson();
      expect(jsonApprove['isApproved'], isTrue);
      expect(jsonApprove['approverNotes'], 'Approved by TL');
      expect(jsonApprove['approverNote'], 'Approved by TL');

      const payloadReject = OvertimeApprovePayload(
        isApproved: false,
        approverNotes: 'Overtime quota exceeded',
      );
      final jsonReject = payloadReject.toJson();
      expect(jsonReject['isApproved'], isFalse);
      expect(jsonReject['approverNotes'], 'Overtime quota exceeded');
    });
  });
}
