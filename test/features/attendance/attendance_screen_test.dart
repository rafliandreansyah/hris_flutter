import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TestAttendanceRepository implements AttendanceRepository {
  AttendanceTodayData data;

  TestAttendanceRepository({AttendanceTodayData? initialData})
      : data = initialData ??
            AttendanceTodayData(
              serverTime: DateTime(2026, 8, 27, 8, 45, 20),
              availableWorkLocations: const [
                WorkLocationItem(
                  id: 'default-office',
                  name: 'Jakarta HQ Office',
                  address: 'HQ Office — Main Lobby',
                  radius: 50.0,
                  latitude: -6.2253,
                  longitude: 106.8097,
                  isDefault: true,
                ),
              ],
              selectedWorkLocation: const WorkLocationItem(
                id: 'default-office',
                name: 'Jakarta HQ Office',
                address: 'HQ Office — Main Lobby',
                radius: 50.0,
                latitude: -6.2253,
                longitude: 106.8097,
                isDefault: true,
              ),
            );

  @override
  Future<AttendanceTodayData> getTodayAttendance() async => data;

  @override
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async {
    data = data.copyWith(inTime: '08:45');
    return data;
  }

  @override
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async {
    data = data.copyWith(outTime: '18:00');
    return data;
  }

  @override
  Future<AttendanceTodayData> toggleBreak() async {
    data = data.copyWith(
      isOnBreak: !data.isOnBreak,
      breakOutTime: !data.isOnBreak ? '12:00' : data.breakOutTime,
      breakInTime: data.isOnBreak ? '13:00' : data.breakInTime,
    );
    return data;
  }

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {}

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
    return const AttendanceLogListResponse(
      success: true,
      message: 'Success',
      data: [],
      meta: AttendanceLogPaginationMeta(
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async {
    return const [];
  }

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) async {
    return AttendanceLogSummary.empty;
  }

  @override
  Future<AttendanceDetailModel> getAttendanceDetail(String id) async {
    return AttendanceDetailModel(
      id: id,
      attendanceType: 'Clock In',
      attendanceMethod: 'Face Recognition',
    );
  }
}

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AttendanceScreen UI Tests (Google Stitch Specifications)', () {
    testWidgets('renders all Stitch elements correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = TestAttendanceRepository();

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header (SliverAppBar with Back & Update Lokasi icons only)
      expect(find.text('Attendance & Check-In'), findsOneWidget);
      expect(find.text('Oasish Global Tech • Design & Product'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.locateFixed), findsOneWidget);

      // 2. Geofence Map Card & Blue Current Location Dot
      expect(
        find.text('Mendeteksi lokasi...').evaluate().isNotEmpty ||
            find.text('Inside Geofence Radius').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('GPS Accuracy: ±5m'), findsOneWidget);
      expect(find.text('HQ Office'), findsOneWidget);

      // 3. Server Clock Card (Without WIB)
      expect(find.text('Asia/Jakarta'), findsOneWidget);
      expect(find.text('08:45:20'), findsOneWidget); // Without WIB per user instruction
      expect(find.textContaining('WIB'), findsNothing); // Ensure WIB is removed
      expect(find.text('Regular Shift (09:00 - 18:00)'), findsOneWidget);

      // 4. Employee Card
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Senior Product Designer • ID: 8829'), findsOneWidget);
      expect(find.text('Jakarta HQ Office'), findsOneWidget);
      expect(find.text('HQ Office — Main Lobby'), findsOneWidget);
      expect(find.text('Radius: 50m'), findsOneWidget);

      // 5. Timeline 3 Cards
      expect(find.text('Clock In'), findsOneWidget);
      expect(find.text('Break Session'), findsOneWidget);
      expect(find.text('Break Out'), findsOneWidget);
      expect(find.text('Break In'), findsOneWidget);
      expect(find.text('Clock Out'), findsOneWidget);
      expect(find.text('Not started'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // 6. Action Buttons (Break button is hidden before clock in per user requirement)
      expect(find.text('Clock In Now'), findsOneWidget);
      expect(find.text('Start Break'), findsNothing);
      expect(find.text('Report Location Issue'), findsOneWidget);
    });

    testWidgets('tapping Clock In Now triggers clock in', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = TestAttendanceRepository();

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure button is visible before tapping
      await tester.ensureVisible(find.text('Clock In Now'));
      await tester.pumpAndSettle();

      // Tap Clock In Now button
      await tester.tap(find.text('Clock In Now'));
      await tester.pumpAndSettle();

      // Status should now be Clock Out Now and recorded
      expect(find.text('Clock Out Now'), findsOneWidget);
      expect(find.text('Recorded'), findsOneWidget);
    });

    testWidgets('tapping Report Location Issue opens modal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = TestAttendanceRepository();

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Report Location Issue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report Location Issue'));
      await tester.pumpAndSettle();

      expect(find.text('Laporkan Kendala Lokasi'), findsOneWidget);
      expect(find.text('Kirim Laporan'), findsOneWidget);
    });

    testWidgets('tapping Update Lokasi icon in app bar triggers GPS update feedback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = TestAttendanceRepository();

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      await tester.pumpAndSettle();

      final updateLocationButton = find.byIcon(LucideIcons.locateFixed);
      expect(updateLocationButton, findsOneWidget);

      await tester.tap(updateLocationButton);
      await tester.pump(); // Start snackbar

      expect(find.textContaining('Memperbarui lokasi GPS'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('SliverAppBar hides on scroll down and reveals on scroll up', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = TestAttendanceRepository();

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      await tester.pumpAndSettle();

      // App bar is initially visible
      expect(find.text('Attendance & Check-In'), findsOneWidget);

      // Scroll down (drag up)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();

      // App bar has scrolled out of view
      expect(find.text('Attendance & Check-In'), findsNothing);

      // Scroll up (drag down) to snap app bar back into view
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
      await tester.pumpAndSettle();

      // App bar immediately snapped back into view!
      expect(find.text('Attendance & Check-In'), findsOneWidget);
    });

    testWidgets('displays API error message and Kembali button when 404 error occurs with English message', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = Test404AttendanceRepository(
        message: 'You do not have an active schedule assignment right now',
      );

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      // Pump to process async fetch and dialog
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies the message comes directly from the API
      expect(find.text('You do not have an active schedule assignment right now'), findsAtLeast(1));
      expect(find.text('Kembali'), findsAtLeast(1));
      expect(find.text('Coba Lagi'), findsNothing);

      // Dismiss dialog by tapping Kembali to clean up dialog animation timers
      await tester.tap(find.text('Kembali').last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('displays API error message and Kembali button when 404 error occurs with Indonesian message', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = Test404AttendanceRepository(
        message: 'Anda tidak memiliki penugasan jadwal yang aktif saat ini',
      );

      await tester.pumpWidget(
        createTestApp(
          AttendanceScreen(repository: repo, autoStartClock: false),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Verifies Indonesian API message and Kembali button
      expect(find.text('Anda tidak memiliki penugasan jadwal yang aktif saat ini'), findsAtLeast(1));
      expect(find.text('Kembali'), findsAtLeast(1));
      expect(find.text('Coba Lagi'), findsNothing);

      await tester.tap(find.text('Kembali').last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}

class Test404AttendanceRepository implements AttendanceRepository {
  final String message;

  Test404AttendanceRepository({
    this.message = 'You do not have an active schedule assignment right now',
  });

  @override
  Future<AttendanceTodayData> getTodayAttendance() async {
    throw ApiException(
      message: message,
      statusCode: 404,
    );
  }

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
  Future<AttendanceTodayData> toggleBreak() async => throw UnimplementedError();

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {}

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
  }) async => throw UnimplementedError();

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async =>
      throw UnimplementedError();

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) async =>
      throw UnimplementedError();

  @override
  Future<AttendanceDetailModel> getAttendanceDetail(String id) async =>
      throw UnimplementedError();
}
