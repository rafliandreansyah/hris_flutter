import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/network/token_refresher.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';

/// Interceptor untuk menyisipkan Bearer token autentikasi serta
/// telemetry & device tracking headers pada setiap permintaan HTTP.
///
/// Saat menerima 401 pada request terautentikasi, interceptor mencoba memperbarui
/// access token lewat refresh token ([tokenRefresher]) lalu mengulang request SEKALI.
/// Hanya bila refresh ditolak server, [onUnauthorized] (auto-logout) dipanggil.
class AuthInterceptor extends Interceptor {
  /// Kunci `extra` penanda request yang sudah diulang setelah refresh (mencegah loop).
  static const String retriedKey = 'x_auth_retried';

  String? _accessToken;
  final void Function()? onUnauthorized;
  final Future<DeviceInfoData> Function()? getDeviceInfo;
  final String Function()? getPlatform;
  DeviceInfoData? cachedDeviceInfo;

  /// Pembaruan token otomatis; `null` = perilaku lama (langsung [onUnauthorized] pada 401).
  final TokenRefresher? tokenRefresher;

  /// Menyediakan [Dio] untuk mengulang request setelah token diperbarui.
  final Dio Function()? dioProvider;

  AuthInterceptor({
    this.onUnauthorized,
    this.getDeviceInfo,
    this.getPlatform,
    this.cachedDeviceInfo,
    this.tokenRefresher,
    this.dioProvider,
  });

  /// Memperbarui token autentikasi yang sedang aktif
  void setToken(String? token) {
    _accessToken = token;
  }

  /// Menghapus token saat logout
  void clearToken() {
    _accessToken = null;
  }

  /// Apakah ada token yang aktif di memori
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      await _handleError(err, handler);
    } catch (_) {
      // Apa pun yang terjadi, request harus selesai dengan error aslinya (tidak boleh menggantung).
      handler.next(err);
    }
  }

  Future<void> _handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;

    // Login / endpoint autentikasi publik: jangan refresh, jangan auto-logout.
    if (!is401 || _isLoginOrPublicAuthRequest(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final refresher = tokenRefresher;
    final dio = dioProvider?.call();
    final alreadyRetried = err.requestOptions.extra[retriedKey] == true;

    if (refresher == null || dio == null || alreadyRetried) {
      onUnauthorized?.call();
      handler.next(err);
      return;
    }

    // Token pada request ini sudah usang tetapi token di memori sudah diperbarui
    // (refresh dari request lain): cukup ulang tanpa memicu refresh lagi.
    final sentAuth = err.requestOptions.headers[AppConstants.headerAuthorization];
    final currentAuth = hasToken
        ? '${AppConstants.headerBearerPrefix}$_accessToken'
        : null;
    final alreadyRefreshed =
        currentAuth != null && sentAuth != null && sentAuth != currentAuth;

    if (!alreadyRefreshed) {
      final result = await refresher.refresh();
      if (result == RefreshResult.rejected) {
        onUnauthorized?.call();
        handler.next(err);
        return;
      }
      if (result == RefreshResult.unavailable) {
        // Gagal sementara (offline/5xx): sesi tetap utuh, biarkan caller menangani error.
        handler.next(err);
        return;
      }
    }

    try {
      final response = await dio.fetch<dynamic>(_cloneForRetry(err.requestOptions));
      handler.resolve(response);
    } on DioException catch (retryError) {
      // 401 pada request ulang sudah memanggil onUnauthorized lewat onError (alreadyRetried).
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Menyalin request untuk diulang; FormData harus di-clone karena stream sudah terpakai.
  RequestOptions _cloneForRetry(RequestOptions original) {
    final options = original.copyWith(
      extra: {...original.extra, retriedKey: true},
    );
    final data = original.data;
    if (data is FormData) {
      options.data = data.clone();
    }
    return options;
  }

  /// Menentukan apakah request berasal dari endpoint login atau endpoint autentikasi publik,
  /// sehingga respons HTTP 401 tidak memicu refresh, auto-logout, ataupun dialog "Sesi Berakhir".
  bool _isLoginOrPublicAuthRequest(RequestOptions options) {
    final path = options.path;
    final uriPath = options.uri.path;

    const excludedPaths = [
      ApiEndpoints.auth, // '/auth'
      ApiEndpoints.login, // '/auth/login'
      ApiEndpoints.resetPassword, // '/auth/reset-password'
      ApiEndpoints.authRefresh, // '/auth/refresh'
      ApiEndpoints.logout, // '/auth/logout' (best-effort saat keluar)
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
