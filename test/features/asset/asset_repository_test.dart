import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/asset/data/datasources/asset_remote_datasource.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/repositories/asset_repository_impl.dart';

class _MockAssetRemoteDataSource implements AssetRemoteDataSource {
  int getAssetsCallCount = 0;
  int getAssetCategoriesCallCount = 0;
  int getAssetDetailCallCount = 0;
  int createAssetCallCount = 0;
  int handoverAssetCallCount = 0;
  int directTransferAssetCallCount = 0;
  int approveAssignmentCallCount = 0;
  int rejectAssignmentCallCount = 0;

  dynamic mockAssetsResponse;
  dynamic mockCategoriesResponse;
  dynamic mockDetailResponse;

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) async {
    getAssetsCallCount++;
    return mockAssetsResponse as AssetListResponse;
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async {
    getAssetCategoriesCallCount++;
    return mockCategoriesResponse as List<AssetCategoryModel>;
  }

  @override
  Future<AssetDetailData> getAssetDetail(String assetId) async {
    getAssetDetailCallCount++;
    return mockDetailResponse as AssetDetailData;
  }

  @override
  Future<void> createAsset(CreateAssetPayload payload) async {
    createAssetCallCount++;
  }

  @override
  Future<void> handoverAsset(String assetId, HandoverAssetPayload payload) async {
    handoverAssetCallCount++;
  }

  @override
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  ) async {
    directTransferAssetCallCount++;
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) async {
    approveAssignmentCallCount++;
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) async {
    rejectAssignmentCallCount++;
  }
}

void main() {
  group('AssetRepositoryImpl Tests', () {
    late _MockAssetRemoteDataSource mockRemoteDataSource;
    late AssetRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockAssetRemoteDataSource();
      repository = AssetRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    });

    test('getAssets delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockAssetsResponse = const AssetListResponse(
        success: true,
        message: 'Success',
        data: [
          AssetListItem(
            id: 'ast-1',
            assetCode: 'AST-001',
            name: 'Lenovo ThinkPad',
            status: 'AVAILABLE',
            condition: 'GOOD',
          ),
        ],
        meta: AssetPaginationMeta(page: 1, limit: 10, total: 1, totalPages: 1),
      );

      final result = await repository.getAssets(
        page: 1,
        size: 10,
        search: 'ThinkPad',
        categoryId: 'cat-01',
        status: 'AVAILABLE',
      );

      expect(mockRemoteDataSource.getAssetsCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.name, equals('Lenovo ThinkPad'));
    });

    test('getAssetCategories delegates to remote data source', () async {
      mockRemoteDataSource.mockCategoriesResponse = const [
        AssetCategoryModel(id: 'cat-1', name: 'Laptop', code: 'LAP'),
        AssetCategoryModel(id: 'cat-2', name: 'Monitor', code: 'MON'),
      ];

      final result = await repository.getAssetCategories(search: 'Lap');

      expect(mockRemoteDataSource.getAssetCategoriesCallCount, equals(1));
      expect(result.length, equals(2));
      expect(result.first.name, equals('Laptop'));
    });

    test('getAssetDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockDetailResponse = const AssetDetailData(
        id: 'ast-1',
        assetCode: 'AST-001',
        name: 'MacBook Pro M2',
        status: 'IN_USE',
        condition: 'GOOD',
      );

      final result = await repository.getAssetDetail('ast-1');

      expect(mockRemoteDataSource.getAssetDetailCallCount, equals(1));
      expect(result.id, equals('ast-1'));
      expect(result.name, equals('MacBook Pro M2'));
    });

    test('createAsset delegates to remote data source', () async {
      final payload = CreateAssetPayload(
        categoryId: 'cat-1',
        name: 'iPad Pro',
        assetCode: 'AST-009',
        serialNumber: 'SN-999',
        condition: 'GOOD',
        purchaseCost: 15000000,
        purchaseDate: DateTime(2026, 1, 1),
      );

      await repository.createAsset(payload);

      expect(mockRemoteDataSource.createAssetCallCount, equals(1));
    });

    test('handoverAsset delegates to remote data source', () async {
      final payload = HandoverAssetPayload(
        employeeId: 'emp-1',
        assignedDate: DateTime(2026, 1, 1),
        conditionOnCheckout: 'GOOD',
      );

      await repository.handoverAsset('ast-1', payload);

      expect(mockRemoteDataSource.handoverAssetCallCount, equals(1));
    });

    test('directTransferAsset delegates to remote data source', () async {
      final payload = DirectTransferAssetPayload(
        targetEmployeeId: 'emp-2',
        assignedDate: DateTime(2026, 1, 1),
        conditionOnCheckout: 'GOOD',
      );

      await repository.directTransferAsset('ast-1', payload);

      expect(mockRemoteDataSource.directTransferAssetCallCount, equals(1));
    });

    test('approveAssignment delegates to remote data source', () async {
      await repository.approveAssignment(
        assignmentId: 'assign-1',
        conditionOnCheckin: 'GOOD',
        recipientNotes: 'Approved and checked',
        signatureUrl: 'https://example.com/sig.png',
        handoverPhotoUrl: 'https://example.com/photo.png',
      );

      expect(mockRemoteDataSource.approveAssignmentCallCount, equals(1));
    });

    test('rejectAssignment delegates to remote data source', () async {
      await repository.rejectAssignment(
        assignmentId: 'assign-1',
        rejectionReason: 'Broken screen upon check',
      );

      expect(mockRemoteDataSource.rejectAssignmentCallCount, equals(1));
    });
  });
}
