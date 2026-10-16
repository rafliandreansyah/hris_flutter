import 'dart:convert';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/network/token_refresher.dart';
import 'package:hris_flutter/core/services/notification_service.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final ApiClient _apiClient;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
    ApiClient? apiClient,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? AuthLocalDataSourceImpl(),
        _apiClient = apiClient ?? ApiClient.instance;

  String? _extractEmployeeIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }
      final payloadStr = utf8.decode(base64.decode(normalized));
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      return (payload['employeeId'] ?? payload['id'] ?? payload['sub'])
          ?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LoginResponseData> login(LoginRequestModel request) async {
    final response = await _remoteDataSource.login(request);

    if (response.success && response.data != null) {
      final token = response.data!.token;

      // 1. Simpan token secara aman ke iOS Keychain / Android Encrypted KeyStore
      await _localDataSource.saveToken(token);

      // 1b. Simpan refresh token (jika server menyediakannya) untuk perpanjangan sesi otomatis
      final refreshToken = response.data!.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _localDataSource.saveRefreshToken(refreshToken);
      }

      // 2. Ekstrak & simpan Employee ID jika tersedia di payload JWT
      final empId = _extractEmployeeIdFromJwt(token);
      if (empId != null && empId.isNotEmpty) {
        await _localDataSource.saveEmployeeId(empId);
      }

      // 3. Set token global di ApiClient untuk request API berikutnya
      _apiClient.setAuthToken(token);

      return response.data!;
    } else {
      throw ApiException(
        message: response.message ?? 'Gagal melakukan autentikasi login.',
      );
    }
  }

  @override
  Future<String?> getSavedToken() async {
    final token = await _localDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
    }
    return token;
  }

  @override
  Future<bool> hasActiveSession() async {
    final hasToken = await _localDataSource.hasToken();
    if (hasToken) {
      final token = await _localDataSource.getToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      }
    }
    return hasToken;
  }

  @override
  Future<String?> refreshSession() async {
    final result = await _apiClient.refreshAccessToken();
    if (result != RefreshResult.success) return null;
    return _localDataSource.getToken();
  }

  @override
  Future<void> logout({bool notifyServer = false}) async {
    // 0. Logout oleh pengguna: beritahu server (best-effort, tidak boleh menghambat logout lokal)
    if (notifyServer) {
      try {
        await _remoteDataSource.logout().timeout(const Duration(seconds: 5));
      } catch (silentError) {
        debugPrint('[diabaikan] $silentError');
      }
    }

    // 1. Hapus token dari secure storage
    await _localDataSource.clearToken();

    // 2. Bersihkan token dari memory ApiClient
    _apiClient.clearAuthToken();

    // 3. Hapus token FCM jika ada
    try {
      await NotificationService.instance.deleteFcmToken();
    } catch (silentError) {
      debugPrint('[diabaikan] $silentError');
    }
  }

  @override
  Future<UserProfileData> getProfile() async {
    final response = await _remoteDataSource.getProfile();
    if (response.success && response.data != null) {
      final profile = response.data!;
      if (profile.user.language != null && profile.user.language!.isNotEmpty) {
        await SecureStorageService.instance.saveUserLanguage(profile.user.language!);
      }
      if (profile.permissions.isNotEmpty) {
        await SecureStorageService.instance.saveUserPermissions(profile.permissions);
      }
      return profile;
    } else {
      throw ApiException(
        message: response.message ?? 'Gagal memuat profil pengguna.',
      );
    }
  }

  @override
  Future<String> updateLanguage(String language) async {
    final response = await _remoteDataSource.updateLanguage(language);
    if (response.success) {
      await SecureStorageService.instance.saveUserLanguage(language);
      return language;
    } else {
      throw ApiException(
        message: response.message ?? 'Gagal memperbarui bahasa tampilan.',
      );
    }
  }
}
