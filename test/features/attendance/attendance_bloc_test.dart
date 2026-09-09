import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

class MockAttendanceRepository implements AttendanceRepository {
  AttendanceTodayData currentData;
  bool shouldThrow;

  MockAttendanceRepository({
    AttendanceTodayData? initialData,
    this.shouldThrow = false,
  }) : currentData = initialData ??
            AttendanceTodayData(
              serverTime: DateTime(2026, 8, 27, 8, 45, 20),
            );

  @override
  Future<AttendanceTodayData> getTodayAttendance() async {
    if (shouldThrow) throw Exception('API Network Error');
    return currentData;
  }

  @override
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async {
    if (shouldThrow) throw Exception('Clock In Error');
    currentData = currentData.copyWith(
      inTime: '08:45',
      userLatitude: latitude,
      userLongitude: longitude,
    );
    return currentData;
  }

  @override
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async {
    if (shouldThrow) throw Exception('Clock Out Error');
    currentData = currentData.copyWith(
      outTime: '18:00',
      userLatitude: latitude,
      userLongitude: longitude,
    );
    return currentData;
  }

  @override
  Future<AttendanceTodayData> toggleBreak() async {
    if (shouldThrow) throw Exception('Break Error');
    final nextBreakState = !currentData.isOnBreak;
    currentData = currentData.copyWith(
      isOnBreak: nextBreakState,
      breakOutTime: nextBreakState ? '12:30' : currentData.breakOutTime,
      breakInTime: !nextBreakState ? '13:30' : currentData.breakInTime,
    );
    return currentData;
  }

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    if (shouldThrow) throw Exception('Report Issue Error');
  }

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AttendanceBloc Tests', () {
    test('initial state is AttendanceInitial', () {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);
      expect(bloc.state, const AttendanceInitial());
      bloc.close();
    });

    test('AttendanceFetchRequested emits [AttendanceLoading, AttendanceLoaded]', () async {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      final states = <AttendanceState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], const AttendanceLoading());
      expect(states[1], isA<AttendanceLoaded>());

      final loaded = states[1] as AttendanceLoaded;
      expect(loaded.data.employeeName, 'Alex Rivera');
      expect(loaded.formattedClockTime, '08:45:20'); // No 'WIB' suffix per user requirement
      expect(loaded.isInsideGeofence, isTrue);

      await bloc.close();
    });

    test('AttendanceClockTicked updates currentClockTime correctly without WIB', () async {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(AttendanceClockTicked(DateTime(2026, 8, 27, 8, 45, 25)));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<AttendanceLoaded>());
      final loaded = bloc.state as AttendanceLoaded;
      expect(loaded.formattedClockTime, '08:45:25');

      await bloc.close();
    });

    test('AttendanceClockInSubmitted updates inTime and sets action message', () async {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const AttendanceClockInSubmitted(
          latitude: -6.2253,
          longitude: 106.8097,
          address: 'HQ Office — Main Lobby',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<AttendanceLoaded>());
      final loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.isClockedIn, isTrue);
      expect(loaded.data.inTime, '08:45');
      expect(loaded.actionMessage, 'Clock In berhasil dicatat!');

      await bloc.close();
    });

    test('AttendanceBreakToggled toggles break on and off', () async {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // Start break
      bloc.add(const AttendanceBreakToggled());
      await Future.delayed(const Duration(milliseconds: 50));

      var loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.isOnBreak, isTrue);
      expect(loaded.data.breakOutTime, '12:30');
      expect(loaded.actionMessage, 'Istirahat dimulai (Break Out)');

      // End break
      bloc.add(const AttendanceBreakToggled());
      await Future.delayed(const Duration(milliseconds: 50));

      loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.isOnBreak, isFalse);
      expect(loaded.data.breakInTime, '13:30');
      expect(loaded.actionMessage, 'Selesai istirahat (Break In)');

      await bloc.close();
    });

    test('AttendanceClockOutSubmitted updates outTime', () async {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const AttendanceClockOutSubmitted(
          latitude: -6.2253,
          longitude: 106.8097,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.isClockedOut, isTrue);
      expect(loaded.data.outTime, '18:00');
      expect(loaded.actionMessage, 'Clock Out berhasil dicatat!');

      await bloc.close();
    });

    test('AttendanceReportIssueSubmitted emits confirmation message', () async {
      final repo = MockAttendanceRepository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const AttendanceReportIssueSubmitted(
          issueDescription: 'GPS jumping due to indoor structure',
          latitude: -6.2253,
          longitude: 106.8097,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = bloc.state as AttendanceLoaded;
      expect(loaded.actionMessage, 'Laporan kendala lokasi berhasil dikirim');

      await bloc.close();
    });

    test('AttendanceFailure emitted when repository throws error', () async {
      final repo = MockAttendanceRepository(shouldThrow: true);
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<AttendanceFailure>());
      final failure = bloc.state as AttendanceFailure;
      expect(failure.message, contains('API Network Error'));

      await bloc.close();
    });

    test('AttendanceFailure emitted with statusCode 404 and isNotFound true when 404 occurs', () async {
      final repo = MockAttendance404Repository();
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<AttendanceFailure>());
      final failure = bloc.state as AttendanceFailure;
      expect(failure.statusCode, 404);
      expect(failure.isNotFound, isTrue);
      expect(failure.message, 'You do not have an active schedule assignment right now');

      await bloc.close();
    });
  });
}

class MockAttendance404Repository extends MockAttendanceRepository {
  @override
  Future<AttendanceTodayData> getTodayAttendance() async {
    throw const ApiException(
      message: 'You do not have an active schedule assignment right now',
      statusCode: 404,
    );
  }
}
