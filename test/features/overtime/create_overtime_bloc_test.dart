import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/create_overtime/create_overtime_bloc.dart';

class _MockOvertimeRepository implements OvertimeRepository {
  final Future<OvertimeScheduleData> Function({
    required String dateTimeStart,
  })? onGetOvertimeSchedule;

  final Future<CreateOvertimeResultModel> Function({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  })? onCreateOvertimeRequest;

  _MockOvertimeRepository({
    this.onGetOvertimeSchedule,
    this.onCreateOvertimeRequest,
  });

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    String? statusApprove,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) async {
    if (onGetOvertimeSchedule != null) {
      return onGetOvertimeSchedule!(dateTimeStart: dateTimeStart);
    }
    return const OvertimeScheduleData(
      isGenerated: false,
      isDayOff: true,
      requiresCheckOut: false,
    );
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) async {
    if (onCreateOvertimeRequest != null) {
      return onCreateOvertimeRequest!(
        startOvertime: startOvertime,
        endOvertime: endOvertime,
        notes: notes,
        workScheduleId: workScheduleId,
        file: file,
      );
    }
    return const CreateOvertimeResultModel(
      success: true,
      message: 'OK',
      id: 'ot-created-123',
    );
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOvertime(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  group('CreateOvertimeBloc Tests', () {
    final baseDate = DateTime(2026, 8, 28, 6, 0); // 06:00 pagi

    test('Lembur Sebelum Shift (Pre-Shift): mendeteksi start < shiftStart', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeSchedule: ({required String dateTimeStart}) async {
          return const OvertimeScheduleData(
            isGenerated: true,
            isDayOff: false,
            requiresCheckOut: true,
            workScheduleId: 'ws-1',
            schedule: OvertimeScheduleInfoModel(
              id: 'ws-1',
              isDayOff: false,
              shift: OvertimeShiftModel(
                id: 'shift-1',
                startTime: '08:00:00',
                endTime: '17:00:00',
              ),
            ),
            attendance: OvertimeAttendanceInfoModel(
              id: 'att-1',
              checkIn: '05:50:00',
              checkOut: null,
            ),
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      bloc.add(CreateOvertimeStarted(initialStartTime: baseDate));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.initial),
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.loadingSchedule),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.scheduleLoaded);
            expect(s.category, OvertimeTypeCategory.preShift);
            expect(s.isCheckOutRequiredBlocked, isFalse);
            expect(s.isEndTimeLocked, isFalse);
            expect(s.endOvertime?.hour, 8);
            expect(s.duration.inHours, 2);
            return true;
          }),
        ]),
      );

      await bloc.close();
    });

    test('Lembur Setelah Shift belum check-out: isCheckOutRequiredBlocked = true', () async {
      final postShiftStart = DateTime(2026, 8, 28, 17, 30); // 17:30
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeSchedule: ({required String dateTimeStart}) async {
          return const OvertimeScheduleData(
            isGenerated: true,
            isDayOff: false,
            requiresCheckOut: true,
            workScheduleId: 'ws-1',
            schedule: OvertimeScheduleInfoModel(
              id: 'ws-1',
              isDayOff: false,
              shift: OvertimeShiftModel(
                id: 'shift-1',
                startTime: '08:00:00',
                endTime: '17:00:00',
              ),
            ),
            attendance: OvertimeAttendanceInfoModel(
              id: 'att-1',
              checkIn: '07:55:00',
              checkOut: null, // Belum check-out!
            ),
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      bloc.add(CreateOvertimeStarted(initialStartTime: postShiftStart));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.initial),
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.loadingSchedule),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.scheduleLoaded);
            expect(s.category, OvertimeTypeCategory.postShift);
            expect(s.isCheckOutRequiredBlocked, isTrue);
            expect(s.canSubmit, isFalse);
            return true;
          }),
        ]),
      );

      await bloc.close();
    });

    test('Lembur Setelah Shift sudah check-out: isEndTimeLocked = true dan terisi checkOut', () async {
      final postShiftStart = DateTime(2026, 8, 28, 17, 0);
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeSchedule: ({required String dateTimeStart}) async {
          return const OvertimeScheduleData(
            isGenerated: true,
            isDayOff: false,
            requiresCheckOut: true,
            workScheduleId: 'ws-1',
            schedule: OvertimeScheduleInfoModel(
              id: 'ws-1',
              isDayOff: false,
              shift: OvertimeShiftModel(
                id: 'shift-1',
                startTime: '08:00:00',
                endTime: '17:00:00',
              ),
            ),
            attendance: OvertimeAttendanceInfoModel(
              id: 'att-1',
              checkIn: '07:55:00',
              checkOut: '21:00:00', // Check-out 21:00
            ),
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      bloc.add(CreateOvertimeStarted(initialStartTime: postShiftStart));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.initial),
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.loadingSchedule),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.scheduleLoaded);
            expect(s.category, OvertimeTypeCategory.postShift);
            expect(s.isCheckOutRequiredBlocked, isFalse);
            expect(s.isEndTimeLocked, isTrue);
            expect(s.endOvertime?.hour, 21);
            expect(s.duration.inHours, 4);
            expect(s.durationLabel, '4 Jam (4.0 Hours)');
            expect(s.canSubmit, isTrue);
            return true;
          }),
        ]),
      );

      await bloc.close();
    });

    test('Lembur Setelah Shift: startOvertime otomatis default ke jam out shift (17:00) saat dibuka di tengah jam kerja', () async {
      final midDayTime = DateTime(2026, 8, 28, 12, 0); // Dibuka siang hari jam 12:00
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeSchedule: ({required String dateTimeStart}) async {
          return const OvertimeScheduleData(
            isGenerated: true,
            isDayOff: false,
            requiresCheckOut: true,
            workScheduleId: 'ws-1',
            schedule: OvertimeScheduleInfoModel(
              id: 'ws-1',
              isDayOff: false,
              shift: OvertimeShiftModel(
                id: 'shift-1',
                startTime: '08:00:00',
                endTime: '17:00:00', // Jam out shift
              ),
            ),
            attendance: OvertimeAttendanceInfoModel(
              id: 'att-1',
              checkIn: '07:55:00',
              checkOut: '20:00:00', // Jam out presensi (Check-out)
            ),
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      bloc.add(CreateOvertimeStarted(initialStartTime: midDayTime));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.initial),
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.loadingSchedule),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.scheduleLoaded);
            expect(s.category, OvertimeTypeCategory.postShift);
            // Default startOvertime harus jam out shift (17:00)
            expect(s.startOvertime?.hour, 17);
            expect(s.startOvertime?.minute, 0);
            // Default endOvertime harus jam out presensi (20:00)
            expect(s.endOvertime?.hour, 20);
            expect(s.endOvertime?.minute, 0);
            expect(s.duration.inHours, 3);
            expect(s.isEndTimeLocked, isTrue);
            expect(s.canSubmit, isTrue);
            return true;
          }),
        ]),
      );

      await bloc.close();
    });

    test('Hari Libur (Day Off): kategori dayOff dan manual end time', () async {
      final dayOffStart = DateTime(2026, 8, 30, 9, 0); // Minggu 09:00
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeSchedule: ({required String dateTimeStart}) async {
          return const OvertimeScheduleData(
            isGenerated: false,
            isDayOff: true,
            requiresCheckOut: false,
            workScheduleId: null,
            schedule: null,
            attendance: null,
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      bloc.add(CreateOvertimeStarted(initialStartTime: dayOffStart));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.initial),
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.loadingSchedule),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.scheduleLoaded);
            expect(s.category, OvertimeTypeCategory.dayOff);
            expect(s.isCheckOutRequiredBlocked, isFalse);
            expect(s.isEndTimeLocked, isFalse);
            return true;
          }),
        ]),
      );

      await bloc.close();
    });

    test('CreateOvertimeSubmitted memancarkan submitting lalu success', () async {
      final mockRepo = _MockOvertimeRepository(
        onCreateOvertimeRequest: ({
          required String startOvertime,
          required String endOvertime,
          required String notes,
          String? workScheduleId,
          required XFile file,
        }) async {
          return const CreateOvertimeResultModel(
            success: true,
            message: 'Berhasil',
            id: 'ot-created-999',
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      final dummyFile = XFile('test/dummy_overtime.jpg');

      bloc.add(CreateOvertimeSubmitted(
        startOvertime: DateTime(2026, 8, 28, 17, 0),
        endOvertime: DateTime(2026, 8, 28, 21, 0),
        notes: 'Pekerjaan migrasi server database',
        workScheduleId: 'ws-1',
        file: dummyFile,
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.submitting),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.success);
            expect(s.createdId, 'ot-created-999');
            expect(s.successMessage, 'Berhasil');
            return true;
          }),
        ]),
      );

      await bloc.close();
    });

    test('CreateOvertimeSubmitted memancarkan failure saat ApiException', () async {
      final mockRepo = _MockOvertimeRepository(
        onCreateOvertimeRequest: ({
          required String startOvertime,
          required String endOvertime,
          required String notes,
          String? workScheduleId,
          required XFile file,
        }) async {
          throw ApiException(
            message: 'File foto bukti wajib dilampirkan.',
            statusCode: 422,
          );
        },
      );

      final bloc = CreateOvertimeBloc(repository: mockRepo);
      final dummyFile = XFile('test/dummy_overtime.jpg');

      bloc.add(CreateOvertimeSubmitted(
        startOvertime: DateTime(2026, 8, 28, 17, 0),
        endOvertime: DateTime(2026, 8, 28, 21, 0),
        notes: 'Lembur',
        file: dummyFile,
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<CreateOvertimeState>((s) => s.status == CreateOvertimeStatus.submitting),
          predicate<CreateOvertimeState>((s) {
            expect(s.status, CreateOvertimeStatus.failure);
            expect(s.errorMessage, 'File foto bukti wajib dilampirkan.');
            expect(s.statusCode, 422);
            return true;
          }),
        ]),
      );

      await bloc.close();
    });
  });
}
