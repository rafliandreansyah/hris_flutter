import 'package:hris_flutter/core/storage/secure_storage_service.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _storageService;

  AuthLocalDataSourceImpl({SecureStorageService? storageService})
      : _storageService = storageService ?? SecureStorageService.instance;

  @override
  Future<void> saveToken(String token) async {
    await _storageService.saveAccessToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await _storageService.getAccessToken();
  }

  @override
  Future<void> clearToken() async {
    await _storageService.clearAuthData();
  }

  @override
  Future<bool> hasToken() async {
    return await _storageService.hasToken();
  }
}
