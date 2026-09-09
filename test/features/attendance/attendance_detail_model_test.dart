import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';

void main() {
  group('AttendanceDetailModel', () {
    final mockJson = {
      "success": true,
      "message": "Success get attendance detail",
      "data": {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "attendanceType": "Clock In",
        "attendanceTime": "2026-09-09T05:40:52.171Z",
        "attendanceMethod": "Photo Face Verification",
        "employee": {
          "id": "emp-uuid-001",
          "firstName": "John",
          "lastName": "Doe",
          "photoUrl": "https://example.com/photo.jpg",
          "company": "PT Oasish Tech",
          "department": "Engineering",
          "position": "Senior Flutter Developer",
          "level": "L4"
        },
        "latitude": -6.2088,
        "longitude": 106.8456,
        "workLocation": {
          "id": "loc-uuid-001",
          "name": "Head Office Jakarta"
        },
        "address": "Jl. Jendral Sudirman No. 10, Jakarta Pusat",
        "filePath": "https://example.com/attendance/proof_123.jpg",
        "attendanceRequestId": "REQ-2026-09-001",
        "lateInMinutes": 15,
        "workDate": "2026-09-09",
        "shift": {
          "id": "shift-uuid-001",
          "name": "Morning Shift",
          "startTime": "08:00",
          "endTime": "17:00"
        },
        "timezone": "WIB"
      }
    };

    test('should parse fromJson correctly with full payload', () {
      final data = mockJson['data'] as Map<String, dynamic>;
      final model = AttendanceDetailModel.fromJson(data);

      expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.attendanceType, 'Clock In');
      expect(model.isClockIn, isTrue);
      expect(model.isLate, isTrue);
      expect(model.lateInMinutes, 15);
      expect(model.hasAttendanceRequest, isTrue);
      expect(model.attendanceRequestId, 'REQ-2026-09-001');
      expect(model.isPhotoMethod, isTrue);
      expect(model.filePath, 'https://example.com/attendance/proof_123.jpg');
      expect(model.timezone, 'WIB');

      // Nested employee
      expect(model.employee?.fullName, 'John Doe');
      expect(model.employee?.company, 'PT Oasish Tech');
      expect(model.employee?.position, 'Senior Flutter Developer');
      expect(model.employee?.level, 'L4');

      // Nested work location & shift
      expect(model.workLocation?.name, 'Head Office Jakarta');
      expect(model.shift?.name, 'Morning Shift');
      expect(model.shift?.timeRange, '08:00 - 17:00');

      // Coordinates
      expect(model.latitude, -6.2088);
      expect(model.longitude, 106.8456);
      expect(model.coordinateDisplay, '-6.208800, 106.845600');

      // 24-hour format
      expect(model.formattedTime24.length, 8); // e.g. "05:40:52" or local representation
      expect(model.formattedTime24.contains(':'), isTrue);
    });

    test('hasAttendanceRequest should be false when attendanceRequestId is null or empty', () {
      final model1 = AttendanceDetailModel(
        id: '1',
        attendanceType: 'Clock In',
        attendanceMethod: 'Biometric',
        attendanceRequestId: null,
      );
      expect(model1.hasAttendanceRequest, isFalse);

      final model2 = AttendanceDetailModel(
        id: '2',
        attendanceType: 'Clock In',
        attendanceMethod: 'Biometric',
        attendanceRequestId: '   ',
      );
      expect(model2.hasAttendanceRequest, isFalse);
    });

    test('isPhotoMethod should be false if method does not contain photo or filePath is null', () {
      final modelWithoutFile = AttendanceDetailModel(
        id: '1',
        attendanceType: 'Clock In',
        attendanceMethod: 'Photo Scan',
        filePath: null,
      );
      expect(modelWithoutFile.isPhotoMethod, isFalse);

      final modelWithoutPhotoMethod = AttendanceDetailModel(
        id: '2',
        attendanceType: 'Clock In',
        attendanceMethod: 'Fingerprint',
        filePath: 'https://example.com/file.jpg',
      );
      expect(modelWithoutPhotoMethod.isPhotoMethod, isFalse);
    });

    test('toJson and fromJson roundtrip serialization', () {
      final data = mockJson['data'] as Map<String, dynamic>;
      final model = AttendanceDetailModel.fromJson(data);
      final jsonOutput = model.toJson();

      final reconstructed = AttendanceDetailModel.fromJson(jsonOutput);
      expect(reconstructed, equals(model));
    });
  });
}
