import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';

/// Interceptor untuk menyisipkan Bearer token autentikasi serta
/// telemetry & device tracking headers pada setiap permintaan HTTP,
/// dan mendeteksi respons 401 Unauthorized.
class AuthInterceptor extends Interceptor {
  String? _accessToken;
  final void Function()? onUnauthorized;
  final Future<DeviceInfoData> Function()? getDeviceInfo;
  final String Function()? getPlatform;
  DeviceInfoData? cachedDeviceInfo;

  AuthInterceptor({
    this.onUnauthorized,
    this.getDeviceInfo,
    this.getPlatform,
    this.cachedDeviceInfo,
  });

  /// Memperbarui token autentikasi yang sedang aktif
  void setToken(String? token) {
    _accessToken = token;
  }

  /// Menghapus token saat logout
  void clearToken() {
    _accessToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      options.headers[AppConstants.headerAuthorization] =
          '${AppConstants.headerBearerPrefix}$_accessToken';
    }
    options.headers[AppConstants.headerContentType] = AppConstants.jsonContentType;
    options.headers[AppConstants.headerAccept] = AppConstants.jsonContentType;

    try {
      final deviceInfo = cachedDeviceInfo ??
          await (getDeviceInfo != null
              ? getDeviceInfo!()
              : DeviceInfoUtil.getDeviceInfo());
      cachedDeviceInfo = deviceInfo;

      final platform = getPlatform != null
          ? getPlatform!()
          : (Platform.isIOS ? 'mobile_ios' : 'mobile_android');

      options.headers['x-device-id'] = deviceInfo.deviceId;
      options.headers['x-platform'] = platform;
      options.headers['x-device-model'] = deviceInfo.deviceModel;
      options.headers['x-os-version'] = deviceInfo.osVersion;
      options.headers['x-app-version'] = deviceInfo.appVersion;
    } catch (_) {
      // Jika terjadi kesalahan tak terduga, request tetap dilanjutkan tanpa crash
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Jika request berasal dari login atau autentikasi publik, jangan memicu auto-logout / dialog sesi berakhir
      if (!_isLoginOrPublicAuthRequest(err.requestOptions)) {
        onUnauthorized?.call();
      }
    }
    handler.next(err);
  }

  /// Menentukan apakah request berasal dari endpoint login atau endpoint autentikasi publik,
  /// sehingga respons HTTP 401 tidak memicu auto-logout ataupun dialog "Sesi Berakhir".
  bool _isLoginOrPublicAuthRequest(RequestOptions options) {
    final path = options.path;
    final uriPath = options.uri.path;

    const excludedPaths = [
      ApiEndpoints.auth, // '/auth'
      ApiEndpoints.login, // '/auth/login'
      ApiEndpoints.forgotPassword, // '/auth/forgot-password'
      ApiEndpoints.resetPassword, // '/auth/reset-password'
    ];

    for (final excluded in excludedPaths) {
      if (path == excluded ||
          uriPath == excluded ||
          uriPath.endsWith(excluded) ||
          uriPath.endsWith('$excluded/')) {
        return true;
      }
    }

    return false;
  }
}
