import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/notification/data/models/notification_settings_model.dart';

void main() {
  group('NotificationSettingsModel Tests', () {
    const jsonSample = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'employeeId': '123e4567-e89b-12d3-a456-426614174000',
      'pushAttendanceRequest': true,
      'pushLeave': false,
      'pushOvertime': true,
      'pushPayroll': false,
      'pushAnnouncement': true,
      'pushWarningLetter': true,
      'createdAt': '2026-08-28T14:15:00.000Z',
      'updatedAt': '2026-08-28T14:15:00.000Z',
    };

    test('fromJson parses full JSON correctly', () {
      final model = NotificationSettingsModel.fromJson(jsonSample);

      expect(model.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.employeeId, '123e4567-e89b-12d3-a456-426614174000');
      expect(model.pushAttendanceRequest, isTrue);
      expect(model.pushLeave, isFalse);
      expect(model.pushOvertime, isTrue);
      expect(model.pushPayroll, isFalse);
      expect(model.pushAnnouncement, isTrue);
      expect(model.pushWarningLetter, isTrue);
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
      expect(model.isAllEnabled, isFalse);
    });

    test('toJson serializes correctly', () {
      final model = NotificationSettingsModel.fromJson(jsonSample);
      final json = model.toJson();

      expect(json['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(json['pushAttendanceRequest'], isTrue);
      expect(json['pushLeave'], isFalse);
      expect(json['pushPayroll'], isFalse);
    });

    test('toUpdatePayload returns only the 6 push configuration fields', () {
      final model = NotificationSettingsModel.fromJson(jsonSample);
      final payload = model.toUpdatePayload();

      expect(payload.length, 6);
      expect(payload['pushAttendanceRequest'], isTrue);
      expect(payload['pushLeave'], isFalse);
      expect(payload['pushOvertime'], isTrue);
      expect(payload['pushPayroll'], isFalse);
      expect(payload['pushAnnouncement'], isTrue);
      expect(payload['pushWarningLetter'], isTrue);
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('createdAt'), isFalse);
    });

    test('toggleAll switches all 6 flags', () {
      const model = NotificationSettingsModel(
        pushAttendanceRequest: false,
        pushLeave: false,
        pushOvertime: false,
        pushPayroll: false,
        pushAnnouncement: false,
        pushWarningLetter: false,
      );
      expect(model.isAllEnabled, isFalse);

      final allOn = model.toggleAll(true);
      expect(allOn.isAllEnabled, isTrue);
      expect(allOn.pushAttendanceRequest, isTrue);
      expect(allOn.pushLeave, isTrue);
      expect(allOn.pushOvertime, isTrue);
      expect(allOn.pushPayroll, isTrue);
      expect(allOn.pushAnnouncement, isTrue);
      expect(allOn.pushWarningLetter, isTrue);

      final allOff = allOn.toggleAll(false);
      expect(allOff.isAllEnabled, isFalse);
      expect(allOff.pushAttendanceRequest, isFalse);
      expect(allOff.pushWarningLetter, isFalse);
    });

    test('copyWith updates individual flags', () {
      const model = NotificationSettingsModel();
      final updated = model.copyWith(
        pushLeave: false,
        pushPayroll: false,
      );

      expect(updated.pushLeave, isFalse);
      expect(updated.pushPayroll, isFalse);
      expect(updated.pushAttendanceRequest, isTrue);
    });

    test('NotificationSettingsResponse.fromJson parses valid response', () {
      final responseJson = {
        'success': true,
        'message': 'OK',
        'data': jsonSample,
      };
      final response = NotificationSettingsResponse.fromJson(responseJson);

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data, isNotNull);
      expect(response.data!.id, '123e4567-e89b-12d3-a456-426614174000');
    });

    test('NotificationSettingsResponse.fromJson handles null or empty data', () {
      final responseJson = {
        'success': false,
        'message': 'Failed',
        'data': null,
      };
      final response = NotificationSettingsResponse.fromJson(responseJson);

      expect(response.success, isFalse);
      expect(response.data, isNull);
    });
  });
}
