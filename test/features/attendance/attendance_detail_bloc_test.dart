import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_detail/attendance_detail_bloc.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

class MockAttendanceDetailRepository implements AttendanceRepository {
  AttendanceDetailModel? mockDetail;
  bool shouldThrow = false;
  int? throwStatusCode;
  String? throwMessage;

  MockAttendanceDetailRepository({
    this.mockDetail,
    this.shouldThrow = false,
    this.throwStatusCode,
    this.throwMessage,
  });

  @override
  Future<AttendanceDetailModel> getAttendanceDetail(String id) async {
    if (shouldThrow) {
      throw ApiException(
        message: throwMessage ?? 'Error fetching attendance detail',
        statusCode: throwStatusCode ?? 500,
      );
    }
    return mockDetail ??
        AttendanceDetailModel(
          id: id,
          attendanceType: 'Clock In',
          attendanceMethod: 'Face Recognition',
          workDate: '2026-09-09',
          lateInMinutes: 0,
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
  }) async =>
      throw UnimplementedError();

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async =>
      throw UnimplementedError();

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) async =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDetail = AttendanceDetailModel(
    id: 'att-123',
    attendanceType: 'Clock In',
    attendanceTime: DateTime(2026, 9, 9, 8, 30, 0),
    attendanceMethod: 'Photo Verification',
    filePath: 'https://example.com/photo.jpg',
    attendanceRequestId: 'REQ-001',
    lateInMinutes: 10,
    workDate: '2026-09-09',
    timezone: 'WIB',
    employee: const AttendanceEmployeeInfo(
      id: 'emp-1',
      firstName: 'Jane',
      lastName: 'Doe',
      position: 'Staff',
      department: 'HR',
      company: 'Oasish Corp',
    ),
  );

  group('AttendanceDetailBloc', () {
    test('initial state has initial status', () {
      final bloc = AttendanceDetailBloc(
        repository: MockAttendanceDetailRepository(),
      );
      expect(bloc.state.status, AttendanceDetailStatus.initial);
      expect(bloc.state.detail, isNull);
      bloc.close();
    });

    test('emits [loading, success] when AttendanceDetailStarted succeeds', () async {
      final bloc = AttendanceDetailBloc(
        repository: MockAttendanceDetailRepository(mockDetail: testDetail),
      );

      final expected = expectLater(
        bloc.stream,
        emitsInOrder([
          const AttendanceDetailState(status: AttendanceDetailStatus.loading),
          AttendanceDetailState(
            status: AttendanceDetailStatus.success,
            detail: testDetail,
          ),
        ]),
      );

      bloc.add(const AttendanceDetailStarted('att-123'));
      await expected;
      bloc.close();
    });

    test('emits [loading, failure] with isNotFound true when 404 is thrown', () async {
      final bloc = AttendanceDetailBloc(
        repository: MockAttendanceDetailRepository(
          shouldThrow: true,
          throwStatusCode: 404,
          throwMessage: 'Data absensi tidak ditemukan',
        ),
      );

      final expected = expectLater(
        bloc.stream,
        emitsInOrder([
          const AttendanceDetailState(status: AttendanceDetailStatus.loading),
          const AttendanceDetailState(
            status: AttendanceDetailStatus.failure,
            errorMessage: 'Data absensi tidak ditemukan',
            statusCode: 404,
          ),
        ]),
      );

      bloc.add(const AttendanceDetailStarted('att-unknown'));
      await expected;

      expect(bloc.state.isNotFound, isTrue);
      expect(bloc.state.isForbidden, isFalse);
      bloc.close();
    });

    test('emits [loading, failure] with isForbidden true when 403 is thrown', () async {
      final bloc = AttendanceDetailBloc(
        repository: MockAttendanceDetailRepository(
          shouldThrow: true,
          throwStatusCode: 403,
          throwMessage: 'Tidak ada hak akses',
        ),
      );

      final expected = expectLater(
        bloc.stream,
        emitsInOrder([
          const AttendanceDetailState(status: AttendanceDetailStatus.loading),
          const AttendanceDetailState(
            status: AttendanceDetailStatus.failure,
            errorMessage: 'Tidak ada hak akses',
            statusCode: 403,
          ),
        ]),
      );

      bloc.add(const AttendanceDetailStarted('att-403'));
      await expected;

      expect(bloc.state.isForbidden, isTrue);
      expect(bloc.state.isNotFound, isFalse);
      bloc.close();
    });

    test('emits [loading, success] when AttendanceDetailRefreshed succeeds', () async {
      final bloc = AttendanceDetailBloc(
        repository: MockAttendanceDetailRepository(mockDetail: testDetail),
      );

      final expected = expectLater(
        bloc.stream,
        emitsInOrder([
          const AttendanceDetailState(status: AttendanceDetailStatus.loading),
          AttendanceDetailState(
            status: AttendanceDetailStatus.success,
            detail: testDetail,
          ),
        ]),
      );

      bloc.add(const AttendanceDetailRefreshed('att-123'));
      await expected;
      bloc.close();
    });
  });
}
