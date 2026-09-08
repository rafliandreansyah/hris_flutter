import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';

void main() {
  group('AttendanceLogItem parsing', () {
    test('parses clock-in entry with on-time status', () {
      final item = AttendanceLogItem.fromJson({
        'id': 'LOG-1',
        'dateTime': '2026-08-27T08:45:00',
        'type': 'IN',
        'locationName': 'Jakarta HQ Office',
        'method': 'GPS Mobile',
        'lateMinutes': 0,
        'timezone': 'Asia/Jakarta',
      });

      expect(item.id, 'LOG-1');
      expect(item.type, AttendanceLogType.clockIn);
      expect(item.isLate, isFalse);
      expect(item.punctuality, AttendanceLogPunctuality.onTime);
      expect(item.locationName, 'Jakarta HQ Office');
      expect(item.method, 'GPS Mobile');
      expect(item.timezoneAbbreviation, 'WIB');
      expect(item.dateTime, DateTime(2026, 8, 27, 8, 45));
    });

    test('parses clock-out entry and late minutes', () {
      final outItem = AttendanceLogItem.fromJson({
        'id': 'LOG-2',
        'time': '2026-08-27T17:30:00',
        'type': 'OUT',
        'location': 'Jakarta HQ Office',
      });
      expect(outItem.type, AttendanceLogType.clockOut);
      expect(outItem.isLate, isFalse);

      final lateItem = AttendanceLogItem.fromJson({
        'id': 'LOG-3',
        'dateTime': '2026-08-26T09:18:00',
        'type': 'clock_in',
        'lateBy': 18,
        'timezone': 'Asia/Makassar',
      });
      expect(lateItem.type, AttendanceLogType.clockIn);
      expect(lateItem.isLate, isTrue);
      expect(lateItem.lateMinutes, 18);
      expect(lateItem.punctuality, AttendanceLogPunctuality.late);
      expect(lateItem.timezoneAbbreviation, 'WITA');
    });

    test('parses official API v1 attendances schema correctly', () {
      final item = AttendanceLogItem.fromJson({
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'date': '2026-09-08',
        'timezone': 'Asia/Jakarta',
        'attendanceType': 'CHECK_IN',
        'attendanceTime': '2026-09-08T14:15:23.229Z',
        'lateInMinutes': null,
        'attendanceMethod': 'GPS',
        'workLocation': {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'name': 'Head Office',
        },
      });

      expect(item.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(item.date, '2026-09-08');
      expect(item.timezone, 'Asia/Jakarta');
      expect(item.timezoneAbbreviation, 'WIB');
      expect(item.type, AttendanceLogType.clockIn);
      expect(item.locationName, 'Head Office');
      expect(item.locationId, '123e4567-e89b-12d3-a456-426614174000');
      expect(item.method, 'GPS');
      expect(item.lateMinutes, isNull);
      expect(item.isLate, isFalse);
      expect(item.punctuality, AttendanceLogPunctuality.onTime);
      expect(item.dateTime, DateTime.parse('2026-09-08T14:15:23.229Z').toLocal());
    });

    test('falls back to defaults for empty json', () {
      final item = AttendanceLogItem.fromJson(const {});
      expect(item.type, AttendanceLogType.clockIn);
      expect(item.locationName, isNull);
      expect(item.method, isNull);
      expect(item.lateMinutes, isNull);
      expect(item.timezoneAbbreviation, 'WIB');
    });
  });

  group('AttendanceLogListResponse parsing', () {
    test('parses flat data list with meta', () {
      final response = AttendanceLogListResponse.fromJson({
        'success': true,
        'message': 'ok',
        'data': [
          {'id': 'A', 'dateTime': '2026-08-27T08:45:00', 'type': 'IN'},
          {'id': 'B', 'dateTime': '2026-08-27T17:30:00', 'type': 'OUT'},
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 42, 'totalPages': 3},
      });

      expect(response.success, isTrue);
      expect(response.data.length, 2);
      expect(response.meta.page, 1);
      expect(response.meta.totalPages, 3);
    });

    test('parses nested data.logs payload', () {
      final response = AttendanceLogListResponse.fromJson({
        'data': {
          'logs': [
            {'id': 'C', 'dateTime': '2026-08-27T08:45:00', 'type': 'IN'},
          ],
          'meta': {'page': 2, 'totalPages': 4},
        },
      });

      expect(response.data.length, 1);
      expect(response.meta.page, 2);
      expect(response.meta.totalPages, 4);
    });

    test('parses flat list response without meta key and infers meta from data length', () {
      final response = AttendanceLogListResponse.fromJson({
        'success': true,
        'message': 'success',
        'data': [
          {
            'id': '123e4567-e89b-12d3-a456-426614174000',
            'date': '2026-09-08',
            'timezone': 'Asia/Jakarta',
            'attendanceType': 'CHECK_IN',
            'attendanceTime': '2026-09-08T14:15:23.229Z',
            'lateInMinutes': null,
            'attendanceMethod': 'GPS',
            'workLocation': {
              'id': '123e4567-e89b-12d3-a456-426614174000',
              'name': 'Office',
            },
          },
        ],
      });

      expect(response.success, isTrue);
      expect(response.data.length, 1);
      expect(response.meta.total, 1);
      expect(response.meta.totalPages, 1);
      expect(response.data.first.locationName, 'Office');
    });

    test('handles missing payload gracefully', () {
      final response = AttendanceLogListResponse.fromJson(const {});
      expect(response.data, isEmpty);
      expect(response.meta.totalPages, 1);
    });
  });

  group('AttendanceLogSummary parsing', () {
    test('parses primary keys', () {
      final summary = AttendanceLogSummary.fromJson({
        'totalInDays': 22,
        'presentPercentage': 100,
        'lateMinutes': 15,
        'lateCount': 0,
      });

      expect(summary.totalInDays, 22);
      expect(summary.presentPercentage, 100);
      expect(summary.lateMinutes, 15);
      expect(summary.lateCount, 0);
    });

    test('parses nested data with alternative keys', () {
      final summary = AttendanceLogSummary.fromJson({
        'data': {
          'totalIn': '18',
          'attendancePercentage': '95.5',
          'totalLateMinutes': 30,
          'lateRecords': 2,
        },
      });

      expect(summary.totalInDays, 18);
      expect(summary.presentPercentage, 95.5);
      expect(summary.lateMinutes, 30);
      expect(summary.lateCount, 2);
    });

    test('empty constant has zero values', () {
      expect(AttendanceLogSummary.empty.totalInDays, 0);
      expect(AttendanceLogSummary.empty.lateMinutes, 0);
    });
  });
}
