import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';

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

  @override
  Future<LoginResponseData> login(LoginRequestModel request) async {
    final response = await _remoteDataSource.login(request);

    if (response.success && response.data != null) {
      final token = response.data!.token;

      // 1. Simpan token secara aman ke iOS Keychain / Android Encrypted KeyStore
      await _localDataSource.saveToken(token);

      // 2. Set token global di ApiClient untuk request API berikutnya
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
  Future<void> logout() async {
    // 1. Hapus token dari secure storage
    await _localDataSource.clearToken();

    // 2. Bersihkan token dari memory ApiClient
    _apiClient.clearAuthToken();
  }
}
