import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Data class penampung informasi perangkat dan metadata aplikasi
class DeviceInfoData {
  final String deviceId;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final String appVersion;

  const DeviceInfoData({
    required this.deviceId,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });
}

/// Utility terpusat untuk mendeteksi informasi perangkat keras, OS,
/// dan versi aplikasi (dari pubspec.yaml via package_info_plus).
class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Mengambil data lengkap perangkat & versi aplikasi
  static Future<DeviceInfoData> getDeviceInfo() async {
    String deviceId = 'unknown_device_id';
    String deviceName = 'Unknown Device';
    String deviceModel = 'Unknown Model';
    String osVersion = 'Unknown OS';
    String appVersion = '1.0.0';

    try {
      // 1. Ambil versi aplikasi dari platform (pubspec.yaml)
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // 2. Ambil informasi device berdasarkan platform
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent.hashCode.toString();
        deviceName = webInfo.browserName.name;
        deviceModel = webInfo.platform ?? 'Web Browser';
        osVersion = webInfo.userAgent ?? 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceModel = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios_unknown_id';
        deviceName = iosInfo.name;
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID ?? 'macos_id';
        deviceName = macInfo.computerName;
        deviceModel = macInfo.model;
        osVersion = 'macOS ${macInfo.osRelease}';
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfo.windowsInfo;
        deviceId = winInfo.deviceId;
        deviceName = winInfo.computerName;
        deviceModel = winInfo.productName;
        osVersion = 'Windows ${winInfo.displayVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'linux_id';
        deviceName = linuxInfo.name;
        deviceModel = linuxInfo.variant ?? 'Linux';
        osVersion = linuxInfo.versionId ?? 'Linux';
      }
    } catch (e) {
      debugPrint('⚠️ [DeviceInfoUtil Error]: $e');
    }

    return DeviceInfoData(
      deviceId: deviceId,
      deviceName: deviceName,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
    );
  }
}
