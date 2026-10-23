import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_lifecycle_repository.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_detail_shimmer_loading.dart';
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
    bool? isFromDirectory,
  }) {
    return MaterialApp(
      home: EmployeeDetailScreen(
        repository: repository,
        employeeId: employeeId,
        employee: employee,
        isFromDirectory: isFromDirectory,
        lifecycleRepository: FakeLifecycleRepository(),
      ),
    );
  }

  group('EmployeeDetailScreen Widget Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SecureStorageService.instance.setEmployeeIdInMemory(null);
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      SecureStorageService.instance.setEmployeeIdInMemory(null);
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

    testWidgets('menyembunyikan tombol Call dan Email saat melihat profil sendiri', (tester) async {
      final repo = _FakeEmployeeDetailRepo();

      // isFromDirectory: false berarti melihat profil sendiri
      await tester.pumpWidget(buildTestableWidget(
        repository: repo,
        isFromDirectory: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Call'), findsNothing);
      expect(find.text('Email'), findsNothing);
    });

    testWidgets('menampilkan tombol Call dan Email saat melihat profil rekan kerja (isFromDirectory: true)', (tester) async {
      final repo = _FakeEmployeeDetailRepo();
      SecureStorageService.instance.setEmployeeIdInMemory('my-logged-in-id');

      await tester.pumpWidget(buildTestableWidget(
        repository: repo,
        employeeId: 'emp-101',
        isFromDirectory: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('menyembunyikan tombol Call dan Email dari direktori jika ID cocok dengan akun sendiri', (tester) async {
      final repo = _FakeEmployeeDetailRepo();
      // Detail yang dikembalikan _FakeEmployeeDetailRepo memiliki id 'emp-101'
      SecureStorageService.instance.setEmployeeIdInMemory('emp-101');

      await tester.pumpWidget(buildTestableWidget(
        repository: repo,
        employeeId: 'emp-101',
        isFromDirectory: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Call'), findsNothing);
      expect(find.text('Email'), findsNothing);
    });

    testWidgets('menampilkan bottom sheet share dengan pilihan WhatsApp, Email, Salin Link, dan Bagikan Lainnya', (tester) async {
      final repo = _FakeEmployeeDetailRepo();
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final shareBtn = find.byKey(const ValueKey('employee_detail_share_button'));
      expect(shareBtn, findsOneWidget);
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bagikan Profil'), findsOneWidget);
      expect(find.byKey(const ValueKey('employee_share_whatsapp')), findsOneWidget);
      expect(find.byKey(const ValueKey('employee_share_email')), findsOneWidget);
      expect(find.byKey(const ValueKey('employee_share_copy')), findsOneWidget);
      expect(find.byKey(const ValueKey('employee_share_more')), findsOneWidget);

      // Tap Salin Link dan pastikan dialog sukses muncul serta link tersalin
      await tester.tap(find.byKey(const ValueKey('employee_share_copy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(copiedText, contains('/employee/'));
      expect(find.text('Link Disalin'), findsOneWidget);
    });

    testWidgets('menampilkan shimmer saat memuat detail lalu konten setelah selesai', (tester) async {
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
      // Saat memuat: skeleton shimmer, bukan konten/loader linear
      expect(find.byType(EmployeeDetailShimmerLoading), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(EmployeeDetailShimmerLoading), findsNothing);
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
