import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/network/api_response.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';

class _MockLocalDataSource implements AuthLocalDataSource {
  String? savedToken;
  String? savedEmployeeId;

  @override
  Future<void> saveToken(String token) async {
    savedToken = token;
  }

  @override
  Future<String?> getToken() async => savedToken;

  @override
  Future<void> saveEmployeeId(String employeeId) async {
    savedEmployeeId = employeeId;
  }

  @override
  Future<String?> getEmployeeId() async => savedEmployeeId;

  @override
  Future<void> clearToken() async {
    savedToken = null;
    savedEmployeeId = null;
  }

  @override
  Future<bool> hasToken() async => savedToken != null && savedToken!.isNotEmpty;
}

class _MockRemoteDataSource implements AuthRemoteDataSource {
  ApiResponse<LoginResponseData>? mockLoginResponse;
  ApiResponse<UserProfileData>? mockProfileResponse;
  ApiResponse<Map<String, dynamic>>? mockLanguageResponse;

  @override
  Future<ApiResponse<LoginResponseData>> login(LoginRequestModel request) async {
    if (mockLoginResponse == null) {
      throw const ApiException(message: 'Login failed');
    }
    return mockLoginResponse!;
  }

  @override
  Future<ApiResponse<UserProfileData>> getProfile() async {
    if (mockProfileResponse == null) {
      throw const ApiException(message: 'Profile fetch failed');
    }
    return mockProfileResponse!;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> updateLanguage(String language) async {
    if (mockLanguageResponse == null) {
      throw const ApiException(message: 'Update language failed');
    }
    return mockLanguageResponse!;
  }
}

class _MockApiClient implements ApiClient {
  String? currentAuthToken;
  bool clearAuthTokenCalled = false;

  @override
  void setAuthToken(String? token) {
    currentAuthToken = token;
  }

  @override
  void clearAuthToken() {
    clearAuthTokenCalled = true;
    currentAuthToken = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Helper untuk membuat token JWT valid dengan payload kustom
String createTestJwt(Map<String, dynamic> payload) {
  final headerBase64 = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}))).replaceAll('=', '');
  final payloadBase64 = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  return '$headerBase64.$payloadBase64.dummySignature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLocalDataSource localDataSource;
  late _MockRemoteDataSource remoteDataSource;
  late _MockApiClient apiClient;
  late AuthRepositoryImpl repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    localDataSource = _MockLocalDataSource();
    remoteDataSource = _MockRemoteDataSource();
    apiClient = _MockApiClient();

    repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      apiClient: apiClient,
    );
  });

  group('AuthRepositoryImpl.login', () {
    const loginRequest = LoginRequestModel(
      email: 'user@example.com',
      password: 'password123',
    );

    test('extracts employeeId from JWT and saves token, employeeId, and sets ApiClient auth token', () async {
      final jwt = createTestJwt({
        'employeeId': 'EMP-TEST-001',
        'email': 'user@example.com',
      });

      remoteDataSource.mockLoginResponse = ApiResponse<LoginResponseData>(
        success: true,
        message: 'Login sukses',
        data: LoginResponseData(token: jwt),
      );

      final result = await repository.login(loginRequest);

      expect(result.token, equals(jwt));
      expect(localDataSource.savedToken, equals(jwt));
      expect(localDataSource.savedEmployeeId, equals('EMP-TEST-001'));
      expect(apiClient.currentAuthToken, equals(jwt));
    });

    test('extracts fallback "sub" as employeeId from JWT if employeeId is absent', () async {
      final jwt = createTestJwt({
        'sub': 'sub-uuid-777',
      });

      remoteDataSource.mockLoginResponse = ApiResponse<LoginResponseData>(
        success: true,
        message: 'Login sukses',
        data: LoginResponseData(token: jwt),
      );

      await repository.login(loginRequest);

      expect(localDataSource.savedEmployeeId, equals('sub-uuid-777'));
    });

    test('extracts fallback "id" as employeeId from JWT if employeeId and sub are absent', () async {
      final jwt = createTestJwt({
        'id': 'id-uuid-888',
      });

      remoteDataSource.mockLoginResponse = ApiResponse<LoginResponseData>(
        success: true,
        message: 'Login sukses',
        data: LoginResponseData(token: jwt),
      );

      await repository.login(loginRequest);

      expect(localDataSource.savedEmployeeId, equals('id-uuid-888'));
    });

    test('handles non-JWT malformed token gracefully without crashing', () async {
      const nonJwtToken = 'plain-random-opaque-token';

      remoteDataSource.mockLoginResponse = const ApiResponse<LoginResponseData>(
        success: true,
        message: 'Login sukses',
        data: LoginResponseData(token: nonJwtToken),
      );

      final result = await repository.login(loginRequest);

      expect(result.token, equals(nonJwtToken));
      expect(localDataSource.savedToken, equals(nonJwtToken));
      expect(localDataSource.savedEmployeeId, isNull);
      expect(apiClient.currentAuthToken, equals(nonJwtToken));
    });

    test('throws ApiException when response.success is false', () async {
      remoteDataSource.mockLoginResponse = const ApiResponse<LoginResponseData>(
        success: false,
        message: 'Kombinasi email dan password salah',
        data: null,
      );

      expect(
        () => repository.login(loginRequest),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Kombinasi email dan password salah',
        )),
      );
    });

    test('throws ApiException with default message when response.message is null', () async {
      remoteDataSource.mockLoginResponse = const ApiResponse<LoginResponseData>(
        success: false,
        message: null,
        data: null,
      );

      expect(
        () => repository.login(loginRequest),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Gagal melakukan autentikasi login.',
        )),
      );
    });
  });

  group('AuthRepositoryImpl.getSavedToken and hasActiveSession', () {
    test('getSavedToken sets token on ApiClient when token exists', () async {
      localDataSource.savedToken = 'saved-jwt-123';

      final token = await repository.getSavedToken();

      expect(token, equals('saved-jwt-123'));
      expect(apiClient.currentAuthToken, equals('saved-jwt-123'));
    });

    test('getSavedToken returns null and does not set token when token is null or empty', () async {
      localDataSource.savedToken = null;

      final token = await repository.getSavedToken();

      expect(token, isNull);
      expect(apiClient.currentAuthToken, isNull);
    });

    test('hasActiveSession returns true and syncs token to ApiClient when session active', () async {
      localDataSource.savedToken = 'active-session-token';

      final hasSession = await repository.hasActiveSession();

      expect(hasSession, isTrue);
      expect(apiClient.currentAuthToken, equals('active-session-token'));
    });

    test('hasActiveSession returns false when no active token', () async {
      localDataSource.savedToken = null;

      final hasSession = await repository.hasActiveSession();

      expect(hasSession, isFalse);
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('clears token from storage and memory ApiClient', () async {
      localDataSource.savedToken = 'token-to-delete';
      localDataSource.savedEmployeeId = 'EMP-999';
      apiClient.currentAuthToken = 'token-to-delete';

      await repository.logout();

      expect(localDataSource.savedToken, isNull);
      expect(localDataSource.savedEmployeeId, isNull);
      expect(apiClient.clearAuthTokenCalled, isTrue);
      expect(apiClient.currentAuthToken, isNull);
    });
  });

  group('AuthRepositoryImpl.getProfile and updateLanguage', () {
    test('getProfile saves user language and permissions to SecureStorageService', () async {
      remoteDataSource.mockProfileResponse = const ApiResponse<UserProfileData>(
        success: true,
        message: 'Profile success',
        data: UserProfileData(
          user: UserModel(id: 'u-1', email: 'user@example.com', language: 'id'),
          dataScope: 'ALL',
          permissions: ['leave.approve', 'overtime.approve'],
        ),
      );

      final profile = await repository.getProfile();

      expect(profile.user.id, 'u-1');
      expect(await SecureStorageService.instance.getUserLanguage(), equals('id'));
      expect(SecureStorageService.instance.hasPermissionInMemory('leave.approve'), isTrue);
      expect(SecureStorageService.instance.hasPermissionInMemory('overtime.approve'), isTrue);
    });

    test('getProfile throws ApiException when response.success is false', () async {
      remoteDataSource.mockProfileResponse = const ApiResponse<UserProfileData>(
        success: false,
        message: 'Gagal memuat profil',
        data: null,
      );

      expect(
        () => repository.getProfile(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Gagal memuat profil')),
      );
    });

    test('updateLanguage saves language and returns updated language string', () async {
      remoteDataSource.mockLanguageResponse = const ApiResponse<Map<String, dynamic>>(
        success: true,
        message: 'Success',
        data: {},
      );

      final updated = await repository.updateLanguage('en');

      expect(updated, equals('en'));
      expect(await SecureStorageService.instance.getUserLanguage(), equals('en'));
    });

    test('updateLanguage throws ApiException when response.success is false', () async {
      remoteDataSource.mockLanguageResponse = const ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Gagal update bahasa',
        data: null,
      );

      expect(
        () => repository.updateLanguage('en'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Gagal update bahasa')),
      );
    });
  });
}
