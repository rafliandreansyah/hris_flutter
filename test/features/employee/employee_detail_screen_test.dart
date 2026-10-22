import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_lifecycle_repository.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeEmployeeDetailRepo implements EmployeeRepository {
  final bool shouldFail;
  final int failStatus;
  final Duration delay;

  _FakeEmployeeDetailRepo({
    this.shouldFail = false,
    this.failStatus = 404,
    this.delay = Duration.zero,
  });

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldFail) {
      throw ApiException(
        message: 'Data pegawai tidak ditemukan',
        statusCode: failStatus,
      );
    }

    return const EmployeeDetailData(
      id: 'emp-101',
      firstName: 'Budi',
      lastName: 'Santoso',
      email: 'budi.santoso@oasish.com',
      phone: '+6281234567890',
      employeeNumber: 'EMP-777',
      employmentType: 'Permanent / Tetap',
      joinDate: '2024-08-28',
      position: DetailPosition(
        id: 'pos-1',
        name: 'Backend Engineer',
      ),
      department: DetailDepartment(
        id: 'dept-1',
        name: 'Finance Ops',
      ),
      company: DetailCompany(
        id: 'comp-1',
        name: 'PT Contoh Abadi',
      ),
      level: DetailLevel(
        id: 'lvl-4',
        name: 'Level Staff (L2)',
      ),
      status: true,
      leaveBalances: [],
      employeeWorkLocation: [],
      coworkers: [],
    );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    return const [];
  }

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) => throw UnimplementedError();

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) => throw UnimplementedError();
}

void main() {
  Widget buildTestableWidget({
    required EmployeeRepository repository,
    String? employeeId = 'emp-101',
    EmployeeDirectoryItem? employee,
  }) {
    return MaterialApp(
      home: EmployeeDetailScreen(
        repository: repository,
        employeeId: employeeId,
        employee: employee,
        lifecycleRepository: FakeLifecycleRepository(),
      ),
    );
  }

  group('EmployeeDetailScreen Widget Tests', () {
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

    testWidgets('renders Employee Detail title, profile hero, and details', (tester) async {
      final repo = _FakeEmployeeDetailRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Employee Detail'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.textContaining('Backend Engineer'), findsWidgets);
      expect(find.text('EMP-777 • Finance Ops'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);
    });

    testWidgets('renders fallback employee directory item preview while loading', (tester) async {
      final repo = _FakeEmployeeDetailRepo(delay: const Duration(seconds: 1));
      const previewEmp = EmployeeDirectoryItem(
        id: 'emp-99',
        name: 'Ahmad Dahlan',
        role: 'Tech Lead',
        department: 'Mobile Core',
        email: 'ahmad@oasish.com',
        initials: 'AD',
        company: 'PT Contoh Abadi',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          repository: repo,
          employeeId: 'emp-99',
          employee: previewEmp,
        ),
      );
      // Pump initial frame before async resolution
      await tester.pump();

      expect(find.text('Employee Detail'), findsOneWidget);
      expect(find.text('Ahmad Dahlan'), findsWidgets);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('shows snackbar when share icon is tapped', (tester) async {
      final repo = _FakeEmployeeDetailRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final shareBtn = find.byIcon(LucideIcons.share2);
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      expect(find.text('Membagikan profil karyawan...'), findsOneWidget);
    });

    testWidgets('404 menampilkan pesan API dan hanya tombol Kembali', (tester) async {
      final repo = _FakeEmployeeDetailRepo(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Employee Detail'), findsOneWidget);
      expect(find.text('Data pegawai tidak ditemukan'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
      // Tidak boleh lagi menampilkan data demo palsu saat gagal memuat.
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('3171012345670001'), findsNothing);
      expect(find.text('Bank BCA'), findsNothing);
    });

    testWidgets('error 500 menampilkan pesan API dan tombol Coba Lagi', (tester) async {
      final repo = _FakeEmployeeDetailRepo(shouldFail: true, failStatus: 500);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Data pegawai tidak ditemukan'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Coba Lagi'), findsOneWidget);
      expect(find.text('Kembali'), findsNothing);
    });

    testWidgets('403 menyembunyikan konten profil dan menampilkan error di tengah', (tester) async {
      final repo = _FakeEmployeeDetailRepo(shouldFail: true, failStatus: 403);
      const previewEmp = EmployeeDirectoryItem(
        id: 'emp-99',
        name: 'Ahmad Dahlan',
        role: 'Tech Lead',
        department: 'Mobile Core',
        email: 'ahmad@oasish.com',
        initials: 'AD',
        company: 'PT Contoh Abadi',
      );

      await tester.pumpWidget(buildTestableWidget(
        repository: repo,
        employeeId: 'emp-99',
        employee: previewEmp,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Data pegawai tidak ditemukan'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
      // Konten halaman & aksi app bar disembunyikan
      expect(find.text('Ahmad Dahlan'), findsNothing);
      expect(find.byIcon(LucideIcons.share2), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });
}
