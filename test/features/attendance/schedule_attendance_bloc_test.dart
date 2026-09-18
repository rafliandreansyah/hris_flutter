import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_state.dart';
import 'package:image_picker/image_picker.dart';

class _MockAttendanceRequestRepo extends Fake implements AttendanceRequestRepository {
  ScheduleAttendanceRequest? lastSubmittedRequest;
  bool shouldThrow = false;
  String errorMessage = 'Gagal mengirim pengajuan jadwal';

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
  }) async {
    return const AttendanceRequestListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: AttendanceRequestPaginationMeta(
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  ) async {
    return const LiveAttendanceResponse(
      success: true,
      message: 'OK',
      data: LiveAttendanceData(id: 'dummy'),
    );
  }

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) async {
    lastSubmittedRequest = request;
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 400);
    }
    return const ScheduleAttendanceResponse(
      success: true,
      message: 'Pengajuan presensi terjadwal berhasil diajukan.',
      data: ScheduleAttendanceData(id: 'sched-123', attendanceType: 'inout'),
    );
  }
}

void main() {
  final fixedDate = DateTime(2026, 9, 17);

  group('ScheduleAttendanceBloc Unit Tests', () {
    late _MockAttendanceRequestRepo mockRepo;

    setUp(() {
      mockRepo = _MockAttendanceRequestRepo();
    });

    test('state awal terinisialisasi dengan konfigurasi default yang benar', () {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      expect(bloc.state.attendanceMethod, 'photo');
      expect(bloc.state.attendanceType, 'inout');
      expect(bloc.state.isPhotoMethod, isTrue);
      expect(bloc.state.isBiometricMethod, isFalse);
      expect(bloc.state.hasIn, isTrue);
      expect(bloc.state.hasOut, isTrue);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.submissionSuccess, isFalse);
      expect(bloc.state.sameLocation, isTrue);
      expect(bloc.state.isSameLocation, isTrue);
      expect(bloc.state.inTime, const TimeOfDay(hour: 8, minute: 30));
      expect(bloc.state.outTime, const TimeOfDay(hour: 17, minute: 0));

      bloc.close();
    });

    test('ScheduleAttendanceStarted menginisialisasi initialMethod dan initialType', () async {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<ScheduleAttendanceState>((s) =>
              s.attendanceMethod == 'biometric' &&
              s.attendanceType == 'in' &&
              s.isBiometricMethod &&
              s.hasIn &&
              !s.hasOut),
        ),
      );

      bloc.add(const ScheduleAttendanceStarted(
        initialMethod: 'biometric',
        initialType: 'in',
      ));

      await expectation;
      bloc.close();
    });

    test('ScheduleAttendanceTypeChanged mengubah attendanceType (in, out, inout)', () async {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ScheduleAttendanceState>((s) => s.attendanceType == 'in' && s.hasIn && !s.hasOut),
          predicate<ScheduleAttendanceState>((s) => s.attendanceType == 'out' && !s.hasIn && s.hasOut),
          predicate<ScheduleAttendanceState>((s) => s.attendanceType == 'inout' && s.hasIn && s.hasOut),
        ]),
      );

      bloc.add(const ScheduleAttendanceTypeChanged('in'));
      bloc.add(const ScheduleAttendanceTypeChanged('out'));
      bloc.add(const ScheduleAttendanceTypeChanged('inout'));

      await expectation;
      bloc.close();
    });

    test('ScheduleAttendanceMethodChanged mengubah mode antara photo dan biometric', () async {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ScheduleAttendanceState>((s) => s.attendanceMethod == 'biometric' && s.isBiometricMethod),
          predicate<ScheduleAttendanceState>((s) => s.attendanceMethod == 'photo' && s.isPhotoMethod),
        ]),
      );

      bloc.add(const ScheduleAttendanceMethodChanged('biometric'));
      bloc.add(const ScheduleAttendanceMethodChanged('photo'));

      await expectation;
      bloc.close();
    });

    test('ScheduleAttendanceInLocationChanged mengupdate inLocation dan outLocation jika sameLocation aktif', () async {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ScheduleAttendanceState>((s) =>
              s.latitudeIn == -6.200000 &&
              s.longitudeIn == 106.816666 &&
              s.addressIn == 'Kantor Pusat' &&
              s.latitudeOut == -6.200000 &&
              s.longitudeOut == 106.816666 &&
              s.addressOut == 'Kantor Pusat'),
        ]),
      );

      bloc.add(const ScheduleAttendanceInLocationChanged(
        latitude: -6.200000,
        longitude: 106.816666,
        address: 'Kantor Pusat',
      ));

      await expectation;
      bloc.close();
    });

    test('ScheduleAttendanceSameLocationToggled menyalin inLocation ke outLocation saat diaktifkan', () async {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ScheduleAttendanceState>((s) => s.sameLocation == false),
          predicate<ScheduleAttendanceState>((s) =>
              s.latitudeIn == -6.123 &&
              s.longitudeIn == 106.456 &&
              s.addressIn == 'Gudang Logistik'),
          predicate<ScheduleAttendanceState>((s) =>
              s.sameLocation == true &&
              s.latitudeOut == -6.123 &&
              s.longitudeOut == 106.456 &&
              s.addressOut == 'Gudang Logistik'),
        ]),
      );

      bloc.add(const ScheduleAttendanceSameLocationToggled(false));
      bloc.add(const ScheduleAttendanceInLocationChanged(
        latitude: -6.123,
        longitude: 106.456,
        address: 'Gudang Logistik',
      ));
      bloc.add(const ScheduleAttendanceSameLocationToggled(true));

      await expectation;
      bloc.close();
    });

    test('ScheduleAttendanceSubmitted berhasil mengirim data type "inout" mode photo dengan 2 file', () async {
      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      final dummyPhotoIn = XFile('path/to/in.jpg');
      final dummyPhotoOut = XFile('path/to/out.jpg');

      bloc.add(const ScheduleAttendanceReasonChanged('Penugasan audit lapangan'));
      bloc.add(const ScheduleAttendanceInLocationChanged(
        latitude: -6.2,
        longitude: 106.8,
        address: 'Lokasi In',
      ));
      bloc.add(const ScheduleAttendanceOutLocationChanged(
        latitude: -6.3,
        longitude: 106.9,
        address: 'Lokasi Out',
      ));
      bloc.add(ScheduleAttendanceInPhotoChanged(dummyPhotoIn));
      bloc.add(ScheduleAttendanceOutPhotoChanged(dummyPhotoOut));

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ScheduleAttendanceState>((s) =>
              s.isSubmitting == false &&
              s.submissionSuccess == true &&
              s.successMessage == 'Pengajuan presensi terjadwal berhasil diajukan.'),
        ),
      );

      bloc.add(const ScheduleAttendanceSubmitted());

      await expectation;

      expect(mockRepo.lastSubmittedRequest, isNotNull);
      expect(mockRepo.lastSubmittedRequest!.attendanceMethod, 'photo');
      expect(mockRepo.lastSubmittedRequest!.attendanceType, 'inout');
      expect(mockRepo.lastSubmittedRequest!.reason, 'Penugasan audit lapangan');
      expect(mockRepo.lastSubmittedRequest!.fileIn?.path, 'path/to/in.jpg');
      expect(mockRepo.lastSubmittedRequest!.fileOut?.path, 'path/to/out.jpg');

      bloc.close();
    });

    test('ScheduleAttendanceSubmitted memancarkan error state jika repository melemparkan ApiException', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Jadwal presensi sudah ada pada tanggal tersebut.';

      final bloc = ScheduleAttendanceBloc(
        repository: mockRepo,
        initialDate: fixedDate,
      );

      bloc.add(const ScheduleAttendanceTypeChanged('in'));
      bloc.add(const ScheduleAttendanceMethodChanged('biometric'));
      bloc.add(const ScheduleAttendanceReasonChanged('Dinas luar'));
      bloc.add(const ScheduleAttendanceInLocationChanged(
        latitude: -6.2,
        longitude: 106.8,
        address: 'Kantor',
      ));

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ScheduleAttendanceState>((s) =>
              s.isSubmitting == false &&
              s.submissionSuccess == false &&
              s.errorMessage == 'Jadwal presensi sudah ada pada tanggal tersebut.' &&
              s.errorCode == 400),
        ),
      );

      bloc.add(const ScheduleAttendanceSubmitted());

      await expectation;
      bloc.close();
    });
  });
}
