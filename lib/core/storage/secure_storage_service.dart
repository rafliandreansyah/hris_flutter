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

  /// Menyimpan Employee ID yang sedang login
  Future<void> saveEmployeeId(String employeeId) async {
    await _storage.write(
      key: AppConstants.employeeIdKey,
      value: employeeId,
    );
  }

  /// Mengambil Employee ID yang tersimpan
  Future<String?> getEmployeeId() async {
    return await _storage.read(key: AppConstants.employeeIdKey);
  }

  /// Menyimpan bahasa terpilih ('id' atau 'en')
  Future<void> saveUserLanguage(String language) async {
    await _storage.write(
      key: AppConstants.userLanguageKey,
      value: language,
    );
  }

  /// Menyimpan bahasa tersimpan
  Future<String?> getUserLanguage() async {
    return await _storage.read(key: AppConstants.userLanguageKey);
  }

  /// Menyimpan theme mode terpilih ('system', 'light', 'dark')
  Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(
      key: AppConstants.themeModeKey,
      value: themeMode,
    );
  }

  /// Mengambil theme mode tersimpan
  Future<String?> getThemeMode() async {
    return await _storage.read(key: AppConstants.themeModeKey);
  }

  static final Set<String> _memoryPermissions = <String>{};

  /// Menyimpan daftar kode izin (permissions) pengguna
  Future<void> saveUserPermissions(List<String> permissions) async {
    _memoryPermissions.clear();
    _memoryPermissions.addAll(permissions);
    try {
      await _storage.write(
        key: AppConstants.userPermissionsKey,
        value: permissions.join(','),
      );
    } catch (_) {}
  }

  /// Mengambil daftar kode izin (permissions) pengguna
  Future<List<String>> getUserPermissions() async {
    if (_memoryPermissions.isNotEmpty) {
      return _memoryPermissions.toList();
    }
    try {
      final raw = await _storage
          .read(key: AppConstants.userPermissionsKey)
          .timeout(const Duration(milliseconds: 200));
      if (raw == null || raw.trim().isEmpty) return [];
      final list = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      _memoryPermissions.addAll(list);
      return list;
    } catch (_) {
      return _memoryPermissions.toList();
    }
  }

  /// Memeriksa apakah pengguna memiliki kode izin tertentu (misal: 'activity.manage')
  Future<bool> hasPermission(String permissionCode) async {
    if (_memoryPermissions.contains(permissionCode)) return true;
    final permissions = await getUserPermissions();
    return permissions.contains(permissionCode);
  }

  /// Memeriksa izin secara sinkron dari cache memori
  bool hasPermissionInMemory(String permissionCode) {
    return _memoryPermissions.contains(permissionCode);
  }

  /// Memeriksa apakah user memiliki access token tersimpan
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Menghapus semua sesi & token autentikasi (saat Logout)
  Future<void> clearAuthData() async {
    _memoryPermissions.clear();
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userProfileKey);
    await _storage.delete(key: AppConstants.employeeIdKey);
    await _storage.delete(key: AppConstants.userPermissionsKey);
  }

  /// Menghapus seluruh data di secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
