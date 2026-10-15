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
      expect(find.text('Lihat Detail Berkas & Timeline'), findsOneWidget);
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
}
