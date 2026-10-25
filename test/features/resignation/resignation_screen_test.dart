import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/pages/resignation_screen.dart';

import 'mock_resignation_repository.dart';

void main() {
  const sampleActiveStatus = MyResignationStatusModel(
    hasActiveResignation: true,
    daysRemaining: 20,
    canCancel: true,
    canSubmitExitInterview: false,
    resignation: ResignationDetailModel(
      id: 'res-101',
      companyId: 'comp-1',
      employeeId: 'emp-1',
      status: 'manager_approved',
      reason: 'Melanjutkan studi',
    ),
  );

  Widget buildTestableWidget({required ResignationRepository repository}) {
    return MaterialApp(
      home: ResignationScreen(resignationRepository: repository),
    );
  }

  group('ResignationScreen Widget Tests', () {
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

    testWidgets('renders empty state card when user has no active resignation', (tester) async {
      final repo = MockResignationRepository();
      repo.mockMyStatus = const MyResignationStatusModel(
        hasActiveResignation: false,
        daysRemaining: 0,
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Resign'), findsOneWidget);
      expect(find.text('Tidak Ada Pengajuan Aktif'), findsOneWidget);
      expect(find.text('Ajukan Pengunduran Diri'), findsOneWidget);
    });

    testWidgets('renders active resignation countdown, stepper, and action buttons', (tester) async {
      final repo = MockResignationRepository();
      repo.mockMyStatus = sampleActiveStatus;

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Resign'), findsOneWidget);
      expect(find.text('Tahapan Proses Resign'), findsOneWidget);
      // Placeholder "segera hadir" sudah dihapus; timeline tampil langsung di halaman.
      expect(find.text('Lihat Detail Berkas & Timeline'), findsNothing);
      expect(find.textContaining('segera hadir'), findsNothing);
      expect(find.text('Batalkan Pengajuan'), findsOneWidget);
    });

    testWidgets('renders pill TabBar and allows switching to Team Approvals tab when authorized', (tester) async {
      // Grant permission for viewing subordinate resignations
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.approvalResignationManager,
      ]);

      final repo = MockResignationRepository();
      repo.mockMyStatus = const MyResignationStatusModel(hasActiveResignation: false);
      repo.mockSubordinates = const SubordinateResignationResponseModel(
        success: true,
        message: 'OK',
        data: [],
        meta: ResignationPaginationMeta(
          page: 1,
          size: 10,
          total: 0,
          totalPages: 1,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Persetujuan Tim'), findsOneWidget);

      // Tap on Team tab
      await tester.tap(find.text('Persetujuan Tim'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Pengajuan Tim'), findsOneWidget);

      // Clean up in-memory permissions
      SecureStorageService.instance.setPermissionsInMemory([]);
    });

    testWidgets('shows error feedback when fetching status fails', (tester) async {
      final repo = MockResignationRepository();
      repo.shouldThrowError = true;
      repo.errorMessage = 'Gagal memuat status resign';

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gagal memuat status resign'), findsOneWidget);
    });
  });

  group('ResignationScreen - exit interview & review atasan', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2600);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
      SecureStorageService.instance.setPermissionsInMemory([]);
    });

    testWidgets('mengisi kuesioner exit interview mengirim payload ke API', (tester) async {
      final repo = MockResignationRepository();
      repo.mockMyStatus = const MyResignationStatusModel(
        hasActiveResignation: true,
        daysRemaining: 5,
        canSubmitExitInterview: true,
        resignation: ResignationDetailModel(
          id: 'res-101',
          companyId: 'comp-1',
          employeeId: 'emp-1',
          status: 'manager_approved',
          reason: 'Melanjutkan studi',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Isi Kuesioner Exit Interview'));
      await tester.tap(find.text('Isi Kuesioner Exit Interview'));
      await tester.pumpAndSettle();

      expect(find.text('Kuesioner Exit Interview'), findsWidgets);

      // Kirim tanpa umpan balik -> validasi, API tidak dipanggil
      await tester.ensureVisible(find.byKey(const ValueKey('exit_interview_submit')));
      await tester.tap(find.byKey(const ValueKey('exit_interview_submit')));
      await tester.pump();
      expect(find.byKey(const ValueKey('exit_interview_error')), findsOneWidget);
      expect(repo.lastExitInterview, isNull);

      // Isi rating budaya = 4 dan umpan balik, lalu kirim
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('exit_interview_culture')),
          matching: find.byKey(const ValueKey('rating-4')),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('exit_interview_feedback')),
          matching: find.byType(TextField),
        ),
        '  Ingin melanjutkan studi  ',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('exit_interview_submit')));
      await tester.tap(find.byKey(const ValueKey('exit_interview_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(repo.lastExitInterview, isNotNull);
      expect(repo.lastExitInterview!.satisfactionCulture, 4);
      expect(repo.lastExitInterview!.reasonFeedback, 'Ingin melanjutkan studi');
      expect(repo.lastExitInterview!.isSkipped, isFalse);
    });

    Future<MockResignationRepository> pumpTeamTab(WidgetTester tester) async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.approvalResignationManager,
      ]);
      final repo = MockResignationRepository();
      repo.mockMyStatus = const MyResignationStatusModel(hasActiveResignation: false);
      repo.mockSubordinates = SubordinateResignationResponseModel(
        success: true,
        message: 'OK',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-1',
            companyId: 'c',
            employeeId: 'e',
            employeeName: 'Dimas Prasetyo',
            status: 'submitted',
            reason: 'Pindah kota',
            isEarlyNotice: true,
            earlyNoticeReason: 'Tawaran kerja mendesak',
            effectiveDate: DateTime(2026, 11, 30),
          ),
        ],
        meta: const ResignationPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persetujuan Tim'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('Review 1-on-1 membuka sheet; catatan <5 karakter ditolak validasi', (tester) async {
      final repo = await pumpTeamTab(tester);

      await tester.ensureVisible(find.text('Review 1-on-1'));
      await tester.tap(find.text('Review 1-on-1'));
      await tester.pumpAndSettle();

      expect(find.text('Review Pengajuan Resign'), findsOneWidget);
      expect(find.byKey(const ValueKey('resignation_review_early_notice')), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('resignation_review_notes')),
          matching: find.byType(TextField),
        ),
        'ok',
      );
      await tester.tap(find.byKey(const ValueKey('resignation_review_submit')));
      await tester.pump();

      expect(find.byKey(const ValueKey('resignation_review_notes_error')), findsOneWidget);
      expect(repo.reviewCalls, isEmpty);
    });

    testWidgets('menyetujui dengan catatan valid memanggil API approve', (tester) async {
      final repo = await pumpTeamTab(tester);

      await tester.ensureVisible(find.text('Review 1-on-1'));
      await tester.tap(find.text('Review 1-on-1'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('resignation_review_notes')),
          matching: find.byType(TextField),
        ),
        'Sudah dibahas bersama',
      );
      await tester.tap(find.byKey(const ValueKey('resignation_review_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(repo.reviewCalls, [
        {
          'action': 'approve',
          'id': 'sub-1',
          'notes': 'Sudah dibahas bersama',
          'approveEarlyNotice': true,
        },
      ]);
    });

    testWidgets('memilih Tolak lalu mengirim memanggil API reject', (tester) async {
      final repo = await pumpTeamTab(tester);

      await tester.ensureVisible(find.text('Review 1-on-1'));
      await tester.tap(find.text('Review 1-on-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('resignation_review_reject_choice')));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('resignation_review_notes')),
          matching: find.byType(TextField),
        ),
        'Proyek belum selesai',
      );
      await tester.tap(find.byKey(const ValueKey('resignation_review_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(repo.reviewCalls.single['action'], 'reject');
      expect(repo.reviewCalls.single['notes'], 'Proyek belum selesai');
    });

    testWidgets('error API ditampilkan dari backend dan sheet tetap terbuka', (tester) async {
      final repo = await pumpTeamTab(tester);
      repo.shouldThrowError = true;
      repo.errorMessage = 'Pengajuan sudah diproses atasan lain';

      await tester.ensureVisible(find.text('Review 1-on-1'));
      await tester.tap(find.text('Review 1-on-1'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('resignation_review_notes')),
          matching: find.byType(TextField),
        ),
        'Disetujui',
      );
      await tester.tap(find.byKey(const ValueKey('resignation_review_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Pengajuan sudah diproses atasan lain'), findsOneWidget);
      expect(find.text('Review Pengajuan Resign'), findsOneWidget);
    });

    testWidgets('pengajuan yang sudah diproses tampil read-only tanpa tombol aksi', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.approvalResignationManager,
      ]);
      final repo = MockResignationRepository();
      repo.mockMyStatus = const MyResignationStatusModel(hasActiveResignation: false);
      repo.mockSubordinates = const SubordinateResignationResponseModel(
        success: true,
        message: 'OK',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-9',
            companyId: 'c',
            employeeId: 'e',
            employeeName: 'Rina',
            status: 'manager_approved',
            managerNotes: 'Sudah 1-on-1 dan disetujui',
          ),
        ],
        meta: ResignationPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persetujuan Tim'));
      await tester.pumpAndSettle();

      expect(find.text('Review 1-on-1'), findsNothing);
      // Seluruh kartu dapat diketuk untuk membuka detail (tanpa tombol "Lihat Detail").
      expect(find.text('Lihat Detail'), findsNothing);
      await tester.tap(find.text('Rina'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Pengajuan Resign'), findsOneWidget);
      expect(find.byKey(const ValueKey('resignation_review_manager_notes')), findsOneWidget);
      expect(find.byKey(const ValueKey('resignation_review_submit')), findsNothing);
    });
  });
}
