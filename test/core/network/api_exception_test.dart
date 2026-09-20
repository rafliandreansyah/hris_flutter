import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';

void main() {
  group('ApiException Tests', () {
    test('uses backend message when responseData contains message on 401', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.auth,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'message': 'Kata sandi yang Anda masukkan salah.'},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, equals(401));
      expect(exception.message, equals('Kata sandi yang Anda masukkan salah.'));
    });

    test('uses backend error field when responseData contains error on 401', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.login,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'error': 'Kredensial tidak valid'},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, equals(401));
      expect(exception.message, equals('Kredensial tidak valid'));
    });

    test('falls back to login specific message on 401 when no backend message provided', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.auth,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, equals(401));
      expect(exception.message, equals('Email atau kata sandi salah.'));
    });

    test('falls back to session expired message on 401 for authenticated endpoints when no backend message provided', () {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.employees,
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, equals(401));
      expect(exception.message, equals('Sesi Anda telah berakhir. Silakan login kembali.'));
    });

    test('handles 400 Bad Request fallback message', () {
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, equals(400));
      expect(exception.message, equals('Permintaan data tidak valid (Bad Request).'));
    });

    test('handles timeout errors correctly', () {
      final requestOptions = RequestOptions(path: '/test');
      final connectionTimeout = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(connectionTimeout);

      expect(exception.message, contains('timeout'));
    });
  });
}
