import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';

/// Layanan terpusat untuk menyimpan data sensitif (JWT Token, Session, Kredensial)
/// menggunakan enkripsi perangkat (iOS Keychain & Android EncryptedSharedPreferences).
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  static SecureStorageService get instance => _instance;
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage;

  SecureStorageService._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // For testing / dependency injection
  SecureStorageService.withStorage(this._storage);

  /// Menyimpan Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  /// Mengambil Access Token yang tersimpan
  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  /// Menyimpan Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
    );
  }

  /// Mengambil Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  /// Memeriksa apakah user memiliki access token tersimpan
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Menghapus semua sesi & token autentikasi (saat Logout)
  Future<void> clearAuthData() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userProfileKey);
  }

  /// Menghapus seluruh data di secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
