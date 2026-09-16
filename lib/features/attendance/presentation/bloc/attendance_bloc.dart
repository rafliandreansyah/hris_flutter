import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
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

  AttendanceLocationUpdated? _lastLocationEvent;

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

      // Pertahankan lokasi GPS yang sudah didapatkan saat reload/refresh
      double? lat = _lastLocationEvent?.latitude;
      double? lng = _lastLocationEvent?.longitude;
      double accuracy = _lastLocationEvent?.accuracy ?? 5.0;

      if (state is AttendanceLoaded) {
        final current = state as AttendanceLoaded;
        lat ??= current.userLatitude;
        lng ??= current.userLongitude;
        if (_lastLocationEvent == null) {
          accuracy = current.gpsAccuracyMeters;
        }
      }

      // Pertahankan lokasi kerja yang terakhir dipilih jika reload/refresh
      WorkLocationItem? activeLocation = data.selectedWorkLocation;
      if (state is AttendanceLoaded) {
        final current = state as AttendanceLoaded;
        final prevLocation = current.data.selectedWorkLocation;
        if (prevLocation != null) {
          final matched = data.availableWorkLocations.where(
            (loc) => loc.id == prevLocation.id,
          );
          if (matched.isNotEmpty) {
            activeLocation = matched.first;
          } else {
            activeLocation = prevLocation;
          }
        }
      }

      // Update parameter lokasi kantor jika activeLocation berbeda dari default server
      String officeName = data.officeName;
      String officeDetail = data.officeDetail;
      double officeLat = data.officeLatitude;
      double officeLng = data.officeLongitude;
      double geofenceRadius = data.geofenceRadiusMeters;

      if (activeLocation != null) {
        if (activeLocation.name.isNotEmpty) {
          officeName = activeLocation.name;
        }
        if (activeLocation.address.isNotEmpty) {
          officeDetail = activeLocation.address;
        }
        if (activeLocation.latitude != null) {
          officeLat = activeLocation.latitude!;
        }
        if (activeLocation.longitude != null) {
          officeLng = activeLocation.longitude!;
        }
        geofenceRadius = activeLocation.isAnyWhere
            ? 0.0
            : (activeLocation.radius < 5 ? 50.0 : activeLocation.radius);
      }

      final isGpsAcquired = lat != null && lng != null;
      final isInside = isGpsAcquired
          ? _calculateIsInsideGeofence(
              userLat: lat,
              userLng: lng,
              selectedWorkLocation: activeLocation,
            )
          : (activeLocation?.isAnyWhere ?? false
              ? true
              : data.isInsideGeofence);

      emit(
        AttendanceLoaded(
          data: data.copyWith(
            selectedWorkLocation: activeLocation,
            officeName: officeName,
            officeDetail: officeDetail,
            officeLatitude: officeLat,
            officeLongitude: officeLng,
            geofenceRadiusMeters: geofenceRadius,
            userLatitude: lat,
            userLongitude: lng,
            isInsideGeofence: isInside,
            gpsAccuracy: isGpsAcquired ? '±${accuracy.toStringAsFixed(0)}m' : '±5m',
          ),
          currentClockTime: clockTime,
          userLatitude: lat,
          userLongitude: lng,
          gpsAccuracyMeters: accuracy,
          isInsideGeofence: isInside,
          isGpsAcquired: isGpsAcquired,
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
    _lastLocationEvent = event;
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
          clearAttendanceSuccess: true,
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
          clearAttendanceSuccess: true,
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

  /// Helper terpusat untuk membangun state [AttendanceLoaded] dengan mempertahankan lokasi
  /// kerja terpilih ([selectedWorkLocation]) dan memastikan koordinat kantor, radius geofence,
  /// serta status [isInsideGeofence] selalu disinkronkan dari lokasi kerja tersebut, bukan tertimpa
  /// oleh default server.
  AttendanceLoaded _buildLoadedWithActiveLocation({
    required AttendanceLoaded current,
    required AttendanceTodayData updatedData,
    String? actionMessage,
    bool isSubmittingAction = false,
    AttendanceSuccessInfo? attendanceSuccess,
  }) {
    // 1. Cari activeLocation dari data yang sudah ada sebelumnya
    WorkLocationItem? activeLocation = updatedData.selectedWorkLocation;
    final prevLocation = current.data.selectedWorkLocation;
    if (prevLocation != null) {
      final matched = updatedData.availableWorkLocations.where(
        (loc) => loc.id == prevLocation.id,
      );
      if (matched.isNotEmpty) {
        activeLocation = matched.first;
      } else {
        final matchedByName = updatedData.availableWorkLocations.where(
          (loc) => loc.name.toLowerCase() == prevLocation.name.toLowerCase(),
        );
        if (matchedByName.isNotEmpty) {
          activeLocation = matchedByName.first;
        } else {
          activeLocation = prevLocation;
        }
      }
    }

    // 2. Sinkronkan nama, detail, dan koordinat kantor dari activeLocation
    String officeName = updatedData.officeName;
    String officeDetail = updatedData.officeDetail;
    double officeLat = updatedData.officeLatitude;
    double officeLng = updatedData.officeLongitude;
    double geofenceRadius = updatedData.geofenceRadiusMeters;

    if (activeLocation != null) {
      if (activeLocation.name.isNotEmpty) {
        officeName = activeLocation.name;
      }
      if (activeLocation.address.isNotEmpty) {
        officeDetail = activeLocation.address;
      }
      if (activeLocation.latitude != null) {
        officeLat = activeLocation.latitude!;
      }
      if (activeLocation.longitude != null) {
        officeLng = activeLocation.longitude!;
      }
      geofenceRadius = activeLocation.isAnyWhere
          ? 0.0
          : (activeLocation.radius < 5 ? 50.0 : activeLocation.radius);
    }

    // 3. Koordinat GPS user & perhitungan ulang geofence
    final userLat = current.userLatitude ?? updatedData.userLatitude;
    final userLng = current.userLongitude ?? updatedData.userLongitude;
    final isGpsAcquired = current.isGpsAcquired || (userLat != null && userLng != null);

    final isInside = (activeLocation?.isAnyWhere ?? false)
        ? true
        : ((userLat != null && userLng != null)
            ? _calculateIsInsideGeofence(
                userLat: userLat,
                userLng: userLng,
                selectedWorkLocation: activeLocation,
              )
            : updatedData.isInsideGeofence);

    return current.copyWith(
      isInsideGeofence: isInside,
      isGpsAcquired: isGpsAcquired,
      userLatitude: userLat,
      userLongitude: userLng,
      isSubmittingAction: isSubmittingAction,
      actionMessage: actionMessage,
      attendanceSuccess: attendanceSuccess,
      data: updatedData.copyWith(
        selectedWorkLocation: activeLocation,
        availableWorkLocations: updatedData.availableWorkLocations.isNotEmpty
            ? updatedData.availableWorkLocations
            : current.data.availableWorkLocations,
        officeName: officeName,
        officeDetail: officeDetail,
        officeLatitude: officeLat,
        officeLongitude: officeLng,
        geofenceRadiusMeters: geofenceRadius,
        userLatitude: userLat,
        userLongitude: userLng,
        isInsideGeofence: isInside,
      ),
    );
  }

  Future<void> _onClockInSubmitted(
    AttendanceClockInSubmitted event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      final loc = current.data.selectedWorkLocation;
      final isAnyWhere = loc?.isAnyWhere ?? false;
      final effectiveUserLat = current.userLatitude ?? event.latitude;
      final effectiveUserLng = current.userLongitude ?? event.longitude;
      final isInside = isAnyWhere ||
          current.isInsideGeofence ||
          (loc != null &&
              _calculateIsInsideGeofence(
                userLat: effectiveUserLat,
                userLng: effectiveUserLng,
                selectedWorkLocation: loc,
              ));
      if (loc != null && !isAnyWhere && !isInside) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: 'Tidak dapat melakukan presensi di luar radius kantor.',
          ),
        );
        return;
      }

      emit(current.copyWith(isSubmittingAction: true));

      try {
        final updatedData = await repository.clockIn(
          latitude: event.latitude,
          longitude: event.longitude,
          address: event.address,
          note: event.note,
          attendanceMethod: event.attendanceMethod,
          workLocationId: event.workLocationId,
          photoFile: event.photoFile,
        );

        final activeLoc = current.data.selectedWorkLocation ?? updatedData.selectedWorkLocation;
        final officeName = (activeLoc != null && activeLoc.name.isNotEmpty)
            ? activeLoc.name
            : updatedData.officeName;
        final recordTime = updatedData.inTime ?? AppDateUtil.formatDateTimeHHmm(DateTime.now());
        final formattedDate = AppDateUtil.formatDateFull(updatedData.serverTime, locale: 'id');
        final effectiveTz = _resolveTimezone(updatedData.timezone);

        final successInfo = AttendanceSuccessInfo(
          attendanceType: 'in',
          title: 'Presensi Masuk Berhasil',
          message: 'Presensi Masuk Anda berhasil dicatat oleh sistem.',
          date: updatedData.serverTime,
          formattedDate: formattedDate,
          formattedTime: '$recordTime $effectiveTz',
          locationName: officeName,
        );

        emit(
          _buildLoadedWithActiveLocation(
            current: current.copyWith(
              userLatitude: effectiveUserLat,
              userLongitude: effectiveUserLng,
            ),
            updatedData: updatedData,
            actionMessage: 'Clock In berhasil dicatat!',
            isSubmittingAction: false,
            attendanceSuccess: successInfo,
          ),
        );
      } catch (e) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: _extractErrorMessage(e),
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
      final loc = current.data.selectedWorkLocation;
      final isAnyWhere = loc?.isAnyWhere ?? false;
      final effectiveUserLat = current.userLatitude ?? event.latitude;
      final effectiveUserLng = current.userLongitude ?? event.longitude;
      final isInside = isAnyWhere ||
          current.isInsideGeofence ||
          (loc != null &&
              _calculateIsInsideGeofence(
                userLat: effectiveUserLat,
                userLng: effectiveUserLng,
                selectedWorkLocation: loc,
              ));
      if (loc != null && !isAnyWhere && !isInside) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: 'Tidak dapat melakukan presensi di luar radius kantor.',
          ),
        );
        return;
      }

      emit(current.copyWith(isSubmittingAction: true));

      try {
        final updatedData = await repository.clockOut(
          latitude: event.latitude,
          longitude: event.longitude,
          address: event.address,
          note: event.note,
          attendanceMethod: event.attendanceMethod,
          workLocationId: event.workLocationId,
          photoFile: event.photoFile,
        );

        final activeLoc = current.data.selectedWorkLocation ?? updatedData.selectedWorkLocation;
        final officeName = (activeLoc != null && activeLoc.name.isNotEmpty)
            ? activeLoc.name
            : updatedData.officeName;
        final recordTime = updatedData.outTime ?? AppDateUtil.formatDateTimeHHmm(DateTime.now());
        final formattedDate = AppDateUtil.formatDateFull(updatedData.serverTime, locale: 'id');
        final effectiveTz = _resolveTimezone(updatedData.timezone);

        final successInfo = AttendanceSuccessInfo(
          attendanceType: 'out',
          title: 'Presensi Pulang Berhasil',
          message: 'Presensi Pulang Anda berhasil dicatat oleh sistem.',
          date: updatedData.serverTime,
          formattedDate: formattedDate,
          formattedTime: '$recordTime $effectiveTz',
          locationName: officeName,
        );

        emit(
          _buildLoadedWithActiveLocation(
            current: current.copyWith(
              userLatitude: effectiveUserLat,
              userLongitude: effectiveUserLng,
            ),
            updatedData: updatedData,
            actionMessage: 'Clock Out berhasil dicatat!',
            isSubmittingAction: false,
            attendanceSuccess: successInfo,
          ),
        );
      } catch (e) {
        emit(
          current.copyWith(
            isSubmittingAction: false,
            errorMessage: _extractErrorMessage(e),
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
          _buildLoadedWithActiveLocation(
            current: current,
            updatedData: updatedData,
            actionMessage: message,
            isSubmittingAction: false,
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

  static String _resolveTimezone(String? timezone) {
    final tz = (timezone ?? '').trim();
    if (tz.isNotEmpty) return tz;
    return 'Asia/Jakarta';
  }

  @override
  Future<void> close() {
    _clockTimer?.cancel();
    return super.close();
  }
}

