import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/pages/create_asset_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeCreateAssetRepo implements AssetRepository {
  final bool shouldFail;
  CreateAssetPayload? submittedPayload;

  _FakeCreateAssetRepo({this.shouldFail = false});

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async {
    return const [
      AssetCategoryModel(id: 'cat-1', name: 'Laptop & Komputer', code: 'LAP'),
      AssetCategoryModel(id: 'cat-2', name: 'Kendaraan Dinas', code: 'CAR'),
    ];
  }

  @override
  Future<void> createAsset(CreateAssetPayload payload) async {
    if (shouldFail) {
      throw const ApiException(
        message: 'Gagal membuat aset baru',
        statusCode: 400,
      );
    }
    submittedPayload = payload;
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
  Future<AssetDetailData> getAssetDetail(String assetId) => throw UnimplementedError();

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
  }) => throw UnimplementedError();

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) => throw UnimplementedError();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget buildTestableWidget({
    required AssetRepository repository,
  }) {
    return MaterialApp(
      home: CreateAssetScreen(repository: repository),
    );
  }

  group('CreateAssetScreen Widget Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('renders all form fields, title, and submit button', (tester) async {
      final repo = _FakeCreateAssetRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Daftarkan Aset Baru'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Kategori Aset'),
        ),
        findsOneWidget,
      );
      expect(find.byType(AppTextField), findsWidgets);
      expect(find.widgetWithText(AppButton, 'Daftarkan Aset'), findsOneWidget);
    });

    testWidgets('shows snackbar when category is not selected on submit', (tester) async {
      final repo = _FakeCreateAssetRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(AppButton, 'Daftarkan Aset');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Silakan pilih kategori aset'), findsOneWidget);
      expect(repo.submittedPayload, isNull);
    });

    testWidgets('submits form successfully when required fields are filled', (tester) async {
      final repo = _FakeCreateAssetRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      // 1. Select category from DropdownButtonFormField
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Laptop & Komputer').last);
      await tester.pumpAndSettle();

      // 2. Fill Kode Aset & Nama Aset
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'AST-LAP-999');
      await tester.enterText(textFields.at(1), 'Dell XPS 15');
      await tester.pump();

      // 3. Submit
      final submitBtn = find.widgetWithText(AppButton, 'Daftarkan Aset');
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.submittedPayload, isNotNull);
      expect(repo.submittedPayload!.assetCode, 'AST-LAP-999');
      expect(repo.submittedPayload!.name, 'Dell XPS 15');
    });

    testWidgets('shows error dialog when API call fails', (tester) async {
      final repo = _FakeCreateAssetRepo(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      // 1. Select category
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laptop & Komputer').last);
      await tester.pumpAndSettle();

      // 2. Fill Kode Aset & Nama Aset
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'AST-ERR-001');
      await tester.enterText(textFields.at(1), 'Broken Monitor');
      await tester.pump();

      // 3. Submit
      final submitBtn = find.widgetWithText(AppButton, 'Daftarkan Aset');
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gagal membuat aset baru'), findsOneWidget);
    });
  });
}
