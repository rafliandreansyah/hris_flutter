import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_state.dart';

class _FakeAssetRepository implements AssetRepository {
  AssetDetailData? mockDetail;
  bool shouldThrow = false;
  String? lastHandoverAssetId;
  HandoverAssetPayload? lastHandoverPayload;
  String? lastTransferAssetId;
  DirectTransferAssetPayload? lastTransferPayload;
  String? lastApprovedAssignmentId;
  String? lastRejectedAssignmentId;

  @override
  Future<AssetDetailData> getAssetDetail(String assetId) async {
    if (shouldThrow) {
      throw const ApiException(
        message: 'Aset tidak ditemukan di sistem',
        statusCode: 404,
      );
    }
    return mockDetail ??
        AssetDetailData(
          id: assetId,
          assetCode: 'AST-001',
          name: 'ThinkPad T14 Gen 4',
          condition: 'GOOD',
          status: 'AVAILABLE',
        );
  }

  @override
  Future<void> handoverAsset(
    String assetId,
    HandoverAssetPayload payload,
  ) async {
    if (shouldThrow) {
      throw const ApiException(
        message: 'Gagal melakukan serah terima unit',
        statusCode: 400,
      );
    }
    lastHandoverAssetId = assetId;
    lastHandoverPayload = payload;
  }

  @override
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  ) async {
    if (shouldThrow) {
      throw const ApiException(
        message: 'Gagal mengalihkan unit ke rekan kerja',
        statusCode: 400,
      );
    }
    lastTransferAssetId = assetId;
    lastTransferPayload = payload;
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) async {
    if (shouldThrow) {
      throw const ApiException(
        message: 'Gagal menyetujui penerimaan aset',
        statusCode: 400,
      );
    }
    lastApprovedAssignmentId = assignmentId;
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) async {
    if (shouldThrow) {
      throw const ApiException(
        message: 'Gagal menolak penyerahan aset',
        statusCode: 400,
      );
    }
    lastRejectedAssignmentId = assignmentId;
  }

  @override
  Future<void> createAsset(CreateAssetPayload payload) async {}

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async => [];

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
}

class _FakeSecureStorageService extends Fake implements SecureStorageService {
  final Set<String> permissions;
  final String? employeeId;

  _FakeSecureStorageService({
    this.permissions = const {},
    this.employeeId = 'emp-001',
  });

  @override
  bool hasPermissionInMemory(String permission) {
    return permissions.contains(permission);
  }

  @override
  Future<String?> getEmployeeId() async => employeeId;
}

void main() {
  group('AssetDetailBloc Unit Tests', () {
    late _FakeAssetRepository repository;
    late _FakeSecureStorageService storageService;

    setUp(() {
      repository = _FakeAssetRepository();
      storageService = _FakeSecureStorageService(
        permissions: {'asset.handover', 'asset.create'},
        employeeId: 'emp-001',
      );
    });

    test('Initial state bernilai default', () {
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );
      expect(bloc.state.status, AssetDetailStatus.initial);
      expect(bloc.state.actionStatus, AssetDetailActionStatus.idle);
      expect(bloc.state.asset, isNull);
    });

    test('AssetDetailStarted sukses memuat detail aset dan permissions', () async {
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );

      final expectedStates = [
        predicate<AssetDetailState>((s) => s.status == AssetDetailStatus.loading),
        predicate<AssetDetailState>((s) =>
            s.status == AssetDetailStatus.success &&
            s.asset?.id == 'ast-101' &&
            s.canHandover == true &&
            s.canCreate == true &&
            s.currentEmployeeId == 'emp-001'),
      ];

      final expectation = expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const AssetDetailStarted('ast-101'));
      await expectation;
    });

    test('AssetDetailStarted gagal menangani ApiException dengan status failure', () async {
      repository.shouldThrow = true;
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );

      final expectedStates = [
        predicate<AssetDetailState>((s) => s.status == AssetDetailStatus.loading),
        predicate<AssetDetailState>((s) =>
            s.status == AssetDetailStatus.failure &&
            s.errorMessage == 'Aset tidak ditemukan di sistem'),
      ];

      final expectation = expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const AssetDetailStarted('ast-999'));
      await expectation;
    });

    test('AssetDetailPoolHandedOver sukses memanggil repository', () async {
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );

      bloc.add(const AssetDetailStarted('ast-101'));
      await pumpEventQueue();

      final payload = HandoverAssetPayload(
        employeeId: 'emp-202',
        assignedDate: DateTime(2024, 6, 1),
        conditionOnCheckout: 'GOOD',
        checkoutNotes: 'Serah terima awal',
      );

      bloc.add(AssetDetailPoolHandedOver(payload));
      await pumpEventQueue();

      expect(repository.lastHandoverAssetId, 'ast-101');
      expect(repository.lastHandoverPayload?.employeeId, 'emp-202');
    });

    test('AssetDetailDirectTransferred sukses memanggil direct transfer', () async {
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );

      bloc.add(const AssetDetailStarted('ast-101'));
      await pumpEventQueue();

      final payload = DirectTransferAssetPayload(
        targetEmployeeId: 'emp-303',
        assignedDate: DateTime(2024, 7, 1),
        conditionOnCheckout: 'GOOD',
      );

      bloc.add(AssetDetailDirectTransferred(payload));
      await pumpEventQueue();

      expect(repository.lastTransferAssetId, 'ast-101');
      expect(repository.lastTransferPayload?.targetEmployeeId, 'emp-303');
    });

    test('AssetDetailAssignmentApproved sukses memanggil approve', () async {
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );

      bloc.add(const AssetDetailStarted('ast-101'));
      await pumpEventQueue();

      bloc.add(const AssetDetailAssignmentApproved(
        assignmentId: 'asg-777',
        conditionOnCheckin: 'GOOD',
        notes: 'Diterima dalam kondisi baik',
      ));
      await pumpEventQueue();

      expect(repository.lastApprovedAssignmentId, 'asg-777');
    });

    test('AssetDetailAssignmentRejected sukses memanggil reject', () async {
      final bloc = AssetDetailBloc(
        repository: repository,
        storageService: storageService,
      );

      bloc.add(const AssetDetailStarted('ast-101'));
      await pumpEventQueue();

      bloc.add(const AssetDetailAssignmentRejected(
        assignmentId: 'asg-888',
        reason: 'Fasilitas tidak sesuai spesifikasi',
      ));
      await pumpEventQueue();

      expect(repository.lastRejectedAssignmentId, 'asg-888');
    });
  });
}
