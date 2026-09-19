import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';

void main() {
  group('AttendanceRequestItem Unit Tests', () {
    test('isIn, isOut, and isInOut identify attendanceType correctly', () {
      const itemIn = AttendanceRequestItem(
        id: '1',
        name: 'John',
        attendanceType: 'in',
        startTime: '08:30',
      );
      expect(itemIn.isIn, isTrue);
      expect(itemIn.isOut, isFalse);
      expect(itemIn.isInOut, isFalse);
      expect(itemIn.attendanceTypeBadge, 'IN');
      expect(itemIn.attendanceTypeLabel, 'Presensi Masuk');

      const itemOut = AttendanceRequestItem(
        id: '2',
        name: 'Jane',
        attendanceType: 'out',
        endTime: '17:00',
      );
      expect(itemOut.isIn, isFalse);
      expect(itemOut.isOut, isTrue);
      expect(itemOut.isInOut, isFalse);
      expect(itemOut.attendanceTypeBadge, 'OUT');
      expect(itemOut.attendanceTypeLabel, 'Presensi Pulang');

      const itemInOut = AttendanceRequestItem(
        id: '3',
        name: 'Bob',
        attendanceType: 'inout',
        startTime: '08:00',
        endTime: '17:00',
      );
      expect(itemInOut.isIn, isFalse);
      expect(itemInOut.isOut, isFalse);
      expect(itemInOut.isInOut, isTrue);
      expect(itemInOut.attendanceTypeBadge, 'IN & OUT');
      expect(itemInOut.attendanceTypeLabel, 'Presensi Masuk & Pulang');
    });

    test('formattedWorkHours formats correctly for in, out, and inout', () {
      const itemIn = AttendanceRequestItem(
        id: '1',
        name: 'John',
        attendanceType: 'in',
        startTime: '08:30',
        timezone: 'WIB',
      );
      expect(itemIn.formattedWorkHours, 'Jam Masuk: 08:30 WIB');

      const itemOut = AttendanceRequestItem(
        id: '2',
        name: 'Jane',
        attendanceType: 'out',
        endTime: '17:00',
        timezone: 'WIB',
      );
      expect(itemOut.formattedWorkHours, 'Jam Pulang: 17:00 WIB');

      const itemInOut = AttendanceRequestItem(
        id: '3',
        name: 'Bob',
        attendanceType: 'inout',
        startTime: '08:00',
        endTime: '17:00',
        timezone: 'WIB',
      );
      expect(itemInOut.formattedWorkHours, 'Masuk 08:00 • Pulang 17:00 WIB');
    });

    test('formattedDate falls back gracefully when date is null', () {
      final item = AttendanceRequestItem(
        id: '1',
        name: 'John',
        attendanceInTime: DateTime(2026, 9, 18, 8, 30),
      );
      expect(item.formattedDate, '18 September 2026');
    });
  });

  group('AttendanceRequestApiModel & JSON Parsing Tests', () {
    test('parses new API response with attendanceInTime and attendanceOutTime', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'employee': {
          'id': 'emp-1',
          'firstName': 'Budi',
          'lastName': 'Santoso',
          'email': 'budi@example.com',
          'phone': '08123456789',
          'company': {'id': 'c1', 'name': 'PT Muratech'},
          'department': {'id': 'd1', 'name': 'Engineering'},
          'position': {'id': 'p1', 'name': 'Software Engineer'},
        },
        'status': 'requested',
        'reason': 'Kunjungan ke klien Jakarta',
        'attendanceType': 'in',
        'attendanceTime': null,
        'attendanceInTime': '2026-09-18T08:30:00.000Z',
        'attendanceOutTime': null,
        'approverNote': null,
        'createdAt': '2026-09-18T13:52:30.636Z',
        'timezone': 'WIB',
      };

      final item = attendanceRequestItemFromApiJson(json, isApprover: true);
      expect(item.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(item.name, 'Budi Santoso');
      expect(item.notes, 'Kunjungan ke klien Jakarta');
      expect(item.attendanceType, 'in');
      expect(item.isIn, isTrue);
      expect(item.attendanceTypeBadge, 'IN');
      expect(item.startTime, isNotNull);
      expect(item.formattedWorkHours, contains('Jam Masuk:'));
      expect(item.formattedDate, isNotEmpty);
    });

    test('parses out request and inout request correctly', () {
      final jsonOut = {
        'id': 'out-1',
        'status': 'approved',
        'reason': 'Pulang lebih awal',
        'attendanceType': 'out',
        'attendanceInTime': null,
        'attendanceOutTime': '2026-09-18T17:00:00.000Z',
        'timezone': 'WIB',
      };
      final itemOut = attendanceRequestItemFromApiJson(jsonOut);
      expect(itemOut.isOut, isTrue);
      expect(itemOut.attendanceTypeBadge, 'OUT');
      expect(itemOut.formattedWorkHours, contains('Jam Pulang:'));

      final jsonInOut = {
        'id': 'inout-1',
        'status': 'requested',
        'reason': 'Luar kantor seharian',
        'attendanceType': 'inout',
        'attendanceInTime': '2026-09-18T08:00:00.000Z',
        'attendanceOutTime': '2026-09-18T17:00:00.000Z',
        'timezone': 'WIB',
      };
      final itemInOut = attendanceRequestItemFromApiJson(jsonInOut);
      expect(itemInOut.isInOut, isTrue);
      expect(itemInOut.attendanceTypeBadge, 'IN & OUT');
      expect(itemInOut.formattedWorkHours, contains('Masuk'));
      expect(itemInOut.formattedWorkHours, contains('Pulang'));
    });
  });

  group('AttendanceRequestDetailData Unit Tests', () {
    test('parses new detail API schema correctly with out fields', () {
      final json = {
        'id': 'detail-123',
        'employee': {
          'id': 'emp-1',
          'firstName': 'Siti',
          'lastName': 'Rahma',
          'email': 'siti@example.com',
          'company': {'id': 'c1', 'name': 'PT Muratech'},
        },
        'approver': {
          'id': 'app-1',
          'firstName': 'Ahmad',
          'lastName': 'Manager',
        },
        'status': 'requested',
        'method': 'photo',
        'reason': 'Dinas Luar',
        'attendanceType': 'inout',
        'attendanceTime': null,
        'attendanceInTime': '2026-09-18T08:30:00.000Z',
        'attendanceOutTime': '2026-09-18T17:30:00.000Z',
        'approverNote': 'Catatan approver',
        'filePath': 'https://example.com/in.jpg',
        'latitude': -6.200000,
        'longitude': 106.816666,
        'address': 'Kantor Klien A',
        'filePathOut': 'https://example.com/out.jpg',
        'latitudeOut': -6.210000,
        'longitudeOut': 106.820000,
        'addressOut': 'Kantor Klien B',
        'createdAt': '2026-09-18T13:52:30.636Z',
        'timezone': 'WIB',
      };

      final detail = AttendanceRequestDetailData.fromJson(json);
      expect(detail.id, 'detail-123');
      expect(detail.isInOut, isTrue);
      expect(detail.isIn, isFalse);
      expect(detail.isOut, isFalse);
      expect(detail.attendanceTypeBadge, 'IN & OUT');
      expect(detail.attendanceTypeLabel, 'Presensi Masuk & Pulang');
      expect(detail.filePath, 'https://example.com/in.jpg');
      expect(detail.filePathOut, 'https://example.com/out.jpg');
      expect(detail.latitude, -6.200000);
      expect(detail.latitudeOut, -6.210000);
      expect(detail.hasValidCoordinates, isTrue);
      expect(detail.hasValidCoordinatesOut, isTrue);
      expect(detail.address, 'Kantor Klien A');
      expect(detail.addressOut, 'Kantor Klien B');
      expect(detail.approverNote, 'Catatan approver');
    });

    test('parses in and out types with time fallback correctly', () {
      final jsonIn = {
        'id': 'in-1',
        'status': 'requested',
        'method': 'photo',
        'attendanceType': 'in',
        'attendanceTime': '2026-09-18T08:15:00.000Z',
        'attendanceInTime': null,
        'timezone': 'WIB',
      };
      final detailIn = AttendanceRequestDetailData.fromJson(jsonIn);
      expect(detailIn.isIn, isTrue);
      expect(detailIn.isOut, isFalse);
      expect(detailIn.formattedInTime, isNot('-'));

      final jsonOut = {
        'id': 'out-1',
        'status': 'requested',
        'method': 'photo',
        'attendanceType': 'out',
        'attendanceTime': '2026-09-18T17:15:00.000Z',
        'attendanceOutTime': null,
        'timezone': 'WIB',
      };
      final detailOut = AttendanceRequestDetailData.fromJson(jsonOut);
      expect(detailOut.isIn, isFalse);
      expect(detailOut.isOut, isTrue);
      expect(detailOut.formattedOutTime, isNot('-'));
    });
  });
}
