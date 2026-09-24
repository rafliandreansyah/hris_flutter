import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_filter_criteria.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_state.dart';

class _MockAssetRepository implements AssetRepository {
  Future<AssetListResponse> Function({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  })? onGetAssets;

  Future<List<AssetCategoryModel>> Function({String? search})?
      onGetAssetCategories;

  Future<void> Function({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  })? onApproveAssignment;

  Future<void> Function({
    required String assignmentId,
    required String rejectionReason,
  })? onRejectAssignment;

  int lastPage = 0;
  int lastSize = 0;
  String? lastSearch;
  String? lastCategoryId;
  String? lastStatus;
  String? lastApprovedAssignmentId;
  String? lastRejectedAssignmentId;
  String? lastRejectionReason;

  _MockAssetRepository({
    this.onGetAssets,
    this.onGetAssetCategories,
    this.onApproveAssignment,
    this.onRejectAssignment,
  });

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) async {
    lastPage = page;
    lastSize = size;
    lastSearch = search;
    lastCategoryId = categoryId;
    lastStatus = status;

    if (onGetAssets != null) {
      return onGetAssets!(
        page: page,
        size: size,
        search: search,
        categoryId: categoryId,
        status: status,
      );
    }

    return const AssetListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: AssetPaginationMeta(page: 1, limit: 10, total: 0, totalPages: 1),
    );
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async {
    if (onGetAssetCategories != null) {
      return onGetAssetCategories!(search: search);
    }
    return [
      const AssetCategoryModel(id: 'cat-1', name: 'Laptop', code: 'LPT'),
      const AssetCategoryModel(id: 'cat-2', name: 'Smartphone', code: 'PHN'),
    ];
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) async {
    lastApprovedAssignmentId = assignmentId;
    if (onApproveAssignment != null) {
      await onApproveAssignment!(
        assignmentId: assignmentId,
        conditionOnCheckin: conditionOnCheckin,
        recipientNotes: recipientNotes,
        signatureUrl: signatureUrl,
        handoverPhotoUrl: handoverPhotoUrl,
      );
    }
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) async {
    lastRejectedAssignmentId = assignmentId;
    lastRejectionReason = rejectionReason;
    if (onRejectAssignment != null) {
      await onRejectAssignment!(
        assignmentId: assignmentId,
        rejectionReason: rejectionReason,
      );
    }
  }
}

void main() {
  group('AssetListBloc Unit Tests', () {
    test('initial state memiliki nilai default yang tepat', () {
      final bloc = AssetListBloc(repository: _MockAssetRepository());
      expect(bloc.state.status, AssetListStatus.initial);
      expect(bloc.state.actionStatus, AssetActionStatus.idle);
      expect(bloc.state.assets, isEmpty);
      expect(bloc.state.categories, isEmpty);
      expect(bloc.state.page, 1);
      expect(bloc.state.hasReachedMax, isFalse);
    });

    test('AssetListStarted sukses memuat kategori dan aset', () async {
      final sampleAssets = [
        const AssetListItem(
          id: 'asset-1',
          assignmentId: 'assign-1',
          assetCode: 'AST-LPT-001',
          name: 'Dell XPS 15',
          status: 'PENDING_ACCEPTANCE',
        ),
      ];

      final repo = _MockAssetRepository(
        onGetAssetCategories: ({search}) async => [
          const AssetCategoryModel(id: 'cat-1', name: 'Laptop', code: 'LPT'),
          const AssetCategoryModel(id: 'cat-2', name: 'Smartphone', code: 'PHN'),
        ],
        onGetAssets: (
            {required page,
            required size,
            search,
            categoryId,
            status}) async {
          return AssetListResponse(
            success: true,
            data: sampleAssets,
            meta: const AssetPaginationMeta(
              page: 1,
              limit: 10,
              total: 1,
              totalPages: 1,
            ),
          );
        },
      );

      final bloc = AssetListBloc(repository: repo);

      final expectedStates = [
        predicate<AssetListState>((s) =>
            s.status == AssetListStatus.loading && s.categoriesLoading == true),
        predicate<AssetListState>((s) =>
            s.status == AssetListStatus.success &&
            s.assets.length == 1 &&
            s.categories.length == 2 &&
            s.hasReachedMax == true),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const AssetListStarted());
    });

    test('AssetListStarted gagal menangani ApiException dengan rapi', () async {
      final repo = _MockAssetRepository(
        onGetAssets: (
            {required page,
            required size,
            search,
            categoryId,
            status}) async {
          throw const ApiException(
            message: 'Akses ditolak',
            statusCode: 403,
          );
        },
      );

      final bloc = AssetListBloc(repository: repo);

      final expectedStates = [
        predicate<AssetListState>((s) => s.status == AssetListStatus.loading),
        predicate<AssetListState>((s) =>
            s.status == AssetListStatus.failure &&
            s.errorMessage == 'Akses ditolak'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const AssetListStarted());
    });

    test('AssetListLoadMore mengambil halaman berikutnya dan menggabungkan data', () async {
      final page1Assets = [
        const AssetListItem(
          id: '1',
          assetCode: 'A1',
          name: 'Item 1',
          status: 'ACTIVE',
        ),
      ];

      final page2Assets = [
        const AssetListItem(
          id: '2',
          assetCode: 'A2',
          name: 'Item 2',
          status: 'ACTIVE',
        ),
      ];

      final repo = _MockAssetRepository(
        onGetAssets: (
            {required page,
            required size,
            search,
            categoryId,
            status}) async {
          if (page == 1) {
            return AssetListResponse(
              data: page1Assets,
              meta: const AssetPaginationMeta(page: 1, limit: 1, total: 2),
            );
          }
          return AssetListResponse(
            data: page2Assets,
            meta: const AssetPaginationMeta(page: 2, limit: 1, total: 2),
          );
        },
      );

      final bloc = AssetListBloc(repository: repo);
      bloc.add(const AssetListStarted());
      await bloc.stream.firstWhere((s) => s.status == AssetListStatus.success);

      expect(bloc.state.assets.length, 1);
      expect(bloc.state.hasReachedMax, isFalse);

      bloc.add(const AssetListLoadMore());
      await bloc.stream.firstWhere((s) => s.page == 2);

      expect(bloc.state.assets.length, 2);
      expect(bloc.state.hasReachedMax, isTrue);
    });

    test('AssetListSearchChanged memfilter kata kunci dan mereset halaman', () async {
      final repo = _MockAssetRepository(
        onGetAssets: (
            {required page,
            required size,
            search,
            categoryId,
            status}) async {
          return const AssetListResponse(data: []);
        },
      );

      final bloc = AssetListBloc(repository: repo);
      bloc.add(const AssetListSearchChanged('Innova'));

      await bloc.stream.firstWhere((s) => s.status == AssetListStatus.success);

      expect(repo.lastSearch, 'Innova');
      expect(bloc.state.searchQuery, 'Innova');
      expect(bloc.state.page, 1);
    });

    test('AssetListFilterApplied memperbarui kriteria filter dan memanggil API', () async {
      final repo = _MockAssetRepository(
        onGetAssets: (
            {required page,
            required size,
            search,
            categoryId,
            status}) async {
          return const AssetListResponse(data: []);
        },
      );

      final bloc = AssetListBloc(repository: repo);
      const criteria = AssetFilterCriteria(
        status: 'PENDING_ACCEPTANCE',
        categoryId: 'cat-1',
      );

      bloc.add(const AssetListFilterApplied(criteria));
      await bloc.stream.firstWhere((s) => s.status == AssetListStatus.success);

      expect(repo.lastStatus, 'PENDING_ACCEPTANCE');
      expect(repo.lastCategoryId, 'cat-1');
      expect(bloc.state.filter.status, 'PENDING_ACCEPTANCE');
    });

    test('AssetListFilterReset mengembalikan kriteria awal', () async {
      final repo = _MockAssetRepository(
        onGetAssets: (
            {required page,
            required size,
            search,
            categoryId,
            status}) async {
          return const AssetListResponse(data: []);
        },
      );

      final bloc = AssetListBloc(repository: repo);
      bloc.add(const AssetListFilterReset());
      await bloc.stream.firstWhere((s) => s.status == AssetListStatus.success);

      expect(bloc.state.filter.status, 'all');
      expect(bloc.state.filter.categoryId, isNull);
    });

    test('AssetAssignmentApproved memanggil approveAssignment dan memicu refresh', () async {
      final repo = _MockAssetRepository(
        onApproveAssignment: ({
          required assignmentId,
          conditionOnCheckin,
          handoverPhotoUrl,
          recipientNotes,
          signatureUrl,
        }) async {},
      );

      final bloc = AssetListBloc(repository: repo);
      bloc.add(const AssetAssignmentApproved('assign-999'));

      await bloc.stream.firstWhere((s) => s.actionStatus == AssetActionStatus.success);

      expect(repo.lastApprovedAssignmentId, 'assign-999');
      expect(bloc.state.actionMessage, contains('berhasil diterima'));
    });

    test('AssetAssignmentRejected memanggil rejectAssignment dan memicu refresh', () async {
      final repo = _MockAssetRepository(
        onRejectAssignment: ({
          required assignmentId,
          required rejectionReason,
        }) async {},
      );

      final bloc = AssetListBloc(repository: repo);
      bloc.add(const AssetAssignmentRejected(
        assignmentId: 'assign-888',
        reason: 'Barang rusak pada bagian layar',
      ));

      await bloc.stream.firstWhere((s) => s.actionStatus == AssetActionStatus.success);

      expect(repo.lastRejectedAssignmentId, 'assign-888');
      expect(repo.lastRejectionReason, 'Barang rusak pada bagian layar');
      expect(bloc.state.actionMessage, contains('telah ditolak'));
    });

    test('sortedAssets mengurutkan berdasarkan nama A-Z dan nama Z-A', () {
      const itemA = AssetListItem(
        id: '1',
        assetCode: '1',
        name: 'Apple MacBook',
        status: 'ACTIVE',
      );
      const itemB = AssetListItem(
        id: '2',
        assetCode: '2',
        name: 'Dell XPS',
        status: 'ACTIVE',
      );

      const stateAsc = AssetListState(
        assets: [itemB, itemA],
        filter: AssetFilterCriteria(sortBy: 'name_asc'),
      );
      expect(stateAsc.sortedAssets.first.name, 'Apple MacBook');

      const stateDesc = AssetListState(
        assets: [itemA, itemB],
        filter: AssetFilterCriteria(sortBy: 'name_desc'),
      );
      expect(stateDesc.sortedAssets.first.name, 'Dell XPS');
    });
  });
}
