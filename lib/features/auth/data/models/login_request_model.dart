import 'package:hris_flutter/core/utils/device_info_util.dart';

/// Model payload request untuk API Login (`POST /api/v1/auth`).
class LoginRequestModel {
  final String email;
  final String password;
  final String? deviceId;
  final String? deviceName;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? fcmToken;

  const LoginRequestModel({
    required this.email,
    required this.password,
    this.deviceId = '',
    this.deviceName = '',
    this.deviceModel = '',
    this.osVersion = '',
    this.appVersion = '',
    this.fcmToken = '',
  });

  /// Factory helper untuk menggabungkan kredensial dengan DeviceInfoData & FCM Token
  factory LoginRequestModel.withDeviceInfo({
    required String email,
    required String password,
    required DeviceInfoData deviceInfo,
    String? fcmToken,
  }) {
    return LoginRequestModel(
      email: email,
      password: password,
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      deviceModel: deviceInfo.deviceModel,
      osVersion: deviceInfo.osVersion,
      appVersion: deviceInfo.appVersion,
      fcmToken: fcmToken ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'deviceId': deviceId ?? '',
      'deviceName': deviceName ?? '',
      'deviceModel': deviceModel ?? '',
      'osVersion': osVersion ?? '',
      'appVersion': appVersion ?? '',
      'fcmToken': fcmToken ?? '',
    };
  }

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      deviceModel: json['deviceModel'] as String? ?? '',
      osVersion: json['osVersion'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '',
      fcmToken: json['fcmToken'] as String? ?? '',
    );
  }
}
