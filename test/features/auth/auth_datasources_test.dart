import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockResponseData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockResponseData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockResponseData as T,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthLocalDataSourceImpl Tests', () {
    late AuthLocalDataSourceImpl localDataSource;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      localDataSource = AuthLocalDataSourceImpl();
    });

    test('saveToken and getToken properly store and retrieve access token', () async {
      expect(await localDataSource.getToken(), isNull);
      expect(await localDataSource.hasToken(), isFalse);

      await localDataSource.saveToken('jwt-sample-token-123');

      expect(await localDataSource.getToken(), equals('jwt-sample-token-123'));
      expect(await localDataSource.hasToken(), isTrue);
    });

    test('saveEmployeeId and getEmployeeId properly store and retrieve employee ID', () async {
      expect(await localDataSource.getEmployeeId(), isNull);

      await localDataSource.saveEmployeeId('emp-uuid-456');

      expect(await localDataSource.getEmployeeId(), equals('emp-uuid-456'));
    });

    test('clearToken clears access token and employee id from secure storage', () async {
      await localDataSource.saveToken('token-to-clear');
      await localDataSource.saveEmployeeId('emp-to-clear');

      expect(await localDataSource.hasToken(), isTrue);
      expect(await localDataSource.getEmployeeId(), isNotNull);

      await localDataSource.clearToken();

      expect(await localDataSource.getToken(), isNull);
      expect(await localDataSource.hasToken(), isFalse);
      expect(await localDataSource.getEmployeeId(), isNull);
    });
  });

  group('AuthRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late AuthRemoteDataSourceImpl remoteDataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      remoteDataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('login sends POST request to ApiEndpoints.auth and parses response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Login berhasil',
        'data': {
          'token': 'remote-jwt-token-xyz',
        },
      };

      const request = LoginRequestModel(
        email: 'user@gmail.com',
        password: 'amaterasu',
      );

      final result = await remoteDataSource.login(request);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.auth));
      expect(mockApiClient.lastData['email'], equals('user@gmail.com'));
      expect(mockApiClient.lastData['password'], equals('amaterasu'));
      expect(result.success, isTrue);
      expect(result.data?.token, equals('remote-jwt-token-xyz'));
    });

    test('getProfile sends GET request to ApiEndpoints.authProfile and parses UserProfileData', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Profile loaded',
        'data': {
          'user': {
            'id': 'user-1',
            'email': 'user@example.com',
            'role': 'EMPLOYEE',
            'language': 'id',
          },
          'dataScope': 'SELF',
          'permissions': ['attendance.view', 'leave.create'],
        },
      };

      final result = await remoteDataSource.getProfile();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.authProfile));
      expect(result.success, isTrue);
      expect(result.data?.user.id, equals('user-1'));
      expect(result.data?.user.email, equals('user@example.com'));
      expect(result.data?.permissions, contains('attendance.view'));
    });

    test('updateLanguage sends PUT request to ApiEndpoints.authLanguage with language payload', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Language updated',
        'data': {'status': 'ok'},
      };

      final result = await remoteDataSource.updateLanguage('en');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.authLanguage));
      expect(mockApiClient.lastData, equals({'language': 'en'}));
      expect(result.success, isTrue);
    });
  });
}
