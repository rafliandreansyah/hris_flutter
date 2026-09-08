import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/check_in_request_model.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';

void main() {
  group('Attendance Models Tests', () {
    test('WorkLocationItem creation and equality', () {
      const loc1 = WorkLocationItem(
        id: 'loc-1',
        name: 'Jakarta HQ',
        address: 'Jl. Sudirman No. 1',
        radius: 100.0,
        latitude: -6.2253,
        longitude: 106.8097,
        isAnyWhere: false,
        isDefault: true,
      );

      const loc2 = WorkLocationItem(
        id: 'loc-1',
        name: 'Jakarta HQ',
        address: 'Jl. Sudirman No. 1',
        radius: 100.0,
        latitude: -6.2253,
        longitude: 106.8097,
        isAnyWhere: false,
        isDefault: true,
      );

      expect(loc1, equals(loc2));
      expect(loc1.id, 'loc-1');
      expect(loc1.name, 'Jakarta HQ');
      expect(loc1.radius, 100.0);
      expect(loc1.isDefault, isTrue);
      expect(loc1.isAnyWhere, isFalse);
    });

    test('WorkLocationItem isAnyWhere defaults correctly', () {
      const loc = WorkLocationItem(
        id: 'loc-anywhere',
        name: 'Remote Office',
        isAnyWhere: true,
      );

      expect(loc.isAnyWhere, isTrue);
      expect(loc.isDefault, isFalse);
      expect(loc.radius, 50.0);
      expect(loc.latitude, isNull);
      expect(loc.longitude, isNull);
    });

    test('AttendanceTodayData default values and copyWith test', () {
      final now = DateTime(2026, 8, 27, 8, 45, 20);
      final data = AttendanceTodayData(
        serverTime: now,
      );

      expect(data.isClockedIn, isFalse);
      expect(data.isClockedOut, isFalse);
      expect(data.isOnBreak, isFalse);
      expect(data.employeeName, 'Alex Rivera');
      expect(data.employeeRole, 'Senior Product Designer');
      expect(data.employeeId, '8829');
      expect(data.officeName, 'Jakarta HQ Office');
      expect(data.geofenceRadiusMeters, 50.0);
      expect(data.isInsideGeofence, isTrue);
      expect(data.availableWorkLocations, isEmpty);
      expect(data.selectedWorkLocation, isNull);
      expect(data.hasWorkLocation, isFalse);

      final updated = data.copyWith(
        inTime: '08:30',
        outTime: '18:00',
        breakOutTime: '12:00',
        breakInTime: '13:00',
        isOnBreak: true,
      );

      expect(updated.isClockedIn, isTrue);
      expect(updated.isClockedOut, isTrue);
      expect(updated.isOnBreak, isTrue);
      expect(updated.inTime, '08:30');
      expect(updated.outTime, '18:00');
      expect(updated.breakOutTime, '12:00');
      expect(updated.breakInTime, '13:00');
    });

    test('AttendanceTodayData with work locations', () {
      const loc1 = WorkLocationItem(
        id: 'loc-1',
        name: 'HQ Office',
        isDefault: true,
        radius: 50.0,
        latitude: -6.2253,
        longitude: 106.8097,
      );

      const loc2 = WorkLocationItem(
        id: 'loc-2',
        name: 'Remote Anywhere',
        isAnyWhere: true,
      );

      final data = AttendanceTodayData(
        serverTime: DateTime(2026, 8, 27, 8, 45, 20),
        availableWorkLocations: [loc1, loc2],
        selectedWorkLocation: loc1,
      );

      expect(data.availableWorkLocations.length, 2);
      expect(data.selectedWorkLocation, loc1);
      expect(data.hasWorkLocation, isTrue);

      // Switch selected location
      final updated = data.copyWith(selectedWorkLocation: loc2);
      expect(updated.selectedWorkLocation, loc2);
      expect(updated.selectedWorkLocation!.isAnyWhere, isTrue);
    });

    test('CheckInRequestModel json serialization and deserialization', () {
      const request = CheckInRequestModel(
        latitude: -6.2253,
        longitude: 106.8097,
        address: 'HQ Office — Main Lobby',
        note: 'Normal check-in',
        type: 'IN',
      );

      final json = request.toJson();
      expect(json['latitude'], -6.2253);
      expect(json['longitude'], 106.8097);
      expect(json['address'], 'HQ Office — Main Lobby');
      expect(json['note'], 'Normal check-in');
      expect(json['type'], 'IN');

      final deserialized = CheckInRequestModel.fromJson(json);
      expect(deserialized.latitude, request.latitude);
      expect(deserialized.longitude, request.longitude);
      expect(deserialized.address, request.address);
      expect(deserialized.note, request.note);
      expect(deserialized.type, request.type);
    });
  });
}
