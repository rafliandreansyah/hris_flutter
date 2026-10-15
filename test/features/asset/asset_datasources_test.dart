import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/asset/data/datasources/asset_remote_datasource.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';

class _MockApiClient implements ApiClient {
  String? lastPath;
  String? lastMethod;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;
  dynamic mockResponseData;

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
  group('AssetRemoteDataSourceImpl Tests', () {
    late _MockApiClient mockApiClient;
    late AssetRemoteDataSourceImpl dataSource;

    setUp(() {
      mockApiClient = _MockApiClient();
      dataSource = AssetRemoteDataSourceImpl(apiClient: mockApiClient);
    });

    test('getAssets sends query params and parses AssetListResponse', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'ast-01',
            'assetCode': 'AST-001',
            'name': 'MacBook Pro',
            'status': 'AVAILABLE',
            'condition': 'GOOD',
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      };

      final response = await dataSource.getAssets(
        page: 1,
        size: 10,
        search: 'MacBook',
        categoryId: 'cat-1',
        status: 'AVAILABLE',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assets));
      expect(mockApiClient.lastQueryParams?['page'], equals(1));
      expect(mockApiClient.lastQueryParams?['size'], equals(10));
      expect(mockApiClient.lastQueryParams?['search'], equals('MacBook'));
      expect(mockApiClient.lastQueryParams?['categoryId'], equals('cat-1'));
      expect(mockApiClient.lastQueryParams?['status'], equals('AVAILABLE'));
      expect(response.data.length, equals(1));
      expect(response.data.first.name, equals('MacBook Pro'));
    });

    test('getAssetCategories fetches category list', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': [
          {'id': 'cat-1', 'name': 'Laptop', 'code': 'LAPTOP'},
        ],
      };

      final categories = await dataSource.getAssetCategories(search: 'Laptop');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assetCategories));
      expect(mockApiClient.lastQueryParams?['search'], equals('Laptop'));
      expect(categories.length, equals(1));
      expect(categories.first.name, equals('Laptop'));
    });

    test('getAssetDetail fetches detail by assetId', () async {
      mockApiClient.mockResponseData = {
        'success': true,
        'data': {
          'id': 'ast-01',
          'companyId': 'comp-1',
          'categoryId': 'cat-1',
          'assetCode': 'AST-001',
          'name': 'MacBook Pro',
          'status': 'AVAILABLE',
          'condition': 'GOOD',
          'assignments': [],
        },
      };

      final detail = await dataSource.getAssetDetail('ast-01');

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assetDetail('ast-01')));
      expect(detail.id, equals('ast-01'));
      expect(detail.name, equals('MacBook Pro'));
    });

    test('createAsset sends POST to assets endpoint', () async {
      mockApiClient.mockResponseData = {'success': true};

      const payload = CreateAssetPayload(
        categoryId: 'cat-1',
        assetCode: 'AST-NEW',
        name: 'Dell Monitor',
      );

      await dataSource.createAsset(payload);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assets));
      expect(mockApiClient.lastData['name'], equals('Dell Monitor'));
    });

    test('handoverAsset sends POST to handover endpoint', () async {
      mockApiClient.mockResponseData = {'success': true};

      final payload = HandoverAssetPayload(
        employeeId: 'emp-1',
        assignedDate: DateTime(2026, 1, 1),
        conditionOnCheckout: 'GOOD',
      );

      await dataSource.handoverAsset('ast-01', payload);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assetHandover('ast-01')));
      expect(mockApiClient.lastData['employeeId'], equals('emp-1'));
    });

    test('directTransferAsset sends POST to transfer endpoint', () async {
      mockApiClient.mockResponseData = {'success': true};

      final payload = DirectTransferAssetPayload(
        targetEmployeeId: 'emp-2',
        assignedDate: DateTime(2026, 1, 1),
        conditionOnCheckout: 'GOOD',
      );

      await dataSource.directTransferAsset('ast-01', payload);

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assetTransfer('ast-01')));
      expect(mockApiClient.lastData['targetEmployeeId'], equals('emp-2'));
    });

    test('approveAssignment sends POST with notes and signatures', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.approveAssignment(
        assignmentId: 'asg-01',
        conditionOnCheckin: 'GOOD',
        recipientNotes: 'Diterima lengkap',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assetApprove('asg-01')));
      expect(mockApiClient.lastData['recipientNotes'], equals('Diterima lengkap'));
    });

    test('rejectAssignment sends POST with rejectionReason', () async {
      mockApiClient.mockResponseData = {'success': true};

      await dataSource.rejectAssignment(
        assignmentId: 'asg-01',
        rejectionReason: 'Layar retak',
      );

      expect(mockApiClient.lastPath, equals(ApiEndpoints.assetReject('asg-01')));
      expect(mockApiClient.lastData['rejectionReason'], equals('Layar retak'));
    });
  });
}
