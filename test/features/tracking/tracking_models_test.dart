import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';

void main() {
  group('TrackingConfigModel Tests', () {
    test('fromJson and toJson parse tracking config successfully', () {
      final json = {
        'hasAccess': true,
        'isTrackingEnabled': true,
        'attendance': {
          'enabled': true,
          'intervalMinutes': 10,
          'activeAttendanceId': 'att-123',
        },
        'activity': {
          'enabled': true,
          'intervalMinutes': 3,
          'activeActivityId': 'act-456',
        },
      };

      final model = TrackingConfigModel.fromJson(json);

      expect(model.hasAccess, isTrue);
      expect(model.isTrackingEnabled, isTrue);
      expect(model.attendance.enabled, isTrue);
      expect(model.attendance.intervalMinutes, equals(10));
      expect(model.attendance.activeSessionId, equals('att-123'));
      expect(model.activity.intervalMinutes, equals(3));
      expect(model.activity.activeSessionId, equals('act-456'));

      final serialized = model.toJson();
      expect(serialized['hasAccess'], isTrue);
      expect(serialized['attendance']['intervalMinutes'], equals(10));
      expect(model.props, equals([
        model.hasAccess,
        model.isTrackingEnabled,
        model.attendance,
        model.activity,
      ]));
    });

    test('TrackingSessionPolicy handles missing fields with default values', () {
      final policy = TrackingSessionPolicy.fromJson(const {});
      expect(policy.enabled, isFalse);
      expect(policy.intervalMinutes, equals(10));
      expect(policy.activeSessionId, isNull);
    });
  });

  group('TrackingLocationPoint & TrackingBatchPayload Tests', () {
    test('toLocalJson and fromLocalJson roundtrip preserved', () {
      final now = DateTime.utc(2026, 10, 7, 12, 0, 0);
      final point = TrackingLocationPoint(
        id: 'point-1',
        latitude: -6.2088,
        longitude: 106.8456,
        accuracy: 5.5,
        speed: 1.2,
        heading: 180.0,
        altitude: 20.0,
        batteryLevel: 85,
        isMock: false,
        isGpsOff: false,
        recordedAt: now,
      );

      final localMap = point.toLocalJson();
      final restored = TrackingLocationPoint.fromLocalJson(localMap);

      expect(restored.id, equals('point-1'));
      expect(restored.latitude, equals(-6.2088));
      expect(restored.longitude, equals(106.8456));
      expect(restored.accuracy, equals(5.5));
      expect(restored.batteryLevel, equals(85));
      expect(restored.recordedAt.toIso8601String(), equals(now.toIso8601String()));
      expect(restored, equals(point));
    });

    test('toApiJson formats payload omitting internal id', () {
      final point = TrackingLocationPoint(
        id: 'internal-id',
        latitude: -6.2088,
        longitude: 106.8456,
        recordedAt: DateTime.utc(2026, 10, 7, 12, 0, 0),
      );

      final apiJson = point.toApiJson();
      expect(apiJson.containsKey('id'), isFalse);
      expect(apiJson['latitude'], equals(-6.2088));
      expect(apiJson['isMock'], isFalse);
      expect(apiJson['isGpsOff'], isFalse);
    });

    test('TrackingBatchPayload toJson serializes locations list', () {
      final payload = TrackingBatchPayload(
        sourceType: 'attendance',
        referenceId: 'att-123',
        locations: [
          TrackingLocationPoint(
            id: 'pt-1',
            latitude: -6.1,
            longitude: 106.8,
            recordedAt: DateTime.utc(2026, 10, 7, 12, 0, 0),
          ),
        ],
      );

      final json = payload.toJson();
      expect(json['sourceType'], equals('attendance'));
      expect(json['referenceId'], equals('att-123'));
      expect((json['locations'] as List).length, equals(1));
      expect(payload.props, equals(['attendance', 'att-123', payload.locations]));
    });
  });

  group('TrackingLogItem Tests', () {
    test('fromJson and toJson serialize correctly', () {
      final json = {
        'id': 'log-1',
        'employeeId': 'emp-101',
        'sourceType': 'attendance',
        'attendanceId': 'att-123',
        'latitude': -6.2,
        'longitude': 106.8,
        'accuracy': 8.0,
        'batteryLevel': 90,
        'isMock': false,
        'recordedAt': '2026-10-07T10:00:00.000Z',
      };

      final log = TrackingLogItem.fromJson(json);
      expect(log.id, equals('log-1'));
      expect(log.employeeId, equals('emp-101'));
      expect(log.latitude, equals(-6.2));
      expect(log.batteryLevel, equals(90));

      final serialized = log.toJson();
      expect(serialized['id'], equals('log-1'));
      expect(serialized['latitude'], equals(-6.2));
    });

    test('TrackingLogItem parses list of logs from API response data', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'log-1',
            'employeeId': 'emp-1',
            'sourceType': 'attendance',
            'latitude': -6.2,
            'longitude': 106.8,
            'recordedAt': '2026-10-07T10:00:00.000Z',
          },
        ],
      };

      final dataList = (json['data'] as List)
          .map((e) => TrackingLogItem.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(dataList.length, equals(1));
      expect(dataList.first.id, equals('log-1'));
    });
  });

  group('LiveTrackingModel Tests', () {
    test('LiveTrackingSummary fromJson, toJson, and empty factory', () {
      final empty = LiveTrackingSummary.empty();
      expect(empty.totalTracked, equals(0));
      expect(empty.onlineCount, equals(0));

      final json = {
        'totalTracked': 12,
        'attendanceCount': 8,
        'activityCount': 4,
        'onlineCount': 10,
        'gpsOffCount': 1,
      };

      final summary = LiveTrackingSummary.fromJson(json);
      expect(summary.totalTracked, equals(12));
      expect(summary.activityCount, equals(4));
      expect(summary.onlineCount, equals(10));
      expect(summary.gpsOffCount, equals(1));
      expect(summary.toJson()['totalTracked'], equals(12));
    });

    test('LiveEmployeeLocation fromJson handles object and string nested positions', () {
      final json = {
        'employeeId': 'emp-1',
        'name': 'Budi Santoso',
        'employeeNumber': 'EMP001',
        'department': {'name': 'Engineering'},
        'position': {'name': 'Mobile Engineer'},
        'latitude': -6.2088,
        'longitude': 106.8456,
        'status': 'activity',
        'minutesSinceLastPing': 5,
        'isGpsOff': false,
        'session': {
          'type': 'activity',
          'id': 'act-99',
          'title': 'Kunjungan Klien A',
        },
      };

      final emp = LiveEmployeeLocation.fromJson(json);
      expect(emp.name, equals('Budi Santoso'));
      expect(emp.departmentName, equals('Engineering'));
      expect(emp.positionName, equals('Mobile Engineer'));
      expect(emp.isOnline, isTrue);
      expect(emp.session?.title, equals('Kunjungan Klien A'));
    });

    test('LiveEmployeeLocation marks offline when minutesSinceLastPing > 15', () {
      final json = {
        'employeeId': 'emp-2',
        'name': 'Siti Rahma',
        'employeeNumber': 'EMP002',
        'latitude': -6.2088,
        'longitude': 106.8456,
        'status': 'attendance',
        'minutesSinceLastPing': 25,
        'isOnline': false,
        'isGpsOff': true,
      };

      final emp = LiveEmployeeLocation.fromJson(json);
      expect(emp.isOnline, isFalse);
      expect(emp.isGpsOff, isTrue);
    });

    test('LiveTrackingResponse fromJson parses full response', () {
      final json = {
        'summary': {
          'totalTracked': 1,
          'attendanceCount': 1,
          'activityCount': 0,
          'onlineCount': 1,
          'gpsOffCount': 0,
        },
        'employees': [
          {
            'employeeId': 'emp-1',
            'name': 'Budi',
            'employeeNumber': 'EMP001',
            'latitude': -6.2,
            'longitude': 106.8,
            'status': 'attendance',
            'minutesSinceLastPing': 2,
          }
        ],
      };

      final response = LiveTrackingResponse.fromJson(json);
      expect(response.summary.totalTracked, equals(1));
      expect(response.employees.length, equals(1));
      expect(response.employees.first.name, equals('Budi'));
    });
  });
}
