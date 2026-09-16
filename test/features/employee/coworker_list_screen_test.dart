import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/pages/coworker_list_screen.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeCoworkerRepository implements EmployeeRepository {
  List<EmployeeDirectoryItem> mockCoworkers;
  _FakeCoworkerRepository({required this.mockCoworkers});

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    return mockCoworkers;
  }

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final coworker1 = const EmployeeDirectoryItem(
    id: 'cw-1',
    name: 'Budi Santoso',
    role: 'UI/UX Designer',
    department: 'Product & Design',
    email: 'budi.santoso@oasish.com',
    phone: '081234567890',
    employeeNumber: 'EMP-001',
    initials: 'BS',
  );

  final coworker2 = const EmployeeDirectoryItem(
    id: 'cw-2',
    name: 'Dewi Lestari',
    role: 'Frontend Engineer',
    department: 'Engineering',
    email: 'dewi.lestari@oasish.com',
    phone: '081298765432',
    employeeNumber: 'EMP-002',
    initials: 'DL',
  );

  Widget createTestWidget({
    List<EmployeeDirectoryItem>? initialCoworkers,
    String? employeeName,
    String? departmentName,
    EmployeeRepository? repository,
  }) {
    return MaterialApp(
      home: CoworkerListScreen(
        args: CoworkerListArgs(
          initialCoworkers: initialCoworkers,
          employeeName: employeeName,
          departmentName: departmentName,
        ),
        repository: repository ?? _FakeCoworkerRepository(mockCoworkers: [coworker1, coworker2]),
      ),
    );
  }

  group('CoworkerListScreen Widget Tests', () {
    testWidgets('Renders AppBar title and subtitle with employee and department info', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialCoworkers: [coworker1, coworker2],
          employeeName: 'Sarah Jenkins',
          departmentName: 'Engineering',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daftar Rekan Kerja'), findsOneWidget);
      expect(find.text('Sarah Jenkins • Engineering'), findsOneWidget);
      expect(find.byType(EmployeeCard), findsNWidgets(2));
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsOneWidget);
    });

    testWidgets('Real-time search filters coworkers list', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialCoworkers: [coworker1, coworker2],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsNWidgets(2));

      // Enter search text "Dewi"
      await tester.enterText(find.byType(TextField), 'Dewi');
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsNWidgets(2));
    });

    testWidgets('Shows empty state when search returns no matching coworkers', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialCoworkers: [coworker1, coworker2],
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query that doesn't match
      await tester.enterText(find.byType(TextField), 'NonExistentPerson');
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsNothing);
      expect(find.text('Rekan Kerja Tidak Ditemukan'), findsOneWidget);
      expect(find.textContaining('Tidak ada rekan kerja yang cocok dengan kata kunci "NonExistentPerson"'), findsOneWidget);
    });

    testWidgets('Shows empty state when coworker list is completely empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialCoworkers: const [],
          repository: _FakeCoworkerRepository(mockCoworkers: const []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsNothing);
      expect(find.text('Belum Ada Rekan Kerja'), findsOneWidget);
    });
  });
}
