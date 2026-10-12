import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_state.dart';

class _FakeCreateAssetRepository implements AssetRepository {
  List<AssetCategoryModel> categories = [
    const AssetCategoryModel(id: 'cat-1', name: 'Laptop', code: 'LPT'),
    const AssetCategoryModel(id: 'cat-2', name: 'Smartphone', code: 'PHN'),
  ];
  bool throwOnCategories = false;
  bool throwOnCreate = false;
  CreateAssetPayload? lastCreatedPayload;

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async {
    if (throwOnCategories) {
      throw const ApiException(
        message: 'Gagal memuat master kategori',
        statusCode: 500,
      );
    }
    return categories;
  }

  @override
  Future<void> createAsset(CreateAssetPayload payload) async {
    if (throwOnCreate) {
      throw const ApiException(
        message: 'Kode aset sudah digunakan',
        statusCode: 400,
      );
    }
    lastCreatedPayload = payload;
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) async {}

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) async {}

  @override
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  ) async {}

  @override
  Future<AssetDetailData> getAssetDetail(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) async {
    return const AssetListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: AssetPaginationMeta(page: 1, limit: 10, total: 0, totalPages: 1),
    );
  }

  @override
  Future<void> handoverAsset(
    String assetId,
    HandoverAssetPayload payload,
  ) async {}
}

void main() {
  group('CreateAssetBloc Unit Tests', () {
    late _FakeCreateAssetRepository repository;

    setUp(() {
      repository = _FakeCreateAssetRepository();
    });

    test('Initial state memiliki default values', () {
      final bloc = CreateAssetBloc(repository: repository);
      expect(bloc.state.status, CreateAssetStatus.initial);
      expect(bloc.state.categories, isEmpty);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.isSuccess, isFalse);
    });

    test('CreateAssetStarted sukses memuat daftar kategori aset', () async {
      final bloc = CreateAssetBloc(repository: repository);

      final expectedStates = [
        predicate<CreateAssetState>((s) => s.status == CreateAssetStatus.loading),
        predicate<CreateAssetState>((s) =>
            s.status == CreateAssetStatus.success &&
            s.categories.length == 2 &&
            s.categories.first.name == 'Laptop'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const CreateAssetStarted());
    });

    test('CreateAssetStarted gagal memuat kategori dan menyimpan pesan error', () async {
      repository.throwOnCategories = true;
      final bloc = CreateAssetBloc(repository: repository);

      final expectedStates = [
        predicate<CreateAssetState>((s) => s.status == CreateAssetStatus.loading),
        predicate<CreateAssetState>((s) =>
            s.status == CreateAssetStatus.failure &&
            s.errorMessage == 'Gagal memuat master kategori'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const CreateAssetStarted());
    });

    test('CreateAssetSubmitted berhasil mendaftarkan aset baru', () async {
      final bloc = CreateAssetBloc(repository: repository);

      final expectedStates = [
        predicate<CreateAssetState>((s) => s.isSubmitting == true),
        predicate<CreateAssetState>((s) =>
            s.isSubmitting == false &&
            s.isSuccess == true &&
            s.successMessage == 'Unit aset baru berhasil didaftarkan.'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const CreateAssetSubmitted(
        CreateAssetPayload(
          categoryId: 'cat-1',
          assetCode: 'AST-009',
          name: 'MacBook Air M2',
          condition: 'NEW',
        ),
      ));

      await pumpEventQueue();
      expect(repository.lastCreatedPayload?.assetCode, 'AST-009');
      expect(repository.lastCreatedPayload?.name, 'MacBook Air M2');
    });

    test('CreateAssetSubmitted gagal menangani error kode duplikat dari server', () async {
      repository.throwOnCreate = true;
      final bloc = CreateAssetBloc(repository: repository);

      final expectedStates = [
        predicate<CreateAssetState>((s) => s.isSubmitting == true),
        predicate<CreateAssetState>((s) =>
            s.isSubmitting == false &&
            s.isSuccess == false &&
            s.errorMessage == 'Kode aset sudah digunakan'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const CreateAssetSubmitted(
        CreateAssetPayload(
          categoryId: 'cat-1',
          assetCode: 'AST-009',
          name: 'MacBook Air M2',
          condition: 'NEW',
        ),
      ));
    });
  });
}
