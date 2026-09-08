import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_logs_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_log_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_summary_card.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TestLogsRepository implements AttendanceRepository {
  final List<AttendanceLogItem> logs;
  final int totalPages;
  final List<EmployeeDirectoryItem> teamEmployees;
  final bool throw403OnTeam;

  TestLogsRepository({
    required this.logs,
    this.totalPages = 2,
    this.teamEmployees = const [],
    this.throw403OnTeam = false,
  });

  @override
  Future<AttendanceLogListResponse> getAttendanceLogs({
    int page = 1,
    int size = 20,
    String? employeeId,
    bool lastMonth = false,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  }) async {
    return AttendanceLogListResponse(
      success: true,
      message: 'Success',
      data: logs,
      meta: AttendanceLogPaginationMeta(
        page: page,
        limit: size,
        total: logs.length * totalPages,
        totalPages: totalPages,
      ),
    );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async {
    if (throw403OnTeam) {
      throw const ApiException(
        message: 'Tidak ada hak akses',
        statusCode: 403,
      );
    }
    return teamEmployees;
  }

  @override
  Future<AttendanceLogSummary> getAttendanceSummary() async {
    return const AttendanceLogSummary(
      totalInDays: 22,
      presentPercentage: 100,
      lateMinutes: 15,
      lateCount: 0,
    );
  }

  @override
  Future<AttendanceTodayData> getTodayAttendance() async =>
      throw UnimplementedError();

  @override
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceTodayData> toggleBreak() async =>
      throw UnimplementedError();

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testLogs = [
    AttendanceLogItem(
      id: 'LOG-1',
      dateTime: DateTime(2026, 8, 27, 8, 45),
      type: AttendanceLogType.clockIn,
      locationName: 'Jakarta HQ Office',
      method: 'GPS Mobile',
    ),
    AttendanceLogItem(
      id: 'LOG-2',
      dateTime: DateTime(2026, 8, 27, 17, 30),
      type: AttendanceLogType.clockOut,
      locationName: 'Jakarta HQ Office',
      method: 'GPS Mobile',
    ),
    AttendanceLogItem(
      id: 'LOG-3',
      dateTime: DateTime(2026, 8, 26, 9, 18),
      type: AttendanceLogType.clockIn,
      locationName: 'Jakarta HQ Office',
      method: 'Geofence Auto',
      lateMinutes: 18,
    ),
  ];

  final testEmployees = const [
    EmployeeDirectoryItem(
      id: 'EMP-092',
      name: 'Sarah Jenkins',
      role: 'Frontend Engineer',
      department: 'Engineering',
      email: 's.jenkins@oasis.corp',
      initials: 'SJ',
    ),
    EmployeeDirectoryItem(
      id: 'EMP-145',
      name: 'Brian Smith',
      role: 'Backend Engineer',
      department: 'Engineering',
      email: 'b.smith@oasis.corp',
      initials: 'BS',
    ),
  ];

  Widget createTestWidget() {
    return MaterialApp(
      home: AttendanceLogsScreen(
        attendanceLogsBloc: AttendanceLogsBloc(
          repository: TestLogsRepository(logs: testLogs),
        )..add(const AttendanceLogsStarted()),
        employeeListBloc: EmployeeListBloc(
          initialCustomEmployees: testEmployees,
        )..add(EmployeeListStarted(customEmployees: testEmployees)),
      ),
    );
  }

  group('AttendanceLogsScreen UI Tests (Google Stitch Specifications)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize =
          const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('renders AppBar with only filter icon and M3 tabs', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Attendance Logs'), findsOneWidget);
      expect(find.text('Track clock-in & clock-out activity'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsNothing);
      expect(find.byIcon(LucideIcons.download), findsNothing);

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.text('My Attendance'), findsOneWidget);
      expect(find.text('Team Attendance'), findsOneWidget);
    });

    testWidgets('does NOT render filter chips row from Stitch design', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('renders KPI summary cards and log cards on My Attendance', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceLogsSummaryCard), findsOneWidget);
      expect(find.text('22 Days'), findsOneWidget);
      expect(find.text('15 Mins'), findsOneWidget);
      expect(find.text('100% Present'), findsOneWidget);
      expect(find.text('0 Late records'), findsOneWidget);

      expect(find.byType(AttendanceLogCard), findsNWidgets(3));
      expect(find.text('Thursday, 27 Aug 2026'), findsNWidgets(2));
      expect(find.text('08:45 AM WIB'), findsOneWidget);
      expect(find.text('05:30 PM WIB'), findsOneWidget);
      expect(find.text('09:18 AM WIB'), findsOneWidget);
      expect(find.text('Late by 18 mins'), findsOneWidget);
      expect(find.text('On Time'), findsOneWidget);
      expect(find.text('Location: '), findsNothing);
    });

    testWidgets('renders Load Previous Period button when more pages exist', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Load Previous Period'), findsOneWidget);
      expect(find.byIcon(LucideIcons.history), findsWidgets);
    });

    testWidgets('switches to Team Attendance tab and lists team members', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Team Attendance'));
      await tester.pumpAndSettle();

      expect(find.text('Search team member...'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Frontend Engineer • Engineering'), findsOneWidget);
      expect(find.text('Brian Smith'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsNWidgets(2));
    });

    testWidgets('renders month selector chips and handles month toggle', (
      tester,
    ) async {
      final logsBloc = AttendanceLogsBloc(
        repository: TestLogsRepository(logs: testLogs),
      )..add(const AttendanceLogsStarted());

      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceLogsScreen(
            attendanceLogsBloc: logsBloc,
            employeeListBloc: EmployeeListBloc(
              initialCustomEmployees: testEmployees,
            )..add(EmployeeListStarted(customEmployees: testEmployees)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('Bulan Lalu'), findsOneWidget);

      await tester.tap(find.text('Bulan Lalu'));
      await tester.pumpAndSettle();

      expect(logsBloc.state.lastMonth, isTrue);
    });

    testWidgets('displays Tidak ada hak akses on 403 Forbidden error in Team Attendance', (
      tester,
    ) async {
      final failingRepo = TestLogsRepository(
        logs: testLogs,
        throw403OnTeam: true,
      );

      final employeeBloc = EmployeeListBloc(
        attendanceRepository: failingRepo,
      )..add(const EmployeeListStarted(isTeamAttendance: true));

      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceLogsScreen(
            attendanceLogsBloc: AttendanceLogsBloc(
              repository: failingRepo,
            )..add(const AttendanceLogsStarted()),
            employeeListBloc: employeeBloc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Team Attendance'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Hak Akses'), findsOneWidget);
      expect(find.text('Tidak ada hak akses'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });
  });
}
