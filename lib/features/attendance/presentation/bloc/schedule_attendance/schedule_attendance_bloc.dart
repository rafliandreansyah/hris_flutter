import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_state.dart';

class ScheduleAttendanceBloc
    extends Bloc<ScheduleAttendanceEvent, ScheduleAttendanceState> {
  final AttendanceRequestRepository repository;
  final AttendanceRepository? attendanceRepository;

  ScheduleAttendanceBloc({
    required this.repository,
    this.attendanceRepository,
    DateTime? initialDate,
  }) : super(ScheduleAttendanceState(
          selectedDate: initialDate ?? DateTime.now(),
        )) {
    on<ScheduleAttendanceStarted>(_onStarted);
    on<ScheduleAttendanceMethodChanged>(_onMethodChanged);
    on<ScheduleAttendanceTypeChanged>(_onTypeChanged);
    on<ScheduleAttendanceDateChanged>(_onDateChanged);
    on<ScheduleAttendanceInTimeChanged>(_onInTimeChanged);
    on<ScheduleAttendanceOutTimeChanged>(_onOutTimeChanged);
    on<ScheduleAttendanceInLocationChanged>(_onInLocationChanged);
    on<ScheduleAttendanceOutLocationChanged>(_onOutLocationChanged);
    on<ScheduleAttendanceSameLocationToggled>(_onSameLocationToggled);
    on<ScheduleAttendanceInPhotoChanged>(_onInPhotoChanged);
    on<ScheduleAttendanceOutPhotoChanged>(_onOutPhotoChanged);
    on<ScheduleAttendanceReasonChanged>(_onReasonChanged);
    on<ScheduleAttendanceSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    ScheduleAttendanceStarted event,
    Emitter<ScheduleAttendanceState> emit,
  ) async {
    String method = event.initialMethod ?? state.attendanceMethod;

    if (event.initialMethod == null && attendanceRepository != null) {
      try {
        final attData = await attendanceRepository!.getTodayAttendance();
        if (attData.hasAttendanceMethod) {
          method = attData.attendanceMethod;
        }
      } catch (_) {}
    }

    emit(state.copyWith(
      attendanceMethod: method,
      attendanceType: event.initialType ?? state.attendanceType,
    ));
  }

  void _onMethodChanged(
    ScheduleAttendanceMethodChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      attendanceMethod: event.attendanceMethod,
      clearErrorMessage: true,
    ));
  }

  void _onTypeChanged(
    ScheduleAttendanceTypeChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      attendanceType: event.attendanceType,
      clearErrorMessage: true,
    ));
  }

  void _onDateChanged(
    ScheduleAttendanceDateChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      selectedDate: event.date,
      clearErrorMessage: true,
    ));
  }

  void _onInTimeChanged(
    ScheduleAttendanceInTimeChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      inTime: event.time,
      clearErrorMessage: true,
    ));
  }

  void _onOutTimeChanged(
    ScheduleAttendanceOutTimeChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      outTime: event.time,
      clearErrorMessage: true,
    ));
  }

  void _onInLocationChanged(
    ScheduleAttendanceInLocationChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    if (state.isSameLocation) {
      emit(state.copyWith(
        inLatitude: event.latitude,
        longitudeIn: event.longitude,
        addressIn: event.address,
        latitudeOut: event.latitude,
        longitudeOut: event.longitude,
        addressOut: event.address,
        clearErrorMessage: true,
      ));
    } else {
      emit(state.copyWith(
        inLatitude: event.latitude,
        longitudeIn: event.longitude,
        addressIn: event.address,
        clearErrorMessage: true,
      ));
    }
  }

  void _onOutLocationChanged(
    ScheduleAttendanceOutLocationChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      latitudeOut: event.latitude,
      longitudeOut: event.longitude,
      addressOut: event.address,
      clearErrorMessage: true,
    ));
  }

  void _onSameLocationToggled(
    ScheduleAttendanceSameLocationToggled event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    if (event.isSame) {
      emit(state.copyWith(
        isSameLocation: true,
        latitudeOut: state.inLatitude,
        longitudeOut: state.longitudeIn,
        addressOut: state.addressIn,
        clearErrorMessage: true,
      ));
    } else {
      emit(state.copyWith(
        isSameLocation: false,
        clearErrorMessage: true,
      ));
    }
  }

  void _onInPhotoChanged(
    ScheduleAttendanceInPhotoChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      inPhoto: event.photo,
      clearInPhoto: event.photo == null,
      clearErrorMessage: true,
    ));
  }

  void _onOutPhotoChanged(
    ScheduleAttendanceOutPhotoChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      outPhoto: event.photo,
      clearOutPhoto: event.photo == null,
      clearErrorMessage: true,
    ));
  }

  void _onReasonChanged(
    ScheduleAttendanceReasonChanged event,
    Emitter<ScheduleAttendanceState> emit,
  ) {
    emit(state.copyWith(
      reason: event.reason,
      clearErrorMessage: true,
    ));
  }

  Future<void> _onSubmitted(
    ScheduleAttendanceSubmitted event,
    Emitter<ScheduleAttendanceState> emit,
  ) async {
    // 1. Validasi Alasan
    if (state.reason.trim().isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Alasan pengajuan presensi terjadwal wajib diisi.',
      ));
      return;
    }

    // 2. Validasi Lokasi & Foto Masuk (jika type 'in' atau 'inout')
    if (state.hasIn) {
      if (!state.hasValidInLocation) {
        emit(state.copyWith(
          errorMessage: 'Lokasi absen masuk wajib dipilih.',
        ));
        return;
      }

      if (state.isPhotoMethod && state.inPhoto == null) {
        emit(state.copyWith(
          errorMessage:
              'Foto selfie absen masuk wajib diambil menggunakan kamera.',
        ));
        return;
      }
    }

    // 3. Validasi Lokasi & Foto Pulang (jika type 'out' atau 'inout')
    if (state.hasOut) {
      if (!state.hasValidOutLocation) {
        emit(state.copyWith(
          errorMessage: 'Lokasi absen pulang wajib dipilih.',
        ));
        return;
      }

      if (state.isPhotoMethod && state.outPhoto == null) {
        emit(state.copyWith(
          errorMessage:
              'Foto selfie absen pulang wajib diambil menggunakan kamera.',
        ));
        return;
      }
    }

    emit(state.copyWith(
      isSubmitting: true,
      submissionSuccess: false,
      clearErrorMessage: true,
    ));

    try {
      final request = ScheduleAttendanceRequest(
        attendanceMethod: state.attendanceMethod,
        attendanceType: state.attendanceType,
        reason: state.reason.trim(),
        attendanceInTime: state.hasIn ? state.formattedInDateTime : null,
        latitudeIn: state.hasIn ? state.inLatitude : null,
        longitudeIn: state.hasIn ? state.longitudeIn : null,
        addressIn: state.hasIn ? state.addressIn : null,
        fileIn: state.hasIn ? state.inPhoto : null,
        attendanceOutTime: state.hasOut ? state.formattedOutDateTime : null,
        latitudeOut: state.hasOut ? state.latitudeOut : null,
        longitudeOut: state.hasOut ? state.longitudeOut : null,
        addressOut: state.hasOut ? state.addressOut : null,
        fileOut: state.hasOut ? state.outPhoto : null,
      );

      final response = await repository.submitScheduleAttendance(request);

      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: true,
        successMessage: response.message.isNotEmpty
            ? response.message
            : 'Pengajuan presensi terjadwal berhasil dikirim.',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
        errorCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
