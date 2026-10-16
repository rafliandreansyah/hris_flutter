import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/interceptors/auth_interceptor.dart';
import 'package:hris_flutter/core/network/token_refresher.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';

typedef _Handler = Future<ResponseBody> Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  final _Handler handler;
  final List<RequestOptions> requests = [];

  _FakeAdapter(this.handler);

  int countPath(String path) =>
      requests.where((r) => r.uri.path.endsWith(path)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody _refreshOk({String access = 'new-access', String refresh = 'new-refresh'}) =>
    _json({
      'success': true,
      'data': {
        'token': access,
        'refreshToken': refresh,
        'refreshTokenExpiresAt': '2027-01-01T00:00:00Z',
      },
    }, 200);

const _device = DeviceInfoData(
  deviceId: 'device-12345',
  deviceName: 'Pixel',
  deviceModel: 'Pixel 8',
  osVersion: 'Android 15',
  appVersion: '1.0.0+1',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureStorageService.instance;
  });

  Dio refreshDio(_FakeAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;

  group('TokenRefresher', () {
    test('sukses: simpan access+refresh baru, kirim deviceId, panggil callback', () async {
      await storage.saveRefreshToken('old-refresh');
      final adapter = _FakeAdapter((_) async => _refreshOk());
      String? notified;
      final refresher = TokenRefresher(
        dio: refreshDio(adapter),
        storage: storage,
        deviceIdProvider: () async => 'device-12345',
        onTokenRefreshed: (t) => notified = t,
      );

      expect(await refresher.refresh(), RefreshResult.success);

      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/v1${ApiEndpoints.authRefresh}');
      expect(req.data, {'refreshToken': 'old-refresh', 'deviceId': 'device-12345'});
      expect(await storage.getAccessToken(), 'new-access');
      expect(await storage.getRefreshToken(), 'new-refresh');
      expect(notified, 'new-access');
    });

    test('tanpa refresh token tersimpan: rejected tanpa request jaringan', () async {
      final adapter = _FakeAdapter((_) async => _refreshOk());
      final refresher = TokenRefresher(
        dio: refreshDio(adapter),
        storage: storage,
        deviceIdProvider: () async => 'device-12345',
      );

      expect(await refresher.refresh(), RefreshResult.rejected);
      expect(adapter.requests, isEmpty);
    });

    for (final status in [400, 401, 403, 404]) {
      test('server menolak ($status): rejected dan token lama tidak diubah', () async {
        await storage.saveRefreshToken('old-refresh');
        await storage.saveAccessToken('old-access');
        final adapter = _FakeAdapter((_) async => _json({'success': false}, status));
        final refresher = TokenRefresher(
          dio: refreshDio(adapter),
          storage: storage,
          deviceIdProvider: () async => 'device-12345',
        );

        expect(await refresher.refresh(), RefreshResult.rejected);
        expect(await storage.getRefreshToken(), 'old-refresh');
        expect(await storage.getAccessToken(), 'old-access');
      });
    }

    for (final status in [429, 500, 502, 503]) {
      test('gangguan server ($status): unavailable, sesi tidak dianggap berakhir', () async {
        await storage.saveRefreshToken('old-refresh');
        final adapter = _FakeAdapter((_) async => _json({'success': false}, status));
        final refresher = TokenRefresher(
          dio: refreshDio(adapter),
          storage: storage,
          deviceIdProvider: () async => 'device-12345',
        );

        expect(await refresher.refresh(), RefreshResult.unavailable);
        expect(await storage.getRefreshToken(), 'old-refresh');
      });
    }

    test('tanpa jaringan (connection error): unavailable', () async {
      await storage.saveRefreshToken('old-refresh');
      final adapter = _FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final refresher = TokenRefresher(
        dio: refreshDio(adapter),
        storage: storage,
        deviceIdProvider: () async => 'device-12345',
      );

      expect(await refresher.refresh(), RefreshResult.unavailable);
    });

    test('respons 200 tanpa token valid: rejected', () async {
      await storage.saveRefreshToken('old-refresh');
      final adapter = _FakeAdapter((_) async => _json({'success': true, 'data': {}}, 200));
      final refresher = TokenRefresher(
        dio: refreshDio(adapter),
        storage: storage,
        deviceIdProvider: () async => 'device-12345',
      );

      expect(await refresher.refresh(), RefreshResult.rejected);
    });

    test('single-flight: pemanggilan bersamaan hanya satu request refresh', () async {
      await storage.saveRefreshToken('old-refresh');
      final adapter = _FakeAdapter((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _refreshOk();
      });
      final refresher = TokenRefresher(
        dio: refreshDio(adapter),
        storage: storage,
        deviceIdProvider: () async => 'device-12345',
      );

      final results = await Future.wait([
        refresher.refresh(),
        refresher.refresh(),
        refresher.refresh(),
      ]);

      expect(results, everyElement(RefreshResult.success));
      expect(adapter.countPath(ApiEndpoints.authRefresh), 1);
      expect(refresher.isRefreshing, isFalse);
    });

    test('deviceId terlalu pendek / gagal dibaca tidak dikirim', () async {
      await storage.saveRefreshToken('old-refresh');
      final adapter = _FakeAdapter((_) async => _refreshOk());
      final refresher = TokenRefresher(
        dio: refreshDio(adapter),
        storage: storage,
        deviceIdProvider: () async => throw Exception('tidak tersedia'),
      );

      await refresher.refresh();

      expect(adapter.requests.single.data, {'refreshToken': 'old-refresh'});
    });
  });

  group('AuthInterceptor + refresh token (alur 401)', () {
    late Dio dio;
    late AuthInterceptor interceptor;
    late _FakeAdapter adapter;
    late int unauthorizedCalls;
    late List<String?> authHeadersSeen;

    /// Menyusun Dio dengan server palsu: endpoint `/data` mengembalikan 401 untuk
    /// token `expired-token` dan 200 untuk token lain.
    Future<void> build({
      _Handler? refreshHandler,
      String initialToken = 'expired-token',
      bool withRefreshToken = true,
      int Function(String token)? dataStatus,
    }) async {
      if (withRefreshToken) await storage.saveRefreshToken('refresh-1');
      unauthorizedCalls = 0;
      authHeadersSeen = [];
      adapter = _FakeAdapter((options) async {
        if (options.uri.path.endsWith(ApiEndpoints.authRefresh)) {
          return refreshHandler != null ? refreshHandler(options) : _refreshOk();
        }
        final auth = options.headers['Authorization'] as String?;
        authHeadersSeen.add(auth);
        final token = auth?.replaceFirst('Bearer ', '') ?? '';
        final status = dataStatus != null
            ? dataStatus(token)
            : (token == 'expired-token' ? 401 : 200);
        return _json({'success': status == 200, 'message': 'status $status'}, status);
      });

      dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = adapter;

      final refresher = TokenRefresher(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
          ..httpClientAdapter = adapter,
        storage: storage,
        deviceIdProvider: () async => 'device-12345',
        onTokenRefreshed: (t) => interceptor.setToken(t),
      );
      interceptor = AuthInterceptor(
        cachedDeviceInfo: _device,
        getPlatform: () => 'mobile_android',
        onUnauthorized: () => unauthorizedCalls++,
        tokenRefresher: refresher,
        dioProvider: () => dio,
      );
      interceptor.setToken(initialToken);
      dio.interceptors.add(interceptor);
    }

    test('401 -> refresh sukses -> request diulang dengan token baru (tanpa logout)', () async {
      await build();

      final response = await dio.get<dynamic>('/data');

      expect(response.statusCode, 200);
      expect(unauthorizedCalls, 0);
      expect(adapter.countPath(ApiEndpoints.authRefresh), 1);
      expect(authHeadersSeen, ['Bearer expired-token', 'Bearer new-access']);
      expect(await storage.getRefreshToken(), 'new-refresh');
      expect(await storage.getAccessToken(), 'new-access');
    });

    test('refresh ditolak -> onUnauthorized dipanggil dan error 401 diteruskan', () async {
      await build(refreshHandler: (_) async => _json({'success': false}, 401));

      await expectLater(
        dio.get<dynamic>('/data'),
        throwsA(
          isA<DioException>().having((e) => e.response?.statusCode, 'status', 401),
        ),
      );

      expect(unauthorizedCalls, 1);
      expect(adapter.countPath('/data'), 1, reason: 'request tidak diulang bila refresh ditolak');
    });

    test('tanpa refresh token tersimpan -> langsung logout (perilaku lama)', () async {
      await build(withRefreshToken: false);

      await expectLater(dio.get<dynamic>('/data'), throwsA(isA<DioException>()));

      expect(unauthorizedCalls, 1);
      expect(adapter.countPath(ApiEndpoints.authRefresh), 0);
    });

    test('server refresh bermasalah (500) -> TIDAK logout, error asli diteruskan', () async {
      await build(refreshHandler: (_) async => _json({'success': false}, 500));

      await expectLater(
        dio.get<dynamic>('/data'),
        throwsA(
          isA<DioException>().having((e) => e.response?.statusCode, 'status', 401),
        ),
      );

      expect(unauthorizedCalls, 0);
      expect(await storage.getRefreshToken(), 'refresh-1');
    });

    test('token baru pun ditolak (401 setelah retry) -> logout, tanpa loop', () async {
      await build(dataStatus: (_) => 401);

      await expectLater(dio.get<dynamic>('/data'), throwsA(isA<DioException>()));

      expect(unauthorizedCalls, 1);
      expect(adapter.countPath(ApiEndpoints.authRefresh), 1);
      expect(adapter.countPath('/data'), 2);
    });

    test('banyak request 401 bersamaan -> satu refresh, semua berhasil', () async {
      await build(refreshHandler: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _refreshOk();
      });

      final responses = await Future.wait([
        dio.get<dynamic>('/data'),
        dio.get<dynamic>('/data'),
        dio.get<dynamic>('/data'),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(adapter.countPath(ApiEndpoints.authRefresh), 1);
      expect(unauthorizedCalls, 0);
    });

    test('request yang tokennya sudah usang diulang tanpa refresh tambahan', () async {
      await build();
      interceptor.setToken('expired-token');

      // Refresh pertama memperbarui token di memori.
      await dio.get<dynamic>('/data');
      expect(adapter.countPath(ApiEndpoints.authRefresh), 1);

      // Request yang "terlambat" 401 dengan token lama: tidak memicu refresh kedua.
      final stale = RequestOptions(
        path: '/data',
        baseUrl: 'https://api.test/api/v1',
        headers: {'Authorization': 'Bearer expired-token'},
      );
      final handler = _CapturingErrorHandler();
      interceptor.onError(
        DioException(
          requestOptions: stale,
          response: Response(requestOptions: stale, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
        handler,
      );
      await handler.done;

      expect(adapter.countPath(ApiEndpoints.authRefresh), 1);
      expect(handler.resolved?.statusCode, 200);
    });

    test('POST multipart (FormData) diulang utuh setelah refresh', () async {
      await build();

      final form = FormData.fromMap({
        'note': 'halo',
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.jpg'),
      });
      final response = await dio.post<dynamic>('/upload', data: form);

      expect(response.statusCode, 200);
      expect(adapter.countPath('/upload'), 2);
      final retried = adapter.requests.where((r) => r.uri.path.endsWith('/upload')).last;
      expect(retried.data, isA<FormData>());
      expect((retried.data as FormData).fields.single.value, 'halo');
      expect((retried.data as FormData).files, hasLength(1));
    });

    test('401 pada endpoint login/publik tidak memicu refresh maupun logout', () async {
      await build(dataStatus: (_) => 401);

      for (final path in [
        ApiEndpoints.auth,
        ApiEndpoints.resetPassword,
        ApiEndpoints.logout,
        ApiEndpoints.authRefresh,
      ]) {
        adapter = _FakeAdapter((_) async => _json({'success': false}, 401));
        dio.httpClientAdapter = adapter;
        await expectLater(dio.post<dynamic>(path), throwsA(isA<DioException>()), reason: path);
      }

      expect(unauthorizedCalls, 0);
    });

    test('error selain 401 tidak disentuh interceptor', () async {
      await build(dataStatus: (_) => 500);

      await expectLater(
        dio.get<dynamic>('/data'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 500)),
      );

      expect(unauthorizedCalls, 0);
      expect(adapter.countPath(ApiEndpoints.authRefresh), 0);
    });
  });
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  Response<dynamic>? resolved;
  DioException? error;
  final _completer = Future<void>.value();

  Future<void> get done async {
    // Beri kesempatan future di dalam onError selesai.
    for (var i = 0; i < 50 && resolved == null && error == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await _completer;
  }

  @override
  void resolve(Response<dynamic> response) => resolved = response;

  @override
  void next(DioException err) => error = err;
}
