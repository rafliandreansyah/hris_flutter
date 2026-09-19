import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/mapbox_geocoding_util.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_state.dart';

typedef SafeAddressFetcher = Future<String> Function({
  required double latitude,
  required double longitude,
});

class LiveAttendanceBloc
    extends Bloc<LiveAttendanceEvent, LiveAttendanceState> {
  final AttendanceRequestRepository repository;
  final AttendanceRepository? attendanceRepository;
  final SafeAddressFetcher _addressFetcher;
  Timer? _clockTimer;

  LiveAttendanceBloc({
    required this.repository,
    this.attendanceRepository,
    SafeAddressFetcher? addressFetcher,
    DateTime? initialTime,
    bool autoStartTimer = true,
  })  : _addressFetcher = addressFetcher ?? MapboxGeocodingUtil.getSafeAddress,
        super(LiveAttendanceState(
          currentClockTime: initialTime ?? DateTime.now(),
        )) {
    on<LiveAttendanceStarted>(_onStarted);
    on<LiveAttendanceClockTicked>(_onClockTicked);
    on<LiveAttendanceTypeChanged>(_onTypeChanged);
    on<LiveAttendanceLocationUpdated>(_onLocationUpdated);
    on<LiveAttendanceReasonChanged>(_onReasonChanged);
    on<LiveAttendancePhotoChanged>(_onPhotoChanged);
    on<LiveAttendanceSubmitted>(_onSubmitted);

    if (autoStartTimer) {
      _startClockTimer();
    }
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(LiveAttendanceClockTicked(
        state.currentClockTime.add(const Duration(seconds: 1)),
      ));
    });
  }

  @override
  Future<void> close() {
    _clockTimer?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    LiveAttendanceStarted event,
    Emitter<LiveAttendanceState> emit,
  ) async {
    String method = event.initialMethod ?? state.attendanceMethod;

    if (event.initialMethod == null && attendanceRepository != null) {
      try {
        final attData = await attendanceRepository!.getTodayAttendance();
        if (attData.hasAttendanceMethod) {
          method = attData.attendanceMethod;
        }
      } catch (_) {
        // Gunakan default method
      }
    }

    emit(state.copyWith(
      attendanceMethod: method,
      currentClockTime: DateTime.now(),
    ));
  }

  void _onClockTicked(
    LiveAttendanceClockTicked event,
    Emitter<LiveAttendanceState> emit,
  ) {
    if (state.submissionSuccess) return;
    emit(state.copyWith(currentClockTime: event.time));
  }

  void _onTypeChanged(
    LiveAttendanceTypeChanged event,
    Emitter<LiveAttendanceState> emit,
  ) {
    emit(state.copyWith(attendanceType: event.attendanceType));
  }

  void _onLocationUpdated(
    LiveAttendanceLocationUpdated event,
    Emitter<LiveAttendanceState> emit,
  ) {
    emit(state.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
      gpsAccuracy: event.accuracy,
      isLocating: false,
    ));
  }

  void _onReasonChanged(
    LiveAttendanceReasonChanged event,
    Emitter<LiveAttendanceState> emit,
  ) {
    emit(state.copyWith(reason: event.reason));
  }

  void _onPhotoChanged(
    LiveAttendancePhotoChanged event,
    Emitter<LiveAttendanceState> emit,
  ) {
    emit(state.copyWith(photo: () => event.photo));
  }

  Future<void> _onSubmitted(
    LiveAttendanceSubmitted event,
    Emitter<LiveAttendanceState> emit,
  ) async {
    if (!state.hasValidCoordinates) {
      emit(state.copyWith(
        errorMessage: () =>
            'Koordinat GPS belum ditemukan. Harap tunggu atau perbarui GPS.',
      ));
      return;
    }

    if (state.reason.trim().isEmpty) {
      emit(state.copyWith(
        errorMessage: () => 'Alasan presensi luar kantor wajib diisi.',
      ));
      return;
    }

    if (state.isPhotoMethod && state.photo == null) {
      emit(state.copyWith(
        errorMessage: () => 'Foto bukti kehadiran / selfie wajib diambil.',
      ));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      submissionSuccess: false,
      errorMessage: () => null,
    ));

    try {
      final safeAddress = await _addressFetcher(
        latitude: state.latitude!,
        longitude: state.longitude!,
      );

      final request = LiveAttendanceRequest(
        attendanceMethod: state.attendanceMethod,
        latitude: state.latitude!,
        longitude: state.longitude!,
        attendanceType: state.attendanceType,
        file: state.isPhotoMethod ? state.photo : null,
        address: safeAddress,
        reason: state.reason.trim(),
      );

      final response = await repository.submitLiveAttendance(request);

      _clockTimer?.cancel();
      _clockTimer = null;

      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: true,
        successMessage: () => response.message,
        submissionResult: () => response.data,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: false,
        errorMessage: () => e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: false,
        errorMessage: () =>
            'Terjadi kesalahan saat mengirim presensi: ${e.toString()}',
      ));
    }
  }
}
