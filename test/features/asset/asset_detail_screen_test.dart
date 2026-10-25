import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/pages/asset_detail_screen.dart';

class _FakeAssetDetailRepo implements AssetRepository {
  final bool shouldFail;
  final int failStatus;
  bool assignmentApproved = false;

  _FakeAssetDetailRepo({this.shouldFail = false, this.failStatus = 404});

  @override
  Future<AssetDetailData> getAssetDetail(String assetId) async {
    if (shouldFail) {
      throw ApiException(
        message: 'Aset tidak ditemukan di server',
        statusCode: failStatus,
      );
    }

    return AssetDetailData(
      id: assetId,
      assetCode: 'AST-NB-001',
      name: 'MacBook Pro M3 Max',
      brand: 'Apple',
      model: 'MacBook Pro 16 Inch',
      serialNumber: 'SN-APL-998877',
      condition: 'EXCELLENT',
      status: 'ASSIGNED',
      location: 'Jakarta HQ',
      category: const AssetDetailCategory(
        id: 'cat-1',
        name: 'Laptop & Komputer',
        code: 'LAP',
      ),
      assignments: [
        AssetAssignmentItemModel(
          id: 'asg-1',
          assetId: assetId,
          employeeId: 'emp-1',
          assignedDate: DateTime(2026, 1, 15),
          conditionOnCheckout: 'GOOD',
          status: 'ACTIVE',
          employee: const AssetAssigneeEmployeeModel(
            id: 'emp-1',
            firstName: 'Ahmad',
            lastName: 'Dahlan',
            employeeNumber: 'EMP-001',
          ),
        ),
      ],
    );
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) async {
    assignmentApproved = true;
  }

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) => throw UnimplementedError();

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) =>
      throw UnimplementedError();

  @override
  Future<void> createAsset(CreateAssetPayload payload) =>
      throw UnimplementedError();

  @override
  Future<void> handoverAsset(String assetId, HandoverAssetPayload payload) =>
      throw UnimplementedError();

  @override
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  ) => throw UnimplementedError();

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) => throw UnimplementedError();
}

void main() {
  Widget buildTestableWidget({required AssetRepository repository}) {
    return MaterialApp(
      home: AssetDetailScreen(
        assetId: 'ast-101',
        repository: repository,
      ),
    );
  }

  group('AssetDetailScreen Widget Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('renders asset details, hero card, spec card, and timeline', (tester) async {
      final repo = _FakeAssetDetailRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Detail Fasilitas'), findsOneWidget);
      expect(find.text('Spesifikasi & Riwayat Handover'), findsNothing);
      expect(find.text('MacBook Pro M3 Max'), findsWidgets);
      expect(find.text('AST-NB-001'), findsWidgets);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('SN-APL-998877'), findsOneWidget);
    });

    testWidgets('404 menampilkan pesan API dan hanya tombol Kembali', (tester) async {
      final repo = _FakeAssetDetailRepo(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Detail Fasilitas'), findsOneWidget);
      expect(find.text('Aset tidak ditemukan di server'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('error 500 menampilkan tombol Coba Lagi', (tester) async {
      final repo = _FakeAssetDetailRepo(shouldFail: true, failStatus: 500);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Aset tidak ditemukan di server'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Coba Lagi'), findsOneWidget);
      expect(find.text('Kembali'), findsNothing);
    });
  });
}
