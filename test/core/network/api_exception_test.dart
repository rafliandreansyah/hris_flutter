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

    DioException badResponse(int status, dynamic data) {
      final requestOptions = RequestOptions(
        path: '/leave-request/1/approve',
        baseUrl: 'https://apidev.hroasish.com/api/v1',
      );
      return DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: status,
          data: data,
        ),
      );
    }

    test('maps 409 to the backend message and exposes the server code', () {
      final exception = ApiException.fromDioException(
        badResponse(409, {
          'message': 'Pengajuan sudah diproses.',
          'code': 'ALREADY_PROCESSED',
        }),
      );

      expect(exception.statusCode, equals(409));
      expect(exception.message, equals('Pengajuan sudah diproses.'));
      expect(exception.code, equals('ALREADY_PROCESSED'));
    });

    test('uses a friendly fallback message on 409 without backend message', () {
      final exception = ApiException.fromDioException(badResponse(409, null));

      expect(exception.statusCode, equals(409));
      expect(exception.message, contains('sudah diproses'));
      expect(exception.code, isNull);
    });

    test('code is null when the backend does not send a string code', () {
      final exception = ApiException.fromDioException(
        badResponse(400, {'message': 'Input salah', 'code': 123}),
      );

      expect(exception.code, isNull);
      expect(exception.message, equals('Input salah'));
    });
  });
}
