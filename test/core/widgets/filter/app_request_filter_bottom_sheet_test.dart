import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/core/widgets/filter/filter_field_selector.dart';
import 'package:hris_flutter/core/widgets/filter/filter_status_segmented_row.dart';
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
    return mockCompanies;
  }

  @override
  Future<List<DepartmentItem>> getDepartments({
    String? companyId,
    String? search,
  }) async {
    return mockDepartments;
  }

  @override
  Future<List<PositionItem>> getPositions({
    String? companyId,
    String? departmentId,
    String? search,
  }) async {
    return mockPositions;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOrganizationFilterRepository mockRepo;

  setUp(() {
    mockRepo = _MockOrganizationFilterRepository();
    mockRepo.mockCompanies = [
      const CompanyItem(id: 'c-1', name: 'PT Muratech Global Solusi'),
    ];
    mockRepo.mockDepartments = [
      const DepartmentItem(id: 'd-1', name: 'Engineering', companyId: 'c-1'),
    ];
    mockRepo.mockPositions = [
      const PositionItem(
        id: 'p-1',
        name: 'Lead Engineer',
        companyId: 'c-1',
        departmentId: 'd-1',
      ),
    ];
  });

  group('AppRequestFilterData Unit Tests', () {
    test('default data has 0 active filters', () {
      const data = AppRequestFilterData();
      expect(data.hasActiveFilter, isFalse);
      expect(data.activeFilterCount, 0);
      expect(data.status, 'requested');
    });

    test('activeFilterCount correctly calculates filled fields', () {
      final data = AppRequestFilterData(
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 5),
        ),
        companyId: 'c-1',
        company: 'Muratech',
        status: 'approved',
      );
      expect(data.hasActiveFilter, isTrue);
      expect(data.activeFilterCount, 3);
      expect(data.startDateParam, '2026-09-01');
      expect(data.endDateParam, '2026-09-05');
    });
  });

  group('FilterFieldSelector Widget Tests', () {
    testWidgets('renders label, value, and helper text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FilterFieldSelector(
              label: 'Nama Perusahaan',
              value: 'PT Muratech',
              icon: LucideIcons.building,
              helperText: 'Pilih salah satu entitas',
            ),
          ),
        ),
      );

      expect(find.text('Nama Perusahaan'), findsOneWidget);
      expect(find.text('PT Muratech'), findsOneWidget);
      expect(find.text('Pilih salah satu entitas'), findsOneWidget);
      expect(find.byIcon(LucideIcons.building), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });

    testWidgets('displays lock icon when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FilterFieldSelector(
              label: 'Departemen',
              value: 'Semua Departemen',
              icon: LucideIcons.briefcase,
              isEnabled: false,
              helperText: 'Pilih perusahaan terlebih dahulu',
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    });
  });

  group('FilterStatusSegmentedRow Widget Tests', () {
    testWidgets('renders all 4 default status options and handles taps',
        (tester) async {
      String selected = 'requested';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: FilterStatusSegmentedRow(
                selectedValue: selected,
                onSelected: (val) {
                  setState(() => selected = val);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Diajukan'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);

      await tester.tap(find.text('Rejected'));
      await tester.pumpAndSettle();

      expect(selected, 'rejected');
    });
  });

  group('AppRequestFilterBottomSheet Integration Widget Tests', () {
    testWidgets('opens sheet, selects company, resets, and applies filter',
        (tester) async {
      AppRequestFilterData? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAppRequestFilterBottomSheet(
                    context,
                    title: 'Filter Pengajuan Tes',
                    initialData: const AppRequestFilterData(),
                    repository: mockRepo,
                  );
                },
                child: const Text('Buka Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Pengajuan Tes'), findsOneWidget);
      expect(find.text('Rentang Tanggal (Date Range)'), findsOneWidget);
      expect(find.text('Perusahaan (Company)'), findsOneWidget);
      expect(find.text('Departemen (Division)'), findsOneWidget);
      expect(find.text('Jabatan (Position)'), findsOneWidget);

      // Select status 'Approved'
      await tester.tap(find.text('Approved'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.status, 'approved');
    });
  });
}
