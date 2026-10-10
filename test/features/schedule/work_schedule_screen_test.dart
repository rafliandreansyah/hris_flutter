import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:hris_flutter/features/schedule/domain/repositories/work_schedule_repository.dart';
import 'package:hris_flutter/features/schedule/presentation/pages/work_schedule_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeWorkScheduleRepository implements WorkScheduleRepository {
  final WorkScheduleResponse mockResponse = const WorkScheduleResponse(
    success: true,
    message: 'Success',
    data: WorkScheduleData(
      id: 'sched-1',
      employee: WorkScheduleEmployee(
        id: 'emp-1',
        firstName: 'Budi',
        lastName: 'Santoso',
        email: 'budi@example.com',
        companyName: 'Muratech',
        departmentName: 'Engineering',
        positionName: 'Developer',
      ),
      workSchedules: [
        WorkScheduleItem(
          id: 'ws-1',
          workDate: '2026-09-20',
          isDayOff: false,
          shift: WorkScheduleShift(
            id: 'shift-1',
            name: 'Regular Shift',
            startTime: '08:00',
            endTime: '17:00',
          ),
        ),
      ],
    ),
  );

  @override
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId}) async {
    return mockResponse;
  }
}

void main() {
  late _FakeWorkScheduleRepository repository;

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = _FakeWorkScheduleRepository();
    SecureStorageService.instance.setPermissionsInMemory([]);
  });

  tearDown(() {
    SecureStorageService.instance.setPermissionsInMemory([]);
  });

  Widget createTestWidget({
    String? employeeId,
    GoRouter? router,
  }) {
    if (router != null) {
      return MaterialApp.router(routerConfig: router);
    }

    return MaterialApp(
      home: WorkScheduleScreen(
        employeeId: employeeId,
        repository: repository,
      ),
    );
  }

  group('WorkScheduleScreen Permission & Adaptive UI Tests', () {
    testWidgets('shows Jadwal Pegawai Lain icon button when user has work_schedule.view permission', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.workScheduleView,
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Jadwal Kerja Saya'), findsOneWidget);
      expect(find.byIcon(LucideIcons.users), findsOneWidget);
    });

    testWidgets('hides Jadwal Pegawai Lain icon button when user lacks work_schedule.view permission', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Jadwal Kerja Saya'), findsOneWidget);
      expect(find.byIcon(LucideIcons.users), findsNothing);
    });

    testWidgets('hides Jadwal Pegawai Lain icon button when viewing other employee schedule', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.workScheduleView,
      ]);

      await tester.pumpWidget(createTestWidget(employeeId: 'emp-2'));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Jadwal Kerja Pegawai')), findsOneWidget);
      expect(find.byIcon(LucideIcons.users), findsNothing);
    });

    testWidgets('tapping Jadwal Pegawai Lain icon navigates to employee schedule select', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([
        AppPermissions.workScheduleView,
      ]);

      final router = GoRouter(
        initialLocation: '/schedule',
        routes: [
          GoRoute(
            path: '/schedule',
            builder: (context, state) => WorkScheduleScreen(
              repository: repository,
            ),
          ),
          GoRoute(
            path: Routes.EMPLOYEE_SCHEDULE_SELECT,
            builder: (context, state) => const Scaffold(
              body: Text('Employee Schedule Selection Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.users));
      await tester.pumpAndSettle();

      expect(find.text('Employee Schedule Selection Screen'), findsOneWidget);
    });
  });
}
