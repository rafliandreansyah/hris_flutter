import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_request_detail_screen.dart';

class _FakeAttendanceRequestDetailRepo implements AttendanceRequestRepository {
  final bool shouldThrow404;
  final bool shouldThrow500;
  bool approvedCalled = false;
  bool rejectedCalled = false;
  bool deleteCalled = false;

  _FakeAttendanceRequestDetailRepo({
    this.shouldThrow404 = false,
    this.shouldThrow500 = false,
  });

  @override
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(String id) async {
    if (shouldThrow404) {
      throw const ApiException(
        message: 'Permohonan presensi tidak ditemukan',
        statusCode: 404,
      );
    }
    if (shouldThrow500) {
      throw const ApiException(
        message: 'Koneksi database bermasalah',
        statusCode: 500,
      );
    }

    return AttendanceRequestDetailData(
      id: id,
      status: 'requested',
      method: 'photo',
      reason: 'Kunjungan kerja ke klien di Sudirman',
      attendanceType: 'in',
      attendanceTime: DateTime(2026, 3, 10, 8, 30),
      attendanceInTime: DateTime(2026, 3, 10, 8, 30),
      latitude: -6.2088,
      longitude: 106.8456,
      address: 'Jl. Jenderal Sudirman No. 45, Jakarta Pusat',
      timezone: 'Asia/Jakarta',
      employee: const AttendanceRequestEmployeeModel(
        id: 'emp-101',
        firstName: 'Budi',
        lastName: 'Santoso',
        employeeNumber: 'EMP-001',
        position: AttendanceRequestPositionModel(id: 'pos-1', name: 'Field Engineer'),
        department: AttendanceRequestDepartmentModel(id: 'dep-1', name: 'Operations'),
        company: AttendanceRequestCompanyModel(id: 'comp-1', name: 'PT Muratech ID'),
      ),
    );
  }

  @override
  Future<void> approveAttendanceRequest({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    if (isApproved) {
      approvedCalled = true;
    } else {
      rejectedCalled = true;
    }
  }

  @override
  Future<void> deleteAttendanceRequest(String id) async {
    deleteCalled = true;
  }

  @override
  Future<AttendanceRequestListResponse> getAttendanceRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) => throw UnimplementedError();

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(LiveAttendanceRequest request) =>
      throw UnimplementedError();

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) => throw UnimplementedError();
}

void main() {
  Widget buildTestableWidget({
    required String id,
    required AttendanceRequestRepository repository,
    bool isApprover = false,
  }) {
    return MaterialApp(
      home: AttendanceRequestDetailScreen(
        id: id,
        repository: repository,
        isApprover: isApprover,
      ),
    );
  }

  group('AttendanceRequestDetailScreen Widget Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SecureStorageService.instance.setPermissionsInMemory([]);
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('renders all cards, title, and employee info on success', (tester) async {
      final repo = _FakeAttendanceRequestDetailRepo();

      await tester.pumpWidget(
        buildTestableWidget(id: 'req-101', repository: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Presensi Luar'), findsOneWidget);
      expect(find.text('INFORMASI PENGAJU'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.textContaining('Field Engineer'), findsOneWidget);
      expect(find.text('Jl. Jenderal Sudirman No. 45, Jakarta Pusat'), findsOneWidget);
      expect(find.text('Kunjungan kerja ke klien di Sudirman'), findsOneWidget);
    });

    testWidgets('renders approver bottom action buttons when isApprover is true and has permission', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([AppPermissions.approvalAttendanceAction]);
      final repo = _FakeAttendanceRequestDetailRepo();

      await tester.pumpWidget(
        buildTestableWidget(id: 'req-101', repository: repo, isApprover: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tolak'), findsOneWidget);
      expect(find.text('Setujui Presensi'), findsOneWidget);
    });

    testWidgets('renders 404 Not Found error state with Kembali button', (tester) async {
      final repo = _FakeAttendanceRequestDetailRepo(shouldThrow404: true);

      await tester.pumpWidget(
        buildTestableWidget(id: 'req-404', repository: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permohonan Presensi Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('renders 500 server error state with Coba Lagi button', (tester) async {
      final repo = _FakeAttendanceRequestDetailRepo(shouldThrow500: true);

      await tester.pumpWidget(
        buildTestableWidget(id: 'req-500', repository: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Detail'), findsOneWidget);
      expect(find.text('Koneksi database bermasalah'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}
