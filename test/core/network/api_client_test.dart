import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient Tests', () {
    late ApiClient apiClient;
    late HttpClientAdapter originalAdapter;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      apiClient = ApiClient.instance;
      originalAdapter = apiClient.dio.httpClientAdapter;
    });

    tearDown(() {
      apiClient.dio.httpClientAdapter = originalAdapter;
      apiClient.clearAuthToken();
    });

    test('singleton pattern returns the exact same instance', () {
      final client1 = ApiClient();
      final client2 = ApiClient.instance;

      expect(identical(client1, client2), isTrue);
    });

    test('dio base options configured correctly', () {
      final dio = apiClient.dio;

      expect(dio.options.baseUrl, equals(ApiEndpoints.baseUrl));
      expect(dio.options.connectTimeout, equals(AppConstants.connectTimeout));
      expect(dio.options.receiveTimeout, equals(AppConstants.receiveTimeout));
      expect(dio.options.sendTimeout, equals(AppConstants.sendTimeout));
      expect(
        dio.options.headers[AppConstants.headerContentType],
        equals(AppConstants.jsonContentType),
      );
    });

    test('setAuthToken menyisipkan header Bearer dan clearAuthToken menghapusnya', () async {
      final seenAuth = <String?>[];
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        seenAuth.add(options.headers[AppConstants.headerAuthorization] as String?);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiClient.setAuthToken('test-token-12345');
      expect(apiClient.hasAuthToken, isTrue);
      await apiClient.get('/with-token');

      apiClient.clearAuthToken();
      expect(apiClient.hasAuthToken, isFalse);
      await apiClient.get('/without-token');

      expect(seenAuth.first, '${AppConstants.headerBearerPrefix}test-token-12345');
      expect(seenAuth.last, isNull);
    });

    test('query parameters diteruskan ke request', () async {
      Map<String, dynamic>? seenQuery;
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        seenQuery = options.queryParameters;
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await apiClient.get('/q', queryParameters: {'page': 2, 'size': 30});

      expect(seenQuery, {'page': 2, 'size': 30});
    });

    test('GET request returns successful Response on 200 OK', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.method, 'GET');
        expect(options.path, contains('/test-path'));
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': 'ok'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiClient.get<Map<String, dynamic>>('/test-path');

      expect(response.statusCode, 200);
      expect(response.data?['success'], isTrue);
    });

    test('POST request sends payload and returns Response', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.method, 'POST');
        expect(options.data, equals({'name': 'Test'}));
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Created'}),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiClient.post<Map<String, dynamic>>(
        '/create-test',
        data: {'name': 'Test'},
      );

      expect(response.statusCode, 201);
      expect(response.data?['message'], equals('Created'));
    });

    test('PUT request sends payload and returns Response', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.method, 'PUT');
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Updated'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiClient.put<Map<String, dynamic>>(
        '/update-test',
        data: {'status': 'active'},
      );

      expect(response.statusCode, 200);
      expect(response.data?['message'], equals('Updated'));
    });

    test('PATCH request sends payload and returns Response', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.method, 'PATCH');
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Patched'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiClient.patch<Map<String, dynamic>>(
        '/patch-test',
        data: {'active': true},
      );

      expect(response.statusCode, 200);
      expect(response.data?['message'], equals('Patched'));
    });

    test('DELETE request executes successfully and returns Response', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.method, 'DELETE');
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'message': 'Deleted'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiClient.delete<Map<String, dynamic>>('/delete-test');

      expect(response.statusCode, 200);
      expect(response.data?['message'], equals('Deleted'));
    });

    test('throws ApiException on HTTP 400 Bad Request with backend message', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Data permohonan tidak lengkap'}),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      expect(
        () => apiClient.get('/fail-endpoint'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Data permohonan tidak lengkap'),
        ),
      );
    });

    test('throws ApiException on DioException connection timeout', () async {
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        );
      });

      await expectLater(
        apiClient.get('/timeout-endpoint'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 408)
              .having((e) => e.type, 'type', DioExceptionType.connectionTimeout),
        ),
      );
    });

    test('POST tidak di-retry saat timeout (hanya 1 percobaan)', () async {
      var attempts = 0;
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        attempts++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      await expectLater(
        apiClient.post('/no-retry', data: {'a': 1}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 408)),
      );
      expect(attempts, 1);
    });

    test('GET di-retry saat 503 lalu sukses', () async {
      var attempts = 0;
      apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
        attempts++;
        if (attempts == 1) {
          return ResponseBody.fromString(
            jsonEncode({'message': 'Service Unavailable'}),
            503,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiClient.get<Map<String, dynamic>>('/flaky');

      expect(attempts, 2);
      expect(response.data?['success'], isTrue);
    });

    for (final entry in {
      401: 'Unauthorized',
      403: 'Anda tidak punya akses',
      404: 'Data tidak ditemukan',
      422: 'Data tidak valid',
      500: 'Kesalahan server',
    }.entries) {
      test('HTTP ${entry.key} menjadi ApiException dengan statusCode & pesan backend', () async {
        apiClient.dio.httpClientAdapter = _FakeAdapter((options) async {
          return ResponseBody.fromString(
            jsonEncode({'message': entry.value}),
            entry.key,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        await expectLater(
          apiClient.post('/err-${entry.key}', data: {}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', entry.key)
                .having((e) => e.message, 'message', contains(entry.value)),
          ),
        );
      });
    }
  });
}
