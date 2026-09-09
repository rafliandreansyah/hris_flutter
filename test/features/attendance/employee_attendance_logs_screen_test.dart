import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/employee_attendance_logs_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_log_card.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MockEmployeeLogsRepository implements AttendanceRepository {
  final List<AttendanceLogItem> logs;
  final AttendanceLogSummary? summary;
  final bool shouldThrow;
  final int? throwStatusCode;
  final String? throwMessage;

  MockEmployeeLogsRepository({
    this.logs = const [],
    this.summary,
    this.shouldThrow = false,
    this.throwStatusCode,
    this.throwMessage,
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
    if (shouldThrow) {
      throw ApiException(
        message: throwMessage ?? 'Gagal memuat riwayat absensi.',
        statusCode: throwStatusCode ?? 500,
      );
    }
    return AttendanceLogListResponse(
      success: true,
      message: 'Success',
      data: logs,
      meta: AttendanceLogPaginationMeta(
        page: page,
        limit: size,
        total: logs.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) async {
    if (shouldThrow) {
      throw ApiException(
        message: throwMessage ?? 'Error summary',
        statusCode: throwStatusCode ?? 500,
      );
    }
    return summary ??
        const AttendanceLogSummary(
          totalInDays: 20,
          presentPercentage: 95,
          lateMinutes: 10,
          lateCount: 1,
        );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async => [];

  @override
  Future<AttendanceTodayData> getTodayAttendance() async =>
      throw UnimplementedError();

  @override
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AttendanceTodayData> toggleBreak() async => throw UnimplementedError();

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testEmployee = EmployeeDirectoryItem(
    id: 'EMP-092',
    rawId: 'uuid-sarah-123',
    name: 'Sarah Jenkins',
    role: 'Senior Frontend Engineer',
    department: 'Engineering',
    company: 'PT Oasish Group',
    email: 's.jenkins@oasis.corp',
    phone: '+62 812-3456-7890',
    initials: 'SJ',
  );

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
  ];

  Widget createTestWidget({
    required AttendanceRepository repo,
    EmployeeDirectoryItem employee = testEmployee,
  }) {
    return MaterialApp(
      home: EmployeeAttendanceLogsScreen(
        employee: employee,
        attendanceRepository: repo,
      ),
    );
  }

  group('EmployeeAttendanceLogsScreen Tests', () {
    testWidgets('renders employee header card with name, role, department, and ID', (
      tester,
    ) async {
      final repo = MockEmployeeLogsRepository(logs: testLogs);

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Verify header card content
      expect(find.text('Sarah Jenkins'), findsNWidgets(2)); // in header card & in appbar subtitle
      expect(
        find.text('Senior Frontend Engineer • Engineering'),
        findsOneWidget,
      );
      expect(find.text('EMP-092'), findsOneWidget);
      expect(find.text('PT Oasish Group'), findsOneWidget);
      expect(find.text('Lihat Profil Pegawai'), findsOneWidget);

      // Verify month chips
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('Bulan Lalu'), findsOneWidget);

      // Verify logs rendered
      expect(find.byType(AttendanceLogCard), findsNWidgets(2));
      expect(find.text('Clock In'), findsOneWidget);
      expect(find.text('Clock Out'), findsOneWidget);
    });

    testWidgets('handles month chip toggle between current and last month', (
      tester,
    ) async {
      final repo = MockEmployeeLogsRepository(logs: testLogs);

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Tap 'Bulan Lalu'
      await tester.tap(find.text('Bulan Lalu'));
      await tester.pumpAndSettle();

      // Tap 'Bulan Ini'
      await tester.tap(find.text('Bulan Ini'));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins'), findsWidgets);
    });

    testWidgets('displays Pemberitahuan Jadwal and Kembali on 404 (e.g. periode payroll belum ada)', (
      tester,
    ) async {
      final repo = MockEmployeeLogsRepository(
        shouldThrow: true,
        throwStatusCode: 404,
        throwMessage: 'Belum ada periode payroll aktif untuk pegawai ini.',
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Error state for 404
      expect(find.text('Pemberitahuan Jadwal'), findsOneWidget);
      expect(
        find.text('Belum ada periode payroll aktif untuk pegawai ini.'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.calendarX), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('displays Tidak Ada Hak Akses and Kembali on 403 Forbidden error', (
      tester,
    ) async {
      final repo = MockEmployeeLogsRepository(
        shouldThrow: true,
        throwStatusCode: 403,
        throwMessage: 'Forbidden access',
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Error state for 403
      expect(find.text('Tidak Ada Hak Akses'), findsOneWidget);
      expect(find.text('Tidak ada hak akses'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('displays Gagal Memuat Data and Coba Lagi on 500 error', (
      tester,
    ) async {
      final repo = MockEmployeeLogsRepository(
        shouldThrow: true,
        throwStatusCode: 500,
        throwMessage: 'Terjadi kesalahan pada server.',
      );

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Error state for 500
      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      expect(find.text('Terjadi kesalahan pada server.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Kembali'), findsNothing);
    });

    testWidgets('displays empty state when logs list is empty', (tester) async {
      final repo = MockEmployeeLogsRepository(logs: const []);

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Riwayat Absensi'), findsOneWidget);
      expect(
        find.text('Riwayat clock-in & clock-out Sarah Jenkins akan tampil di sini.'),
        findsOneWidget,
      );
    });
  });
}
