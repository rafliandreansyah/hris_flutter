import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/network/interceptors/auth_interceptor.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';

class _FakeErrorInterceptorHandler extends ErrorInterceptorHandler {
  DioException? handledError;

  @override
  void next(DioException err) {
    handledError = err;
  }
}

class _FakeRequestInterceptorHandler extends RequestInterceptorHandler {
  RequestOptions? handledOptions;

  @override
  void next(RequestOptions options) {
    handledOptions = options;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthInterceptor Tests', () {
    late AuthInterceptor interceptor;
    bool unauthorizedCalled = false;
    const testDeviceInfo = DeviceInfoData(
      deviceId: 'test-device-id-xyz',
      deviceName: 'iPhone 15 Pro',
      deviceModel: 'iPhone16,1',
      osVersion: 'iOS 17.4',
      appVersion: '1.0.0+1',
    );

    setUp(() {
      unauthorizedCalled = false;
      interceptor = AuthInterceptor(
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
        cachedDeviceInfo: testDeviceInfo,
      );
    });

    test('attaches Authorization Bearer token to request headers if token is set', () {
      interceptor.setToken('test-jwt-token');
      final options = RequestOptions(path: '/employees');
      final handler = _FakeRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers[AppConstants.headerAuthorization], equals('Bearer test-jwt-token'));
      expect(options.headers[AppConstants.headerContentType], equals(AppConstants.jsonContentType));
      expect(options.headers[AppConstants.headerAccept], equals(AppConstants.jsonContentType));
    });

    test('clears Authorization Bearer token on clearToken', () {
      interceptor.setToken('test-jwt-token');
      interceptor.clearToken();
      final options = RequestOptions(path: '/employees');
      final handler = _FakeRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers[AppConstants.headerAuthorization], isNull);
    });

    test('calls onUnauthorized for HTTP 401 on authenticated endpoint', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.employees,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _FakeErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(unauthorizedCalled, isTrue);
      expect(handler.handledError, equals(dioException));
    });

    test('calls onUnauthorized for HTTP 401 on /auth/profile endpoint', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.authProfile,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _FakeErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(unauthorizedCalled, isTrue);
      expect(handler.handledError, equals(dioException));
    });

    test('does NOT call onUnauthorized for HTTP 401 on login endpoint (${ApiEndpoints.auth})', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.auth,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Password yang Anda masukkan salah.'},
        ),
      );
      final handler = _FakeErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(unauthorizedCalled, isFalse);
      expect(handler.handledError, equals(dioException));
    });

    test('does NOT call onUnauthorized for HTTP 401 on login endpoint (${ApiEndpoints.login})', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.login,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Invalid credentials'},
        ),
      );
      final handler = _FakeErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(unauthorizedCalled, isFalse);
      expect(handler.handledError, equals(dioException));
    });

    test('does NOT call onUnauthorized for HTTP 401 on forgot password endpoint', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.forgotPassword,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _FakeErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(unauthorizedCalled, isFalse);
      expect(handler.handledError, equals(dioException));
    });

    test('does NOT call onUnauthorized for HTTP 401 on reset password endpoint', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.resetPassword,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _FakeErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(unauthorizedCalled, isFalse);
      expect(handler.handledError, equals(dioException));
    });

    test('does NOT call onUnauthorized for non-401 HTTP status codes', () {
      for (final statusCode in [400, 403, 404, 422, 500]) {
        unauthorizedCalled = false;
        final requestOptions = RequestOptions(path: ApiEndpoints.employees);
        final dioException = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
          ),
        );
        final handler = _FakeErrorInterceptorHandler();

        interceptor.onError(dioException, handler);

        expect(unauthorizedCalled, isFalse, reason: 'Failed for status $statusCode');
      }
    });

    test('attaches telemetry & device tracking headers on request', () async {
      final options = RequestOptions(path: ApiEndpoints.employees);
      final handler = _FakeRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers[AppConstants.headerDeviceId], equals('test-device-id-xyz'));
      expect(options.headers[AppConstants.headerDeviceModel], equals('iPhone16,1'));
      expect(options.headers[AppConstants.headerOsVersion], equals('iOS 17.4'));
      expect(options.headers[AppConstants.headerAppVersion], equals('1.0.0+1'));
      expect(options.headers[AppConstants.headerPlatform], isNotNull);
    });

    test('attaches x-platform as mobile_ios when getPlatform returns mobile_ios', () async {
      final iosInterceptor = AuthInterceptor(
        cachedDeviceInfo: testDeviceInfo,
        getPlatform: () => 'mobile_ios',
      );
      final options = RequestOptions(path: ApiEndpoints.employees);
      final handler = _FakeRequestInterceptorHandler();

      iosInterceptor.onRequest(options, handler);

      expect(options.headers['x-platform'], equals('mobile_ios'));
    });

    test('attaches x-platform as mobile_android when getPlatform returns mobile_android', () async {
      final androidInterceptor = AuthInterceptor(
        cachedDeviceInfo: testDeviceInfo,
        getPlatform: () => 'mobile_android',
      );
      final options = RequestOptions(path: ApiEndpoints.employees);
      final handler = _FakeRequestInterceptorHandler();

      androidInterceptor.onRequest(options, handler);

      expect(options.headers['x-platform'], equals('mobile_android'));
    });

    test('caches DeviceInfoData and only calls getDeviceInfo once across multiple requests', () async {
      int getDeviceInfoCallCount = 0;
      final cachingInterceptor = AuthInterceptor(
        getDeviceInfo: () async {
          getDeviceInfoCallCount++;
          return testDeviceInfo;
        },
      );

      final handler1 = _FakeRequestInterceptorHandler();
      final options1 = RequestOptions(path: ApiEndpoints.employees);
      cachingInterceptor.onRequest(options1, handler1);
      // Wait for async execution
      await Future<void>.delayed(Duration.zero);

      expect(getDeviceInfoCallCount, equals(1));
      expect(options1.headers[AppConstants.headerDeviceId], equals('test-device-id-xyz'));
      expect(cachingInterceptor.cachedDeviceInfo, equals(testDeviceInfo));

      final handler2 = _FakeRequestInterceptorHandler();
      final options2 = RequestOptions(path: ApiEndpoints.employeeDashboard);
      cachingInterceptor.onRequest(options2, handler2);
      await Future<void>.delayed(Duration.zero);

      expect(getDeviceInfoCallCount, equals(1), reason: 'getDeviceInfo should not be called again after caching');
      expect(options2.headers[AppConstants.headerDeviceId], equals('test-device-id-xyz'));
    });
  });
}
