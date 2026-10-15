import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/pages/asset_list_screen.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeAssetRepository implements AssetRepository {
  final bool shouldFail;
  final List<AssetListItem> items;

  _FakeAssetRepository({
    this.shouldFail = false,
    this.items = const [],
  });

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        message: 'Gagal memuat daftar fasilitas',
        statusCode: 500,
      );
    }

    var result = items;
    if (search != null && search.isNotEmpty) {
      result = result
          .where((item) =>
              item.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    return AssetListResponse(
      success: true,
      message: 'OK',
      data: result,
      meta: AssetPaginationMeta(
        page: page,
        limit: size,
        total: result.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async {
    return const [
      AssetCategoryModel(id: 'cat-1', name: 'Laptop & Komputer', code: 'LAP'),
      AssetCategoryModel(id: 'cat-2', name: 'Kendaraan Dinas', code: 'CAR'),
    ];
  }

  @override
  Future<AssetDetailData> getAssetDetail(String assetId) => throw UnimplementedError();

  @override
  Future<void> createAsset(CreateAssetPayload payload) => throw UnimplementedError();

  @override
  Future<void> handoverAsset(String assetId, HandoverAssetPayload payload) =>
      throw UnimplementedError();

  @override
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  ) =>
      throw UnimplementedError();

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
}

void main() {
  Widget buildTestableWidget({
    required AssetRepository repository,
  }) {
    return MaterialApp(
      home: AssetListScreen(repository: repository),
    );
  }

  final sampleAssets = [
    const AssetListItem(
      id: 'asset-1',
      assetCode: 'AST-LAP-001',
      name: 'MacBook Pro 14 M3',
      serialNumber: 'SN-MBP-9921',
      status: 'ACTIVE',
      condition: 'GOOD',
    ),
    const AssetListItem(
      id: 'asset-2',
      assetCode: 'AST-CAR-002',
      name: 'Toyota Innova Zenix',
      serialNumber: 'B 1234 XYZ',
      status: 'AVAILABLE',
      condition: 'GOOD',
    ),
  ];

  group('AssetListScreen Widget Tests', () {
    testWidgets('renders assets list, title, and search bar on success', (tester) async {
      final repo = _FakeAssetRepository(items: sampleAssets);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Asset Saya'), findsOneWidget);
      expect(find.byType(AppSearchBar), findsOneWidget);
      expect(find.text('MacBook Pro 14 M3'), findsOneWidget);
      expect(find.text('Toyota Innova Zenix'), findsOneWidget);
      expect(find.byType(AssetCard), findsNWidgets(2));
    });

    testWidgets('renders empty state when there are no assets', (tester) async {
      final repo = _FakeAssetRepository(items: const []);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets('renders error state and retry button on failure', (tester) async {
      final repo = _FakeAssetRepository(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat daftar fasilitas'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('typing query in search bar filters assets list', (tester) async {
      final repo = _FakeAssetRepository(items: sampleAssets);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'MacBook');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('MacBook Pro 14 M3'), findsOneWidget);
      expect(find.text('Toyota Innova Zenix'), findsNothing);
    });

    testWidgets('tapping filter button opens asset filter bottom sheet', (tester) async {
      final repo = _FakeAssetRepository(items: sampleAssets);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final filterBtn = find.byIcon(LucideIcons.slidersHorizontal);
      expect(filterBtn, findsOneWidget);

      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      expect(find.text('Filter Fasilitas'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);
    });
  });
}
