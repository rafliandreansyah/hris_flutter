import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/announcement/data/datasources/announcement_remote_datasource.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;
  Exception? errorToThrow;

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
    if (errorToThrow != null) throw errorToThrow!;
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
    if (errorToThrow != null) throw errorToThrow!;
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
  group('AnnouncementRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late AnnouncementRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = AnnouncementRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getAnnouncements sends query params and parses AnnouncementListResponse', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'ann-1',
            'title': 'Libur Lebaran 2026',
            'summary': 'Pengumuman cuti bersama',
            'content': '<p>Informasi cuti bersama lebaran</p>',
            'priority': 'high',
            'category': 'company',
            'isPinned': true,
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getAnnouncements(
        page: 1,
        size: 10,
        search: 'Lebaran',
        category: 'company',
        priority: 'high',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.announcement));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(10));
      expect(mockApiClient.lastQueryParams?['search'], equals('Lebaran'));
      expect(mockApiClient.lastQueryParams?['category'], equals('company'));
      expect(mockApiClient.lastQueryParams?['priority'], equals('high'));
      expect(response.data.length, equals(1));
      expect(response.data.first.title, equals('Libur Lebaran 2026'));
      expect(response.data.first.isPinned, isTrue);
    });

    test('getAnnouncements ignores all / semua filters', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [],
        'meta': {'page': 1, 'size': 10, 'total': 0, 'totalPages': 1},
      };

      await dataSource.getAnnouncements(
        page: 1,
        size: 10,
        category: 'all',
        priority: 'semua',
      );

      expect(mockApiClient.lastQueryParams?.containsKey('category'), isFalse);
      expect(mockApiClient.lastQueryParams?.containsKey('priority'), isFalse);
    });

    test('getAnnouncements throws ApiException when data format is invalid', () async {
      mockApiClient.mockResponseData = 'invalid format';

      expect(
        () => dataSource.getAnnouncements(page: 1, size: 10),
        throwsA(isA<ApiException>()),
      );
    });

    test('getAnnouncementDetail sends GET and parses detail response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'ann-1',
          'title': 'Townhall Q3',
          'content': '<p>Semua staf wajib hadir</p>',
          'priority': 'urgent',
          'category': 'general',
          'attachments': [
            {
              'id': 'att-1',
              'fileName': 'agenda.pdf',
              'fileUrl': 'https://example.com/agenda.pdf',
              'fileSize': 1024,
            }
          ],
        },
      };

      final response = await dataSource.getAnnouncementDetail('ann-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.announcementDetail('ann-1')));
      expect(response.data.id, equals('ann-1'));
      expect(response.data.title, equals('Townhall Q3'));
      expect(response.data.attachments.length, equals(1));
      expect(response.data.attachments.first.fileName, equals('agenda.pdf'));
    });

    test('getAnnouncementDetail throws ApiException on error', () async {
      mockApiClient.mockResponseData = null;

      expect(
        () => dataSource.getAnnouncementDetail('ann-1'),
        throwsA(isA<ApiException>()),
      );
    });

    test('acknowledgeAnnouncement sends POST and parses response', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'Pengumuman berhasil dikonfirmasi',
        'data': {
          'message': 'Acknowledged successfully',
          'acknowledgedAt': '2026-10-14T08:00:00Z',
        },
      };

      final response = await dataSource.acknowledgeAnnouncement('ann-1');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.announcementAcknowledge('ann-1')));
      expect(response.success, isTrue);
      expect(response.data.message, equals('Acknowledged successfully'));
    });

    test('acknowledgeAnnouncement throws ApiException on invalid format', () async {
      mockApiClient.mockResponseData = 'invalid';

      expect(
        () => dataSource.acknowledgeAnnouncement('ann-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
