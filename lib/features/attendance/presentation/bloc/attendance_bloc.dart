import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;
  Timer? _clockTimer;

  AttendanceBloc({
    required this.repository,
    bool autoStartClock = true,
  }) : super(const AttendanceInitial()) {
    on<AttendanceFetchRequested>(_onFetchRequested);
    on<AttendanceClockTicked>(_onClockTicked);
    on<AttendanceLocationUpdated>(_onLocationUpdated);
    on<AttendanceWorkLocationChanged>(_onWorkLocationChanged);
    on<AttendanceClockInSubmitted>(_onClockInSubmitted);
    on<AttendanceClockOutSubmitted>(_onClockOutSubmitted);
    on<AttendanceBreakToggled>(_onBreakToggled);
    on<AttendanceReportIssueSubmitted>(_onReportIssueSubmitted);

    if (autoStartClock) {
      _startClockTimer();
    }
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is AttendanceLoaded) {
        final current = (state as AttendanceLoaded).currentClockTime;
        add(AttendanceClockTicked(current.add(const Duration(seconds: 1))));
      }
    });
  }

  /// Hitung isInsideGeofence berdasarkan GPS dan lokasi kerja terpilih.
  bool _calculateIsInsideGeofence({
    required double? userLat,
    required double? userLng,
    required WorkLocationItem? selectedWorkLocation,
  }) {
    if (selectedWorkLocation == null) {
      return false;
    }
    if (selectedWorkLocation.isAnyWhere) {
      return true;
    }
    if (userLat == null || userLng == null) {
      return false;
    }
    if (selectedWorkLocation.latitude == null ||
        selectedWorkLocation.longitude == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      userLat,
      userLng,
      selectedWorkLocation.latitude!,
      selectedWorkLocation.longitude!,
    );
    return distance <= selectedWorkLocation.radius;
  }

  Future<void> _onFetchRequested(
    AttendanceFetchRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(const AttendanceLoading());
    }

    try {
      final data = await repository.getTodayAttendance();
      final clockTime = data.serverTime;

      // Poin 7: Jangan fallback userLatitude ke officeLatitude.
      // Biarkan null agar BLoC tahu GPS belum tersedia.
      // isInsideGeofence berasal dari repository (false untuk normal, true untuk isAnyWhere).
      emit(
        AttendanceLoaded(
          data: data,
          currentClockTime: clockTime,
          userLatitude: null,
          userLongitude: null,
          gpsAccuracyMeters: 5.0,
          isInsideGeofence: data.isInsideGeofence,
          isGpsAcquired: false,
        ),
      );
    } on ApiException catch (e) {
      emit(AttendanceFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(AttendanceFailure(_extractErrorMessage(e)));
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  void _onClockTicked(
    AttendanceClockTicked event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(currentClockTime: event.currentTime));
    }
  }

  void _onLocationUpdated(
    AttendanceLocationUpdated event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;

      // Hitung geofence berdasarkan lokasi kerja terpilih
      final isInside = _calculateIsInsideGeofence(
        userLat: event.latitude,
        userLng: event.longitude,
        selectedWorkLocation: current.data.selectedWorkLocation,
      );

      emit(
        current.copyWith(
          userLatitude: event.latitude,
          userLongitude: event.longitude,
          gpsAccuracyMeters: event.accuracy,
          isInsideGeofence: isInside,
          isGpsAcquired: true,
          data: current.data.copyWith(
            userLatitude: event.latitude,
            userLongitude: event.longitude,
            isInsideGeofence: isInside,
            gpsAccuracy: '±${event.accuracy.toStringAsFixed(0)}m',
          ),
        ),
      );
    }
  }

  /// Handler pergantian lokasi kerja oleh user.
  void _onWorkLocationChanged(
    AttendanceWorkLocationChanged event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      final loc = event.selectedLocation;

      // Tentukan parameter lokasi kantor baru
      final String officeName = loc.name;
      final String officeDetail =
          loc.address.isNotEmpty ? loc.address : 'HQ Office — Main Lobby';
      final double officeLat = loc.latitude ?? -6.2253;
      final double officeLng = loc.longitude ?? 106.8097;
      final double geofenceRadius = loc.isAnyWhere
          ? 0.0
          : (loc.radius < 5 ? 50.0 : loc.radius);

      // Hitung ulang geofence jika GPS sudah tersedia
      final isInside = _calculateIsInsideGeofence(
        userLat: current.userLatitude,
        userLng: current.userLongitude,
        selectedWorkLocation: loc,
      );

      emit(
        current.copyWith(
          isInsideGeofence: isInside,
          data: current.data.copyWith(
            selectedWorkLocation: loc,
            officeName: officeName,
            officeDetail: officeDetail,
            officeLatitude: officeLat,
            officeLongitude: officeLng,
            geofenceRadiusMeters: geofenceRadius,
            isInsideGeofence: isInside,
          ),
        ),
      );
    }
  }

  Future<void> _onClockInSubmitted(
    AttendanceClockInSubmitted event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(isSubmittingAction: true));

      try {
        final updatedData = await repository.clockIn(
          latitude: event.latitude,
          longitude: event.longitude,
          address: event.address,
          note: event.note,
        );

        emit(
          current.copyWith(
            data: updatedData.copyWith(
              availableWorkLocations: current.data.availableWorkLocations,
              selectedWorkLocation: current.data.selectedWorkLocation,
            ),
            isSubmittingAction: false,
            actionMessage: 'Clock In berhasil dicatat!',
          ),
        );
      } catch (e) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: 'Gagal melakukan Clock In: ${_extractErrorMessage(e)}',
          ),
        );
      }
    }
  }

  Future<void> _onClockOutSubmitted(
    AttendanceClockOutSubmitted event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(isSubmittingAction: true));

      try {
        final updatedData = await repository.clockOut(
          latitude: event.latitude,
          longitude: event.longitude,
          address: event.address,
          note: event.note,
        );

        emit(
          current.copyWith(
            data: updatedData.copyWith(
              availableWorkLocations: current.data.availableWorkLocations,
              selectedWorkLocation: current.data.selectedWorkLocation,
            ),
            isSubmittingAction: false,
            actionMessage: 'Clock Out berhasil dicatat!',
          ),
        );
      } catch (e) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: 'Gagal melakukan Clock Out: ${_extractErrorMessage(e)}',
          ),
        );
      }
    }
  }

  Future<void> _onBreakToggled(
    AttendanceBreakToggled event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(isSubmittingAction: true));

      try {
        final updatedData = await repository.toggleBreak();
        final message = updatedData.isOnBreak
            ? 'Istirahat dimulai (Break Out)'
            : 'Selesai istirahat (Break In)';

        emit(
          current.copyWith(
            data: updatedData.copyWith(
              availableWorkLocations: current.data.availableWorkLocations,
              selectedWorkLocation: current.data.selectedWorkLocation,
            ),
            isSubmittingAction: false,
            actionMessage: message,
          ),
        );
      } catch (e) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: 'Gagal memperbarui status break: ${_extractErrorMessage(e)}',
          ),
        );
      }
    }
  }

  Future<void> _onReportIssueSubmitted(
    AttendanceReportIssueSubmitted event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      try {
        await repository.reportLocationIssue(
          issueDescription: event.issueDescription,
          latitude: event.latitude,
          longitude: event.longitude,
        );

        emit(
          current.copyWith(
            actionMessage: 'Laporan kendala lokasi berhasil dikirim',
          ),
        );
      } catch (e) {
        emit(
          current.copyWith(
            errorMessage: 'Gagal mengirim laporan kendala lokasi: ${_extractErrorMessage(e)}',
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _clockTimer?.cancel();
    return super.close();
  }
}

