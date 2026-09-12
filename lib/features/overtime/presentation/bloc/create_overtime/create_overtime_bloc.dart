import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/create_overtime/create_overtime_event.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/create_overtime/create_overtime_state.dart';

export 'create_overtime_event.dart';
export 'create_overtime_state.dart';

class CreateOvertimeBloc
    extends Bloc<CreateOvertimeEvent, CreateOvertimeState> {
  final OvertimeRepository _repository;

  CreateOvertimeBloc({OvertimeRepository? repository})
      : _repository = repository ?? OvertimeRepositoryImpl(),
        super(const CreateOvertimeState()) {
    on<CreateOvertimeStarted>(_onStarted);
    on<CreateOvertimeStartChanged>(_onStartChanged);
    on<CreateOvertimeFetchSchedule>(_onFetchSchedule);
    on<CreateOvertimeEndChanged>(_onEndChanged);
    on<CreateOvertimeSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateOvertimeStarted event,
    Emitter<CreateOvertimeState> emit,
  ) async {
    final start = event.initialStartTime ?? DateTime.now();
    final defaultEnd = start.add(const Duration(hours: 2));
    emit(state.copyWith(
      status: CreateOvertimeStatus.initial,
      startOvertime: start,
      endOvertime: defaultEnd,
    ));

    await _fetchScheduleForDate(
      start,
      emit,
      isInitialOrDateChange: true,
    );
  }

  Future<void> _onStartChanged(
    CreateOvertimeStartChanged event,
    Emitter<CreateOvertimeState> emit,
  ) async {
    final start = event.startOvertime;
    final isDateDifferent = state.startOvertime == null ||
        state.startOvertime!.year != start.year ||
        state.startOvertime!.month != start.month ||
        state.startOvertime!.day != start.day;

    emit(state.copyWith(
      startOvertime: start,
    ));
    await _fetchScheduleForDate(
      start,
      emit,
      isInitialOrDateChange: isDateDifferent || !event.isUserExplicitTime,
    );
  }

  Future<void> _onFetchSchedule(
    CreateOvertimeFetchSchedule event,
    Emitter<CreateOvertimeState> emit,
  ) async {
    await _fetchScheduleForDate(
      event.dateTimeStart,
      emit,
      isInitialOrDateChange: true,
    );
  }

  void _onEndChanged(
    CreateOvertimeEndChanged event,
    Emitter<CreateOvertimeState> emit,
  ) {
    if (state.isEndTimeLocked) return;
    emit(state.copyWith(endOvertime: event.endOvertime));
  }

  Future<void> _fetchScheduleForDate(
    DateTime start,
    Emitter<CreateOvertimeState> emit, {
    bool isInitialOrDateChange = false,
  }) async {
    emit(state.copyWith(status: CreateOvertimeStatus.loadingSchedule));
    try {
      final rfc3339 = start.toUtc().toIso8601String();
      final scheduleData = await _repository.getOvertimeSchedule(
        dateTimeStart: rfc3339,
      );

      final shiftStart = scheduleData.parsedShiftStartTime(start);
      final shiftEnd = scheduleData.parsedShiftEndTime(start);
      final checkOut = scheduleData.parsedCheckOutDateTime(start);

      OvertimeTypeCategory category;
      bool isEndTimeLocked = false;
      bool isCheckOutRequiredBlocked = false;
      DateTime effectiveStart = start;
      DateTime endOvertime;

      if (!scheduleData.hasSchedule || scheduleData.isDayOff) {
        // 1. Kasus Hari Libur (Day Off)
        category = OvertimeTypeCategory.dayOff;
        isEndTimeLocked = false;
        isCheckOutRequiredBlocked = false;
        effectiveStart = start;
        endOvertime = state.endOvertime ?? start.add(const Duration(hours: 2));
        if (!endOvertime.isAfter(effectiveStart)) {
          endOvertime = effectiveStart.add(const Duration(hours: 2));
        }
      } else if (shiftStart != null && start.isBefore(shiftStart)) {
        // 2. Kasus Lembur Sebelum Shift (Pre-Shift)
        category = OvertimeTypeCategory.preShift;
        isEndTimeLocked = false;
        isCheckOutRequiredBlocked = false;
        effectiveStart = start;
        endOvertime = shiftStart;
      } else {
        // 3. Kasus Lembur Setelah Shift (Post-Shift)
        category = OvertimeTypeCategory.postShift;

        // Jika jadwal kerja memiliki jam selesai (shiftEnd / "jam out"),
        // default waktu mulai lembur setelah jam kerja diarahkan ke jam out shift.
        if (shiftEnd != null) {
          if (isInitialOrDateChange ||
              start.isBefore(shiftEnd) ||
              (checkOut != null && start.isAfter(checkOut))) {
            effectiveStart = shiftEnd;
          } else {
            effectiveStart = start;
          }
        } else {
          effectiveStart = start;
        }

        if (checkOut == null) {
          isCheckOutRequiredBlocked = true;
          isEndTimeLocked = false;
          endOvertime = effectiveStart.add(const Duration(hours: 2));
        } else {
          isCheckOutRequiredBlocked = false;
          isEndTimeLocked = true;
          endOvertime = checkOut;
        }
      }

      emit(state.copyWith(
        status: CreateOvertimeStatus.scheduleLoaded,
        startOvertime: effectiveStart,
        endOvertime: endOvertime,
        category: category,
        isEndTimeLocked: isEndTimeLocked,
        isCheckOutRequiredBlocked: isCheckOutRequiredBlocked,
        scheduleData: scheduleData,
        errorMessage: '',
        statusCode: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateOvertimeStatus.scheduleLoaded,
        startOvertime: start,
        category: OvertimeTypeCategory.dayOff,
        isEndTimeLocked: false,
        isCheckOutRequiredBlocked: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateOvertimeStatus.scheduleLoaded,
        startOvertime: start,
        category: OvertimeTypeCategory.dayOff,
        isEndTimeLocked: false,
        isCheckOutRequiredBlocked: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitted(
    CreateOvertimeSubmitted event,
    Emitter<CreateOvertimeState> emit,
  ) async {
    emit(state.copyWith(status: CreateOvertimeStatus.submitting));
    try {
      final startRfc = event.startOvertime.toUtc().toIso8601String();
      final endRfc = event.endOvertime.toUtc().toIso8601String();

      final result = await _repository.createOvertimeRequest(
        startOvertime: startRfc,
        endOvertime: endRfc,
        notes: event.notes,
        workScheduleId: event.workScheduleId,
        file: event.file,
      );

      emit(state.copyWith(
        status: CreateOvertimeStatus.success,
        createdId: result.id,
        successMessage: result.message.isNotEmpty
            ? result.message
            : 'Pengajuan lembur berhasil dikirim!',
        errorMessage: '',
        statusCode: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateOvertimeStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateOvertimeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
