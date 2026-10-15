import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/warning_letter/data/datasources/warning_letter_remote_datasource.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:image_picker/image_picker.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;
  DioException? dioErrorToThrow;
  ApiException? apiExceptionToThrow;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'GET';
    lastQueryParams = queryParameters;
    if (apiExceptionToThrow != null) {
      throw apiExceptionToThrow!;
    }
    if (dioErrorToThrow != null) {
      throw dioErrorToThrow!;
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: mockResponseData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastMethod = 'POST';
    lastData = data;
    lastQueryParams = queryParameters;
    if (apiExceptionToThrow != null) {
      throw apiExceptionToThrow!;
    }
    if (dioErrorToThrow != null) {
      throw dioErrorToThrow!;
    }
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
  group('WarningLetterRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late WarningLetterRemoteDataSourceImpl dataSource;
    late Directory tempDir;
    late File testFile;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = WarningLetterRemoteDataSourceImpl(apiClient: mockApiClient);
      tempDir = Directory.systemTemp.createTempSync('wl_test_');
      testFile = File('${tempDir.path}/test_sp.pdf')..writeAsStringSync('dummy pdf');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getWarningLetters sends query params and parses WarningLetterListResponse', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'wl-1',
            'warningLetterType': {
              'level': 1,
              'name': 'SP 1',
            },
            'isActive': true,
            'createdAt': '2026-10-01T08:00:00Z',
            'timezone': 'WIB',
          }
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getWarningLetters(
        page: 1,
        size: 10,
        approver: true,
        letterTypeId: 'type-1',
        status: 'active',
        search: 'Terlambat',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.warningLetter));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(10));
      expect(mockApiClient.lastQueryParams?['approver'], isTrue);
      expect(mockApiClient.lastQueryParams?['letterTypeId'], equals('type-1'));
      expect(mockApiClient.lastQueryParams?['status'], equals('active'));
      expect(mockApiClient.lastQueryParams?['search'], equals('Terlambat'));
      expect(mockApiClient.lastQueryParams?['startDate'], equals('2026-10-01'));
      expect(mockApiClient.lastQueryParams?['endDate'], equals('2026-10-31'));
      expect(response.success, isTrue);
      expect(response.data.length, equals(1));
      expect(response.data.first.id, equals('wl-1'));
      expect(response.data.first.warningLetterType.name, equals('SP 1'));
    });

    test('getWarningLetterTypes parses list of types correctly', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {
            'id': 'wl-t-1',
            'name': 'SP 1',
            'level': 1,
            'validityPeriodMonths': 6,
          },
          {
            'id': 'wl-t-2',
            'name': 'SP 2',
            'level': 2,
            'validityPeriodMonths': 6,
          },
        ],
      };

      final types = await dataSource.getWarningLetterTypes();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.warningLetterType));
      expect(types.length, equals(2));
      expect(types.first.name, equals('SP 1'));
    });

    test('getLastWarningLetter parses last SP model', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'wl-prev-1',
          'referenceNumber': 'SP/2026/01',
          'issuedDate': '2026-05-01',
          'status': 'active',
          'warningLetterType': {
            'id': 'wl-t-1',
            'name': 'SP 1',
            'level': 1,
          },
        },
      };

      final lastWl = await dataSource.getLastWarningLetter('emp-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.lastWarningLetterByEmployee('emp-1')));
      expect(lastWl, isNotNull);
      expect(lastWl?.referenceNumber, equals('SP/2026/01'));
    });

    test('getLastWarningLetter returns null on 404 ApiException', () async {
      mockApiClient.apiExceptionToThrow = const ApiException(
        statusCode: 404,
        message: 'No previous warning letter',
      );

      final result = await dataSource.getLastWarningLetter('emp-none');

      expect(result, isNull);
    });

    test('createWarningLetter sends FormData and returns response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Surat peringatan diterbitkan',
        'data': {
          'id': 'new-wl-id',
          'referenceNumber': 'SP/2026/10/001',
        },
      };

      final request = CreateWarningLetterRequest(
        employeeId: 'emp-101',
        warningLetterTypeId: 'wl-t-1',
        reason: 'Indisipliner',
        issuedDate: '2026-10-15',
        sanction: 'Potong tunjangan',
        file: XFile(testFile.path),
      );

      final result = await dataSource.createWarningLetter(request);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.warningLetter));
      expect(mockApiClient.lastData, isA<FormData>());
      expect(result.success, isTrue);
      expect(result.data?.referenceNumber, equals('SP/2026/10/001'));
    });

    test('getWarningLetterDetail fetches and parses detail', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Detail SP dimuat',
        'data': {
          'id': 'wl-101',
          'referenceNumber': 'SP/001',
          'infractionReason': 'Absen tanpa izin',
          'issuedDate': '2026-10-01',
          'expiredDate': '2027-04-01',
          'warningLetterType': {
            'level': 1,
            'name': 'SP 1',
          },
          'employee': {
            'id': 'emp-1',
            'firstName': 'Budi',
          },
        },
      };

      final detail = await dataSource.getWarningLetterDetail('wl-101');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.warningLetterDetail('wl-101')));
      expect(detail.id, equals('wl-101'));
      expect(detail.referenceNumber, equals('SP/001'));
      expect(detail.infractionReason, equals('Absen tanpa izin'));
    });

    test('throws Exception on invalid response formats', () async {
      mockApiClient.mockResponseData = 'Invalid string';

      expect(
        () => dataSource.getWarningLetters(page: 1, size: 10, approver: false),
        throwsA(isA<Exception>()),
      );
      expect(
        () => dataSource.getWarningLetterDetail('wl-101'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
