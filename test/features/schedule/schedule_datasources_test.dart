import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/schedule/data/datasources/work_schedule_remote_datasource.dart';

class _MockApiClient implements ApiClient {
  late final Dio _mockDio;
  String? lastPath;
  String? lastMethod;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;
  DioException? dioErrorToThrow;

  _MockApiClient() {
    _mockDio = Dio(BaseOptions());
    _mockDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          lastPath = options.path;
          lastQueryParams = options.queryParameters;
          if (dioErrorToThrow != null) {
            return handler.reject(dioErrorToThrow!);
          }
          return handler.resolve(
            Response(
              requestOptions: options,
              data: mockResponseData,
              statusCode: 200,
            ),
          );
        },
      ),
    );
  }

  @override
  Dio get dio => _mockDio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('WorkScheduleRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late WorkScheduleRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = WorkScheduleRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getWorkSchedule fetches schedule without employeeId', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'sch-data-1',
          'employee': {
            'id': 'emp-1',
            'name': 'Budi',
          },
          'workSchedules': [
            {
              'id': 'sch-item-1',
              'date': '2026-10-15',
              'shiftName': 'Regular Morning',
              'startTime': '08:00',
              'endTime': '17:00',
              'isDayOff': false,
            }
          ],
        },
      };

      final response = await dataSource.getWorkSchedule();

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeWorkSchedule));
      expect(mockApiClient.lastQueryParams?.isEmpty ?? true, isTrue);
      expect(response.success, isTrue);
      expect(response.data?.id, equals('sch-data-1'));
      expect(response.data?.workSchedules.length, equals(1));
    });

    test('getWorkSchedule includes employeeId in query parameters when specified', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'sch-data-2',
          'workSchedules': [],
        },
      };

      final response = await dataSource.getWorkSchedule(employeeId: 'emp-99');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.employeeWorkSchedule));
      expect(mockApiClient.lastQueryParams?['employeeId'], equals('emp-99'));
      expect(response.success, isTrue);
    });

    test('throws ApiException on DioException', () async {
      mockApiClient.dioErrorToThrow = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: ApiEndpoints.employeeWorkSchedule),
        response: Response(
          requestOptions: RequestOptions(path: ApiEndpoints.employeeWorkSchedule),
          statusCode: 404,
          data: {'message': 'Jadwal kerja tidak ditemukan'},
        ),
      );

      await expectLater(
        dataSource.getWorkSchedule(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Jadwal kerja tidak ditemukan'),
        ),
      );
    });
  });
}
