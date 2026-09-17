import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _MockOrganizationFilterRepository
    implements OrganizationFilterRepository {
  List<CompanyItem> mockCompanies = [];
  List<DepartmentItem> mockDepartments = [];
  List<PositionItem> mockPositions = [];

  @override
  Future<List<CompanyItem>> getCompanies({String? search}) async {
    if (search != null && search.isNotEmpty) {
      return mockCompanies
          .where((c) => c.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return mockCompanies;
  }

  @override
  Future<List<DepartmentItem>> getDepartments({
    String? companyId,
    String? search,
  }) async {
    var list = mockDepartments;
    if (companyId != null && companyId.isNotEmpty) {
      list = list.where((d) => d.companyId == companyId).toList();
    }
    if (search != null && search.isNotEmpty) {
      list = list
          .where((d) => d.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Future<List<PositionItem>> getPositions({
    String? companyId,
    String? departmentId,
    String? search,
  }) async {
    var list = mockPositions;
    if (companyId != null && companyId.isNotEmpty) {
      list = list.where((p) => p.companyId == companyId).toList();
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      list = list.where((p) => p.departmentId == departmentId).toList();
    }
    if (search != null && search.isNotEmpty) {
      list = list
          .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return list;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOrganizationFilterRepository mockRepo;

  setUp(() {
    mockRepo = _MockOrganizationFilterRepository();
    mockRepo.mockCompanies = [
      const CompanyItem(id: 'c-1', name: 'PT Muratech Global Solusi'),
      const CompanyItem(id: 'c-2', name: 'PT Oasish Tech Nusantara'),
    ];
    mockRepo.mockDepartments = [
      const DepartmentItem(id: 'd-1', name: 'Engineering', companyId: 'c-1'),
      const DepartmentItem(id: 'd-2', name: 'Operations', companyId: 'c-1'),
    ];
    mockRepo.mockPositions = [
      const PositionItem(
        id: 'p-1',
        name: 'Senior Backend Engineer',
        companyId: 'c-1',
        departmentId: 'd-1',
      ),
      const PositionItem(
        id: 'p-2',
        name: 'Site Supervisor',
        companyId: 'c-1',
        departmentId: 'd-2',
      ),
    ];
  });

  Widget buildTestWidget({
    AttendanceRequestFilterCriteria? initialCriteria,
    required void Function(AttendanceRequestFilterCriteria? result) onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final res = await showAttendanceRequestFilterBottomSheet(
                context,
                initialCriteria:
                    initialCriteria ?? const AttendanceRequestFilterCriteria(),
                repository: mockRepo,
              );
              onResult(res);
            },
            child: const Text('Buka Filter'),
          ),
        ),
      ),
    );
  }

  group('AttendanceRequestFilterCriteria Unit Tests', () {
    test('default criteria has no active filter', () {
      const criteria = AttendanceRequestFilterCriteria();
      expect(criteria.hasActiveFilter, isFalse);
      expect(criteria.activeFilterCount, 0);
      expect(criteria.status, 'requested');
    });

    test('activeFilterCount correctly increments for each active field', () {
      final criteria = AttendanceRequestFilterCriteria(
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 10),
        ),
        companyId: 'c-1',
        company: 'PT Muratech Global Solusi',
        departmentId: 'd-1',
        department: 'Engineering',
        positionId: 'p-1',
        position: 'Senior Backend Engineer',
        status: 'approved',
      );

      expect(criteria.hasActiveFilter, isTrue);
      expect(criteria.activeFilterCount, 5);
      expect(criteria.startDateParam, '2026-09-01');
      expect(criteria.endDateParam, '2026-09-10');
    });

    test('copyWith works correctly', () {
      const criteria = AttendanceRequestFilterCriteria();
      final updated = criteria.copyWith(status: 'rejected');
      expect(updated.status, 'rejected');
      expect(updated.hasActiveFilter, isTrue);
    });
  });

  group('AttendanceRequestFilterBottomSheet Widget Tests', () {
    testWidgets('renders all Stitch M3 standard filter elements',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(onResult: (_) {}),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Buka Filter'));
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Filter Pengajuan Presensi'), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);

      // 2. Date Range Field
      expect(find.text('Rentang Tanggal (Date Range)'), findsOneWidget);
      expect(find.text('Semua Rentang Waktu'), findsOneWidget);
      expect(find.text('Pilih rentang tanggal mulai hingga selesai'),
          findsOneWidget);

      // 3. Status Pengajuan (4 segmented chips)
      expect(find.text('Status Pengajuan'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Diajukan'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(
        find.text('Default memuat status pengajuan diminta (requested)'),
        findsOneWidget,
      );

      // 4. Perusahaan (Company)
      expect(find.text('Perusahaan (Company)'), findsOneWidget);
      expect(find.text('Semua Perusahaan'), findsOneWidget);

      // 5. Departemen (Division) & Jabatan (Position) - disabled
      expect(find.text('Departemen (Division)'), findsOneWidget);
      expect(find.text('Jabatan (Position)'), findsOneWidget);
      expect(find.text('Pilih perusahaan terlebih dahulu'), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.lock), findsNWidgets(2));

      // 6. Action buttons
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);
    });

    testWidgets('status chip selection updates selected status',
        (tester) async {
      AttendanceRequestFilterCriteria? result;
      await tester.pumpWidget(
        buildTestWidget(onResult: (res) => result = res),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Filter'));
      await tester.pumpAndSettle();

      // Select 'Approved'
      await tester.tap(find.text('Approved'));
      await tester.pumpAndSettle();

      // Tap 'Terapkan Filter'
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.status, 'approved');
    });

    testWidgets(
        'selecting company opens option selector and enables department & position',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(onResult: (_) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Filter'));
      await tester.pumpAndSettle();

      // Tap Company field
      await tester.tap(find.text('Semua Perusahaan'));
      await tester.pumpAndSettle();

      // Option modal sheet is opened
      expect(find.text('Pilih Perusahaan'), findsOneWidget);
      expect(find.text('PT Muratech Global Solusi'), findsOneWidget);

      // Select PT Muratech
      await tester.tap(find.text('PT Muratech Global Solusi'));
      await tester.pumpAndSettle();

      // Now company is selected and lock icons are gone
      expect(find.text('PT Muratech Global Solusi'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsNothing);
      expect(find.text('Filter berdasarkan divisi organisasi kerja'),
          findsOneWidget);
    });

    testWidgets('Reset Filter resets state back to default', (tester) async {
      AttendanceRequestFilterCriteria? result;
      await tester.pumpWidget(
        buildTestWidget(
          initialCriteria: const AttendanceRequestFilterCriteria(
            status: 'approved',
            company: 'PT Muratech Global Solusi',
            companyId: 'c-1',
          ),
          onResult: (res) => result = res,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Filter'));
      await tester.pumpAndSettle();

      // Check initially loaded with 'PT Muratech Global Solusi'
      expect(find.text('PT Muratech Global Solusi'), findsOneWidget);

      // Tap Reset Filter
      await tester.tap(find.text('Reset Filter'));
      await tester.pumpAndSettle();

      // Should reset to 'Semua Perusahaan' and lock downstream
      expect(find.text('Semua Perusahaan'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsNWidgets(2));

      // Apply
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.hasActiveFilter, isFalse);
      expect(result!.status, 'requested');
    });
  });
}
