import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/schedule/presentation/pages/employee_schedule_select_screen.dart';

class _FakeEmployeeSelectRepo implements EmployeeRepository {
  final bool shouldFail;
  final List<EmployeeDirectoryItem> employees;

  _FakeEmployeeSelectRepo({
    this.shouldFail = false,
    this.employees = const [],
  });

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        message: 'Gagal memuat daftar pegawai',
        statusCode: 500,
      );
    }

    var list = employees;
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
    }

    return EmployeeListResponse(
      success: true,
      message: 'OK',
      data: list,
      meta: EmployeePaginationMeta(
        page: page,
        limit: size,
        total: list.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) =>
      throw UnimplementedError();

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() =>
      throw UnimplementedError();

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) => throw UnimplementedError();
}

void main() {
  final sampleEmployees = [
    const EmployeeDirectoryItem(
      id: 'emp-1',
      name: 'Budi Santoso',
      role: 'Staff IT',
      department: 'Teknologi Informasi',
      email: 'budi@example.com',
      initials: 'BS',
      company: 'PT Muratech ID',
    ),
    const EmployeeDirectoryItem(
      id: 'emp-2',
      name: 'Siti Aminah',
      role: 'Finance Officer',
      department: 'Keuangan',
      email: 'siti@example.com',
      initials: 'SA',
      company: 'PT Muratech ID',
    ),
  ];

  Widget buildTestableWidget({required EmployeeRepository repository}) {
    return MaterialApp(
      home: EmployeeScheduleSelectScreen(repository: repository),
    );
  }

  group('EmployeeScheduleSelectScreen Widget Tests', () {
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

    testWidgets('renders title, subtitle, search bar, and employee list on success', (tester) async {
      final repo = _FakeEmployeeSelectRepo(employees: sampleEmployees);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Jadwal Pegawai'), findsOneWidget);
      expect(find.text('Pilih pegawai untuk melihat jadwal kerja'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Aminah'), findsOneWidget);
    });

    testWidgets('searches employee via AppSearchBar and filters list', (tester) async {
      final repo = _FakeEmployeeSelectRepo(employees: sampleEmployees);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'Siti');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Siti Aminah'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('renders empty state when no employees exist', (tester) async {
      final repo = _FakeEmployeeSelectRepo(employees: const []);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Data Pegawai'), findsOneWidget);
    });

    testWidgets('renders error view with retry button on failure', (tester) async {
      final repo = _FakeEmployeeSelectRepo(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat daftar pegawai'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}
