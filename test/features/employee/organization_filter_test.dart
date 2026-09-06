import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';

class MockOrganizationFilterRepository implements OrganizationFilterRepository {
  List<CompanyItem> mockCompanies = [];
  List<DepartmentItem> mockDepartments = [];
  List<PositionItem> mockPositions = [];

  String? lastCompanySearch;
  String? lastDepartmentCompanyId;
  String? lastDepartmentSearch;
  String? lastPositionCompanyId;
  String? lastPositionDepartmentId;
  String? lastPositionSearch;

  @override
  Future<List<CompanyItem>> getCompanies({String? search}) async {
    lastCompanySearch = search;
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
    lastDepartmentCompanyId = companyId;
    lastDepartmentSearch = search;
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
    lastPositionCompanyId = companyId;
    lastPositionDepartmentId = departmentId;
    lastPositionSearch = search;
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
  group('Organization Filter Models Serialization Tests', () {
    test('CompanyItem correctly parses API response format', () {
      final json = {
        'id': 'comp-1',
        'name': 'PT Oasish Group',
        'tenantId': null,
        'parentId': null,
        'address': 'Jakarta Pusat',
        'phone': '021-12345678',
        'email': 'info@oasis.corp',
        'logoUrl': null,
      };

      final item = CompanyItem.fromJson(json);
      expect(item.id, 'comp-1');
      expect(item.name, 'PT Oasish Group');
      expect(item.address, 'Jakarta Pusat');
      expect(item.email, 'info@oasis.corp');
      expect(item.tenantId, isNull);

      final outJson = item.toJson();
      expect(outJson['id'], 'comp-1');
      expect(outJson['name'], 'PT Oasish Group');
    });

    test('DepartmentItem correctly parses API response format', () {
      final json = {
        'id': 'dept-1',
        'name': 'Engineering',
        'code': 'ENG',
        'description': 'Software and hardware development',
        'companyId': 'comp-1',
        'company': {
          'id': 'comp-1',
          'name': 'PT Oasish Group',
        },
      };

      final item = DepartmentItem.fromJson(json);
      expect(item.id, 'dept-1');
      expect(item.name, 'Engineering');
      expect(item.companyId, 'comp-1');
      expect(item.companyName, 'PT Oasish Group');
    });

    test('PositionItem correctly parses API response format', () {
      final json = {
        'id': 'pos-1',
        'name': 'Senior Frontend Engineer',
        'code': 'SFE',
        'description': null,
        'companyId': 'comp-1',
        'departmentId': 'dept-1',
        'company': {
          'id': 'comp-1',
          'name': 'PT Oasish Group',
        },
        'department': {
          'id': 'dept-1',
          'name': 'Engineering',
        },
      };

      final item = PositionItem.fromJson(json);
      expect(item.id, 'pos-1');
      expect(item.name, 'Senior Frontend Engineer');
      expect(item.companyId, 'comp-1');
      expect(item.departmentId, 'dept-1');
      expect(item.companyName, 'PT Oasish Group');
      expect(item.departmentName, 'Engineering');
    });
  });

  group('EmployeeFilterCriteria Tests', () {
    test('Computes active filter status and count accurately', () {
      const criteriaEmpty = EmployeeFilterCriteria();
      expect(criteriaEmpty.hasActiveFilter, isFalse);
      expect(criteriaEmpty.activeFilterCount, 0);

      const criteriaAll = EmployeeFilterCriteria(
        company: 'Semua Perusahaan',
        department: 'Semua Departemen',
        position: 'Semua Jabatan',
      );
      expect(criteriaAll.hasActiveFilter, isFalse);
      expect(criteriaAll.activeFilterCount, 0);

      final criteriaWithCompany = criteriaEmpty.copyWith(
        companyId: 'comp-1',
        company: 'PT Oasish Group',
      );
      expect(criteriaWithCompany.hasActiveFilter, isTrue);
      expect(criteriaWithCompany.activeFilterCount, 1);

      final criteriaWithAll = criteriaWithCompany.copyWith(
        departmentId: 'dept-1',
        department: 'Engineering',
        positionId: 'pos-1',
        position: 'Senior Frontend Engineer',
      );
      expect(criteriaWithAll.hasActiveFilter, isTrue);
      expect(criteriaWithAll.activeFilterCount, 3);
    });
  });

  group('EmployeeFilterBottomSheet Widget Tests', () {
    late MockOrganizationFilterRepository mockRepo;

    setUp(() {
      mockRepo = MockOrganizationFilterRepository();
      mockRepo.mockCompanies = [
        const CompanyItem(id: 'comp-1', name: 'PT Oasish Group'),
        const CompanyItem(id: 'comp-2', name: 'PT Oasish Nusantara'),
      ];
      mockRepo.mockDepartments = [
        const DepartmentItem(
          id: 'dept-1',
          name: 'Engineering',
          companyId: 'comp-1',
        ),
        const DepartmentItem(
          id: 'dept-2',
          name: 'Human Resources',
          companyId: 'comp-1',
        ),
      ];
      mockRepo.mockPositions = [
        const PositionItem(
          id: 'pos-1',
          name: 'Senior Frontend Engineer',
          companyId: 'comp-1',
          departmentId: 'dept-1',
        ),
        const PositionItem(
          id: 'pos-2',
          name: 'QA Engineer',
          companyId: 'comp-1',
          departmentId: 'dept-1',
        ),
      ];
    });

    testWidgets('Renders bottom sheet with loaded API data and allows selection', (
      WidgetTester tester,
    ) async {
      EmployeeFilterCriteria? returnedCriteria;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedCriteria = await showEmployeeFilterBottomSheet(
                    context,
                    initialCriteria: const EmployeeFilterCriteria(),
                    repository: mockRepo,
                  );
                },
                child: const Text('Open Filter'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Check header and labels
      expect(find.text('Filter Data Pegawai'), findsOneWidget);
      expect(find.text('Perusahaan (Company)'), findsOneWidget);
      expect(find.text('Departemen (Department)'), findsOneWidget);
      expect(find.text('Jabatan (Position)'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);

      // Tap on Perusahaan to open selector
      await tester.tap(find.text('Semua Perusahaan'));
      await tester.pumpAndSettle();

      // Check options from repository
      expect(find.text('PT Oasish Group'), findsOneWidget);
      expect(find.text('PT Oasish Nusantara'), findsOneWidget);

      // Select PT Oasish Group
      await tester.tap(find.text('PT Oasish Group'));
      await tester.pumpAndSettle();

      // Perusahaan field should now display PT Oasish Group
      expect(find.text('PT Oasish Group'), findsOneWidget);

      // Tap on Departemen to open selector
      await tester.tap(find.text('Semua Departemen'));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);
      await tester.tap(find.text('Engineering'));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);

      // Tap on Terapkan Filter
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      // Bottom sheet should close and return selected criteria
      expect(find.text('Filter Data Pegawai'), findsNothing);
      expect(returnedCriteria, isNotNull);
      expect(returnedCriteria?.company, 'PT Oasish Group');
      expect(returnedCriteria?.companyId, 'comp-1');
      expect(returnedCriteria?.department, 'Engineering');
      expect(returnedCriteria?.departmentId, 'dept-1');
    });

    testWidgets('Reset Filter resets all selections back to default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showEmployeeFilterBottomSheet(
                    context,
                    initialCriteria: const EmployeeFilterCriteria(
                      companyId: 'comp-1',
                      company: 'PT Oasish Group',
                      departmentId: 'dept-1',
                      department: 'Engineering',
                    ),
                    repository: mockRepo,
                  );
                },
                child: const Text('Open Filter'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('PT Oasish Group'), findsOneWidget);
      expect(find.text('Engineering'), findsOneWidget);

      // Tap Reset Filter
      await tester.tap(find.text('Reset Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Semua Perusahaan'), findsOneWidget);
      expect(find.text('Semua Departemen'), findsOneWidget);
      expect(find.text('Semua Jabatan'), findsOneWidget);
    });
  });
}
