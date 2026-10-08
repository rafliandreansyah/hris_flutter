import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/services/notification_service.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_state.dart';

class _MockAuthRepository implements AuthRepository {
  String? savedToken;
  bool shouldThrowLogin = false;
  ApiException? apiExceptionToThrow;
  Exception? genericExceptionToThrow;
  LoginRequestModel? lastLoginRequest;
  bool logoutCalled = false;
  bool shouldThrowLogout = false;

  @override
  Future<LoginResponseData> login(LoginRequestModel request) async {
    lastLoginRequest = request;
    if (apiExceptionToThrow != null) {
      throw apiExceptionToThrow!;
    }
    if (genericExceptionToThrow != null) {
      throw genericExceptionToThrow!;
    }
    if (shouldThrowLogin) {
      throw const ApiException(message: 'Kombinasi email atau password salah', statusCode: 401);
    }
    return const LoginResponseData(token: 'mock-jwt-token-999');
  }

  @override
  Future<String?> getSavedToken() async {
    if (genericExceptionToThrow != null) {
      throw genericExceptionToThrow!;
    }
    return savedToken;
  }

  @override
  Future<bool> hasActiveSession() async => savedToken != null && savedToken!.isNotEmpty;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (shouldThrowLogout) {
      throw Exception('Logout network failure');
    }
  }

  @override
  Future<UserProfileData> getProfile() async => throw UnimplementedError();

  @override
  Future<String> updateLanguage(String language) async => language;
}

class _MockNotificationService implements NotificationService {
  String? mockFcmToken = 'mock-fcm-device-token';
  bool deleteFcmCalled = false;

  @override
  Future<String?> getFcmToken() async => mockFcmToken;

  @override
  Future<void> deleteFcmToken() async {
    deleteFcmCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository mockRepository;
  late _MockNotificationService mockNotificationService;
  late AuthBloc authBloc;

  const testDeviceInfo = DeviceInfoData(
    deviceId: 'test-device-uuid',
    deviceName: 'Google Pixel 8',
    deviceModel: 'Pixel 8',
    osVersion: 'Android 14',
    appVersion: '1.0.0+1',
  );

  setUp(() {
    DeviceInfoUtil.setMockDeviceInfo(testDeviceInfo);
    mockRepository = _MockAuthRepository();
    mockNotificationService = _MockNotificationService();
    authBloc = AuthBloc(
      authRepository: mockRepository,
      notificationService: mockNotificationService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state is AuthInitial', () {
    expect(authBloc.state, equals(const AuthInitial()));
  });

  group('AuthCheckSessionRequested', () {
    test('emits [AuthSuccess] when saved token exists', () async {
      mockRepository.savedToken = 'valid-saved-token';

      final expectedStates = [
        const AuthSuccess(token: 'valid-saved-token', message: 'Sesi aktif ditemukan'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckSessionRequested());
    });

    test('emits [AuthInitial] when saved token is null', () async {
      mockRepository.savedToken = null;

      expectLater(authBloc.stream, emitsInOrder([const AuthInitial()]));

      authBloc.add(const AuthCheckSessionRequested());
    });

    test('emits [AuthInitial] when saved token is empty', () async {
      mockRepository.savedToken = '';

      expectLater(authBloc.stream, emitsInOrder([const AuthInitial()]));

      authBloc.add(const AuthCheckSessionRequested());
    });

    test('emits [AuthInitial] when repository throws error', () async {
      mockRepository.genericExceptionToThrow = Exception('Storage read corrupted');

      expectLater(authBloc.stream, emitsInOrder([const AuthInitial()]));

      authBloc.add(const AuthCheckSessionRequested());
    });
  });

  group('AuthLoginSubmitted', () {
    test('emits [AuthLoading, AuthSuccess] on successful login with trimmed email and device info', () async {
      final expectedStates = [
        const AuthLoading(),
        const AuthSuccess(token: 'mock-jwt-token-999'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLoginSubmitted(
        email: '  user@gmail.com  ',
        password: 'amaterasu',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepository.lastLoginRequest?.email, equals('user@gmail.com'));
      expect(mockRepository.lastLoginRequest?.password, equals('amaterasu'));
      expect(mockRepository.lastLoginRequest?.deviceId, equals('test-device-uuid'));
      expect(mockRepository.lastLoginRequest?.fcmToken, equals('mock-fcm-device-token'));
    });

    test('emits [AuthLoading, AuthFailure] when repository throws ApiException with statusCode', () async {
      mockRepository.apiExceptionToThrow = const ApiException(
        message: 'Kombinasi email atau password salah',
        statusCode: 401,
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure(
          message: 'Kombinasi email atau password salah',
          statusCode: 401,
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLoginSubmitted(
        email: 'user@gmail.com',
        password: 'wrong_password',
      ));
    });

    test('emits [AuthLoading, AuthFailure] when repository throws generic Exception', () async {
      mockRepository.genericExceptionToThrow = Exception('Network timeout');

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure(message: 'Terjadi kesalahan: Exception: Network timeout'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLoginSubmitted(
        email: 'user@gmail.com',
        password: 'password',
      ));
    });
  });

  group('AuthLogoutRequested', () {
    test('calls repository logout and emits [AuthInitial]', () async {
      expectLater(authBloc.stream, emitsInOrder([const AuthInitial()]));

      authBloc.add(const AuthLogoutRequested());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepository.logoutCalled, isTrue);
    });

    test('emits [AuthInitial] even when repository logout throws exception', () async {
      mockRepository.shouldThrowLogout = true;

      expectLater(authBloc.stream, emitsInOrder([const AuthInitial()]));

      authBloc.add(const AuthLogoutRequested());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepository.logoutCalled, isTrue);
    });
  });
}
