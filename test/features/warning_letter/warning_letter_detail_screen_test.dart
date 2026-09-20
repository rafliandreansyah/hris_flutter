import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_bloc.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/warning_letter_detail_screen.dart';

class _FakeWarningLetterRepository implements WarningLetterRepository {
  WarningLetterDetail? detailToReturn;
  Exception? exceptionToThrow;

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return detailToReturn ??
        const WarningLetterDetail(
          id: 'wl-fallback',
          warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
          timezone: 'WIB',
          isActive: true,
          createdAt: null,
          issuedDate: null,
          expiredDate: null,
        );
  }

  @override
  Future<WarningLetterListResponse> getWarningLetters({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  }) async {
    return const WarningLetterListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: WarningLetterPaginationMeta(
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async => [];

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async =>
      null;

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    return const CreateWarningLetterResponse(success: true, message: 'OK');
  }
}

void main() {
  final sampleDetail = WarningLetterDetail(
    id: 'wl-101',
    warningLetterType:
        const WarningLetterTypeSummary(level: 1, name: 'Surat Peringatan 1'),
    referenceNumber: 'SP/2026/08/0019',
    attachmentUrl: 'https://example.com/Surat_Peringatan_Resmi_123E.pdf',
    infractionReason: 'Indisipliner Keterlambatan & Kehadiran (SP 1)',
    sanction: 'Pemotongan tunjangan kehadiran 10%',
    employee: const WarningLetterEmployee(
      id: 'emp-101',
      firstName: 'Sarah',
      lastName: 'Jenkins',
      company: WarningLetterOrgUnit(id: 'c1', name: 'PT Oasish Tech Nusantara'),
      department: WarningLetterOrgUnit(id: 'd1', name: 'Engineering'),
      position: WarningLetterOrgUnit(id: 'p1', name: 'Frontend Engineer'),
      employeeNumber: 'EMP-2024-019',
    ),
    issuedDate: DateTime(2026, 8, 29),
    expiredDate: DateTime(2027, 2, 28),
    timezone: 'WIB',
    isActive: true,
    issuedByEmployee: const WarningLetterEmployee(
      id: 'emp-202',
      firstName: 'Alex',
      lastName: 'Rivera',
      company: WarningLetterOrgUnit(id: 'c1', name: 'PT Oasish Tech Nusantara'),
      position: WarningLetterOrgUnit(id: 'p2', name: 'Engineering Manager'),
      email: 'alex.r@oasish.com',
    ),
    createdAt: DateTime(2026, 8, 29, 12, 47),
  );

  Widget createWidgetUnderTest(_FakeWarningLetterRepository repository) {
    return MaterialApp(
      home: BlocProvider<WarningLetterDetailBloc>(
        create: (context) => WarningLetterDetailBloc(repository: repository),
        child: const WarningLetterDetailScreen(id: 'wl-101'),
      ),
    );
  }

  group('WarningLetterDetailScreen Widget Tests', () {
    testWidgets('renders all sections and information correctly on success',
        (tester) async {
      final repository = _FakeWarningLetterRepository();
      repository.detailToReturn = sampleDetail;

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pumpAndSettle();

      // Top bar & title
      expect(find.text('Detail Surat Peringatan'), findsOneWidget);
      expect(find.textContaining('SP/2026/08/0019'), findsWidgets);

      // Main banner card contents
      expect(find.text('Surat Peringatan 1 (SP 1)'), findsOneWidget);
      expect(find.text('Masih Berlaku'), findsOneWidget);
      expect(
        find.text('Indisipliner Keterlambatan & Kehadiran (SP 1)'),
        findsOneWidget,
      );
      expect(find.text('MASA BERLAKU SANKSI'), findsOneWidget);

      // Recipient section
      expect(find.text('PENERIMA SURAT PERINGATAN'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);

      // Issuer section
      expect(find.text('PEJABAT PENERBIT (ISSUED BY)'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Engineering Manager'), findsOneWidget);

      // Attachment section
      expect(find.text('LAMPIRAN DOKUMEN RESMI'), findsOneWidget);
      expect(find.text('Surat_Peringatan_Resmi_123E.pdf'), findsOneWidget);

      // Bottom action button
      expect(
        find.text('Unduh Salinan Surat Peringatan (PDF)'),
        findsOneWidget,
      );
    });

    testWidgets('renders error state on 404 with Kembali button',
        (tester) async {
      final repository = _FakeWarningLetterRepository();
      repository.exceptionToThrow = const ApiException(
        message: 'Surat peringatan tidak ditemukan.',
        statusCode: 404,
      );

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pumpAndSettle();

      expect(find.text('Surat Peringatan Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Surat peringatan tidak ditemukan.'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('renders error state on 500 with Coba Lagi button',
        (tester) async {
      final repository = _FakeWarningLetterRepository();
      repository.exceptionToThrow = const ApiException(
        message: 'Internal server error.',
        statusCode: 500,
      );

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Detail'), findsOneWidget);
      expect(find.text('Internal server error.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('renders photo preview when attachment is an image',
        (tester) async {
      final repository = _FakeWarningLetterRepository();
      repository.detailToReturn = const WarningLetterDetail(
        id: 'wl-photo-1',
        warningLetterType: WarningLetterTypeSummary(
          level: 2,
          name: 'Surat Peringatan 2',
        ),
        referenceNumber: 'SP/2026/09/0099',
        attachmentUrl: 'https://example.com/bukti_foto.jpg',
        infractionReason: 'Kerusakan Fasilitas Kerja',
        employee: WarningLetterEmployee(
          id: 'emp-1',
          firstName: 'Dimas',
        ),
        timezone: 'WIB',
        isActive: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pumpAndSettle();

      expect(find.text('Foto Lampiran Resmi'), findsOneWidget);
      expect(find.text('bukti_foto.jpg'), findsOneWidget);
      expect(find.byType(AppImageThumbnailPreview), findsOneWidget);
      expect(find.text('Unduh Foto Surat Peringatan'), findsOneWidget);
    });

    testWidgets('tapping photo thumbnail opens AppImagePreviewDialog with long reference number safely',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = _FakeWarningLetterRepository();
      repository.detailToReturn = const WarningLetterDetail(
        id: 'wl-photo-overflow',
        warningLetterType: WarningLetterTypeSummary(
          level: 1,
          name: 'Surat Peringatan Lisan / Teguran',
        ),
        referenceNumber:
            'Surat Peringatan Lisan / Teguran/PT. Oasish Indonesia/09/2026/0001',
        attachmentUrl: 'https://example.com/sp_long_ref.jpg',
        infractionReason: 'Keterlambatan Berulang',
        timezone: 'WIB',
        isActive: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pumpAndSettle();

      // Scroll until thumbnail preview is visible and tap it
      expect(find.byType(AppImageThumbnailPreview), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(AppImageThumbnailPreview),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppImageThumbnailPreview));
      await tester.pumpAndSettle();

      // Verify dialog opened without RenderFlex overflow
      expect(find.byType(AppImagePreviewDialog), findsOneWidget);
      expect(find.text('Foto Surat Peringatan'), findsOneWidget);
      expect(
        find.text(
          'Ref: Surat Peringatan Lisan / Teguran/PT. Oasish Indonesia/09/2026/0001',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders empty placeholder when there is no attachment',
        (tester) async {
      final repository = _FakeWarningLetterRepository();
      repository.detailToReturn = const WarningLetterDetail(
        id: 'wl-no-attach',
        warningLetterType: WarningLetterTypeSummary(
          level: 1,
          name: 'Surat Peringatan 1',
        ),
        referenceNumber: 'SP/2026/09/0100',
        attachmentUrl: null,
        infractionReason: 'Teguran Lisan',
        timezone: 'WIB',
        isActive: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(repository));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Dokumen Lampiran'), findsOneWidget);
      expect(find.byType(AppImageThumbnailPreview), findsNothing);
    });
  });
}
