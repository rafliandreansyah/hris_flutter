import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';

/// Hasil percobaan memperbarui access token memakai refresh token.
enum RefreshResult {
  /// Access token & refresh token baru berhasil disimpan.
  success,

  /// Server menolak (token tidak ada / tidak valid / kedaluwarsa / dicabut / akun nonaktif).
  /// Sesi benar-benar berakhir sehingga pengguna harus login ulang.
  rejected,

  /// Gagal sementara (tidak ada jaringan, timeout, 5xx, rate limit). Sesi TIDAK dianggap berakhir.
  unavailable,
}

/// Memperbarui access token (JWT) lewat `POST /auth/refresh` dengan rotasi refresh token.
///
/// * **Single-flight**: banyak request 401 bersamaan hanya memicu satu panggilan refresh;
///   semuanya menunggu hasil yang sama (refresh token dirotasi sehingga panggilan ganda
///   akan dianggap pemakaian ulang oleh server).
/// * Memakai instance [Dio] terpisah tanpa interceptor autentikasi agar tidak berulang tanpa akhir.
class TokenRefresher {
  final Dio _dio;
  final SecureStorageService _storage;
  final Future<String> Function() _deviceIdProvider;

  /// Dipanggil setelah access token baru tersimpan (mis. untuk memperbarui token di memori ApiClient).
  final void Function(String accessToken)? onTokenRefreshed;

  Future<RefreshResult>? _inFlight;

  TokenRefresher({
    Dio? dio,
    SecureStorageService? storage,
    Future<String> Function()? deviceIdProvider,
    this.onTokenRefreshed,
  })  : _dio = dio ?? _buildDio(),
        _storage = storage ?? SecureStorageService.instance,
        _deviceIdProvider = deviceIdProvider ?? _defaultDeviceId;

  static Dio _buildDio() => Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          sendTimeout: AppConstants.sendTimeout,
          headers: {
            AppConstants.headerContentType: AppConstants.jsonContentType,
            AppConstants.headerAccept: AppConstants.jsonContentType,
          },
          responseType: ResponseType.json,
        ),
      );

  static Future<String> _defaultDeviceId() async =>
      (await DeviceInfoUtil.getDeviceInfo()).deviceId;

  /// Apakah sedang ada proses refresh berjalan.
  bool get isRefreshing => _inFlight != null;

  /// Memperbarui sesi. Pemanggilan bersamaan berbagi satu proses.
  Future<RefreshResult> refresh() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<RefreshResult> _doRefresh() async {
    String? refreshToken;
    try {
      refreshToken = await _storage.getRefreshToken();
    } catch (e) {
      // Secure storage tidak terbaca: jangan memaksa logout, biarkan caller menangani error.
      debugPrint('[TokenRefresher] gagal membaca refresh token: $e');
      return RefreshResult.unavailable;
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      return RefreshResult.rejected;
    }

    String? deviceId;
    try {
      deviceId = await _deviceIdProvider();
    } catch (_) {
      deviceId = null;
    }

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.authRefresh,
        data: {
          'refreshToken': refreshToken,
          if (deviceId != null && deviceId.length >= 5) 'deviceId': deviceId,
        },
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final newAccess = data is Map ? data['token']?.toString() : null;
      final newRefresh = data is Map ? data['refreshToken']?.toString() : null;

      if (newAccess == null ||
          newAccess.isEmpty ||
          newRefresh == null ||
          newRefresh.isEmpty) {
        return RefreshResult.rejected;
      }

      // Simpan refresh token baru DULU: token lama sudah dicabut server.
      await _storage.saveRefreshToken(newRefresh);
      await _storage.saveAccessToken(newAccess);
      onTokenRefreshed?.call(newAccess);
      return RefreshResult.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403 || status == 404) {
        return RefreshResult.rejected;
      }
      debugPrint('[TokenRefresher] refresh gagal sementara: ${e.type} $status');
      return RefreshResult.unavailable;
    } catch (e) {
      debugPrint('[TokenRefresher] refresh error tak terduga: $e');
      return RefreshResult.unavailable;
    }
  }
}
