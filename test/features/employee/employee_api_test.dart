import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';

class MockEmployeeRepository implements EmployeeRepository {
  int? lastPage;
  int? lastSize;
  String? lastCompanyId;
  String? lastDepartmentId;
  String? lastPositionId;
  String? lastSearch;

  List<EmployeeDirectoryItem> mockEmployees = [];
  int mockTotal = 0;
  int mockTotalPages = 1;

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    lastPage = page;
    lastSize = size;
    lastCompanyId = companyId;
    lastDepartmentId = departmentId;
    lastPositionId = positionId;
    lastSearch = search;

    var list = mockEmployees;
    if (companyId != null && companyId.isNotEmpty) {
      list = list.where((e) => e.companyId == companyId).toList();
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      list = list.where((e) => e.departmentId == departmentId).toList();
    }
    if (positionId != null && positionId.isNotEmpty) {
      list = list.where((e) => e.positionId == positionId).toList();
    }
    if (search != null && search.isNotEmpty) {
      list = list
          .where((e) => e.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    return EmployeeListResponse(
      success: true,
      message: 'OK',
      data: list,
      meta: EmployeePaginationMeta(
        page: page,
        limit: size,
        total: mockTotal > 0 ? mockTotal : list.length,
        totalPages: mockTotalPages,
      ),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    return EmployeeDetailData(
      id: employeeId,
      firstName: 'Mock',
      lastName: 'User',
      email: 'mock@example.com',
      phone: '08123456789',
    );
  }
}

void main() {
  group('Employee API Model Serialization Tests', () {
    test('EmployeeDirectoryItem.fromJson parses full API response payload', () {
      final json = {
        'id': 'uuid-1234',
        'firstName': 'Sarah',
        'lastName': 'Jenkins',
        'email': 's.jenkins@oasis.corp',
        'phone': '+62 812-3456-7890',
        'idNumber': '3201234567890001',
        'employeeNumber': 'EMP-092',
        'company': {
          'id': 'comp-uuid-1',
          'name': 'PT Oasish Group',
        },
        'department': {
          'id': 'dept-uuid-1',
          'name': 'Engineering',
          'code': 'ENG',
        },
        'position': {
          'id': 'pos-uuid-1',
          'name': 'Senior Frontend Engineer',
          'code': 'SFE',
        },
        'photoUrl': 'https://example.com/avatar.jpg',
      };

      final item = EmployeeDirectoryItem.fromJson(json);

      expect(item.id, 'EMP-092');
      expect(item.name, 'Sarah Jenkins');
      expect(item.role, 'Senior Frontend Engineer');
      expect(item.department, 'Engineering');
      expect(item.company, 'PT Oasish Group');
      expect(item.email, 's.jenkins@oasis.corp');
      expect(item.phone, '+62 812-3456-7890');
      expect(item.avatarUrl, 'https://example.com/avatar.jpg');
      expect(item.initials, 'SJ');
      expect(item.companyId, 'comp-uuid-1');
      expect(item.departmentId, 'dept-uuid-1');
      expect(item.positionId, 'pos-uuid-1');
    });

    test('EmployeeDirectoryItem.fromJson handles null lastName and fallback employee number', () {
      final json = {
        'id': 'uuid-5678',
        'firstName': 'Budi',
        'lastName': null,
        'email': 'budi@oasis.corp',
        'phone': null,
        'idNumber': null,
        'employeeNumber': null,
        'company': null,
        'department': null,
        'position': null,
        'photoUrl': null,
      };

      final item = EmployeeDirectoryItem.fromJson(json);

      expect(item.id, 'uuid-5678');
      expect(item.name, 'Budi');
      expect(item.initials, 'BU');
      expect(item.role, 'Staff');
      expect(item.department, 'Umum');
      expect(item.company, isNull);
    });

    test('EmployeeListResponse parses full response with meta', () {
      final responseJson = {
        'success': true,
        'message': 'Data pegawai berhasil diambil',
        'data': [
          {
            'id': 'emp-1',
            'firstName': 'Alex',
            'lastName': 'Rivera',
            'email': 'a.rivera@oasis.corp',
            'phone': '+62 812-7788-9900',
            'idNumber': null,
            'employeeNumber': 'EMP-005',
            'company': {'id': 'comp-1', 'name': 'PT Oasish Group'},
            'department': {'id': 'dept-1', 'name': 'Engineering', 'code': 'ENG'},
            'position': {'id': 'pos-1', 'name': 'Engineering Manager', 'code': 'EM'},
            'photoUrl': null,
          }
        ],
        'meta': {
          'page': 1,
          'limit': 30,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = EmployeeListResponse.fromJson(responseJson);

      expect(response.success, isTrue);
      expect(response.message, 'Data pegawai berhasil diambil');
      expect(response.data.length, 1);
      expect(response.data.first.name, 'Alex Rivera');
      expect(response.meta.page, 1);
      expect(response.meta.limit, 30);
      expect(response.meta.total, 1);
      expect(response.meta.totalPages, 1);
    });
  });

  group('EmployeeDirectoryScreen API & Scroll Behavior Tests', () {
    late MockEmployeeRepository mockRepo;

    setUp(() {
      mockRepo = MockEmployeeRepository();
      mockRepo.mockEmployees = List.generate(
        15,
        (i) => EmployeeDirectoryItem(
          id: 'EMP-00$i',
          name: 'Employee $i',
          role: 'Engineer',
          department: 'Engineering',
          company: 'PT Oasish Group',
          email: 'emp$i@oasis.corp',
          initials: 'E$i',
        ),
      );
      mockRepo.mockTotal = 15;
    });

    testWidgets('Loads data from EmployeeRepository with default size 30', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(employeeRepository: mockRepo),
        ),
      );

      // Initial pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastPage, 1);
      expect(mockRepo.lastSize, 30);
      expect(find.text('Employee 0'), findsOneWidget);
      expect(find.text('Employee 1'), findsOneWidget);
    });

    testWidgets('Search bar hides on scroll down and reappears on scroll up', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(employeeRepository: mockRepo),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial state: Search TextField is visible
      expect(find.byType(TextField), findsOneWidget);

      // Find the AnimatedContainer wrapping the search bar
      final searchContainerFinder = find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(AnimatedContainer),
      );
      expect(searchContainerFinder, findsOneWidget);

      AnimatedContainer searchContainer = tester.widget(searchContainerFinder);
      expect(searchContainer.constraints?.maxHeight, 62.0);

      // Scroll content UP (user drag finger down/up)
      // Drag down by -300 to scroll downwards into feed (reverse scroll)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // AnimatedContainer height should animate to 0
      searchContainer = tester.widget(searchContainerFinder);
      expect(searchContainer.constraints?.maxHeight, 0.0);

      // Scroll back UP (user drag finger downwards, forward scroll)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // AnimatedContainer height should expand back to 62
      searchContainer = tester.widget(searchContainerFinder);
      expect(searchContainer.constraints?.maxHeight, 62.0);
    });
  });
}
