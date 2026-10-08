import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';

void main() {
  group('LoginRequestModel Tests', () {
    test('toJson and fromJson serialize and deserialize correctly', () {
      const model = LoginRequestModel(
        email: 'user@example.com',
        password: 'secretPassword',
        deviceId: 'device-123',
        deviceName: 'Pixel 8',
        deviceModel: 'Pixel',
        osVersion: 'Android 14',
        appVersion: '1.0.0+1',
        fcmToken: 'fcm-token-xyz',
      );

      final json = model.toJson();

      expect(json['email'], 'user@example.com');
      expect(json['password'], 'secretPassword');
      expect(json['deviceId'], 'device-123');
      expect(json['deviceName'], 'Pixel 8');
      expect(json['deviceModel'], 'Pixel');
      expect(json['osVersion'], 'Android 14');
      expect(json['appVersion'], '1.0.0+1');
      expect(json['fcmToken'], 'fcm-token-xyz');

      final reconstructed = LoginRequestModel.fromJson(json);

      expect(reconstructed.email, model.email);
      expect(reconstructed.password, model.password);
      expect(reconstructed.deviceId, model.deviceId);
      expect(reconstructed.deviceName, model.deviceName);
      expect(reconstructed.deviceModel, model.deviceModel);
      expect(reconstructed.osVersion, model.osVersion);
      expect(reconstructed.appVersion, model.appVersion);
      expect(reconstructed.fcmToken, model.fcmToken);
    });

    test('fromJson handles null values with fallback defaults', () {
      final json = <String, dynamic>{
        'email': null,
        'password': null,
      };

      final model = LoginRequestModel.fromJson(json);

      expect(model.email, '');
      expect(model.password, '');
      expect(model.deviceId, '');
      expect(model.deviceName, '');
      expect(model.deviceModel, '');
      expect(model.osVersion, '');
      expect(model.appVersion, '');
      expect(model.fcmToken, '');
    });

    test('LoginRequestModel.withDeviceInfo helper sets device metadata correctly', () {
      const deviceInfo = DeviceInfoData(
        deviceId: 'hardware-id-999',
        deviceName: 'iPhone 15 Pro',
        deviceModel: 'iPhone16,1',
        osVersion: 'iOS 17.5',
        appVersion: '2.1.0+42',
      );

      final model = LoginRequestModel.withDeviceInfo(
        email: 'employee@oasish.com',
        password: 'password123',
        deviceInfo: deviceInfo,
        fcmToken: 'token-abc',
      );

      expect(model.email, 'employee@oasish.com');
      expect(model.password, 'password123');
      expect(model.deviceId, 'hardware-id-999');
      expect(model.deviceName, 'iPhone 15 Pro');
      expect(model.deviceModel, 'iPhone16,1');
      expect(model.osVersion, 'iOS 17.5');
      expect(model.appVersion, '2.1.0+42');
      expect(model.fcmToken, 'token-abc');
    });

    test('LoginRequestModel.withDeviceInfo helper handles null fcmToken with empty string fallback', () {
      const deviceInfo = DeviceInfoData(
        deviceId: 'dev-1',
        deviceName: 'Device',
        deviceModel: 'Model',
        osVersion: 'OS',
        appVersion: '1.0.0',
      );

      final model = LoginRequestModel.withDeviceInfo(
        email: 'test@example.com',
        password: 'pass',
        deviceInfo: deviceInfo,
        fcmToken: null,
      );

      expect(model.fcmToken, '');
    });
  });

  group('LoginResponseData Tests', () {
    test('parses token from JSON correctly', () {
      final json = {'token': 'jwt-token-12345'};
      final data = LoginResponseData.fromJson(json);

      expect(data.token, 'jwt-token-12345');
    });

    test('handles missing or null token in JSON with fallback empty string', () {
      final data = LoginResponseData.fromJson({});
      expect(data.token, '');

      final dataNull = LoginResponseData.fromJson({'token': null});
      expect(dataNull.token, '');
    });

    test('toJson serializes token correctly', () {
      const data = LoginResponseData(token: 'jwt-xyz');
      expect(data.toJson(), {'token': 'jwt-xyz'});
    });
  });
}
