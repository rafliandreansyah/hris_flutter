import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceSuccessInfo extends Equatable {
  final String attendanceType; // 'in' or 'out'
  final String title;
  final String message;
  final DateTime date;
  final String formattedDate;
  final String formattedTime;
  final String locationName;

  const AttendanceSuccessInfo({
    required this.attendanceType,
    required this.title,
    required this.message,
    required this.date,
    required this.formattedDate,
    required this.formattedTime,
    required this.locationName,
  });

  @override
  List<Object?> get props => [
        attendanceType,
        title,
        message,
        date,
        formattedDate,
        formattedTime,
        locationName,
      ];
}

class AttendanceLoaded extends AttendanceState {
  final AttendanceTodayData data;
  final DateTime currentClockTime;
  final bool isSubmittingAction;
  final String? actionMessage;
  final String? errorMessage;
  final double? userLatitude;
  final double? userLongitude;
  final double gpsAccuracyMeters;
  final bool isInsideGeofence;

  /// Apakah GPS sudah berhasil didapat. Jika false, geofence belum dihitung.
  final bool isGpsAcquired;

  /// Data sukses presensi (clock in / clock out) untuk memicu dialog sukses.
  final AttendanceSuccessInfo? attendanceSuccess;

  const AttendanceLoaded({
    required this.data,
    required this.currentClockTime,
    this.isSubmittingAction = false,
    this.actionMessage,
    this.errorMessage,
    this.userLatitude,
    this.userLongitude,
    this.gpsAccuracyMeters = 5.0,
    this.isInsideGeofence = true,
    this.isGpsAcquired = false,
    this.attendanceSuccess,
  });

  /// Format waktu jam:menit:detik tanpa 'WIB' karena timezone sudah ditampilkan secara terpisah di chip.
  String get formattedClockTime =>
      AppDateUtil.formatTimeWithSeconds(currentClockTime);

  AttendanceLoaded copyWith({
    AttendanceTodayData? data,
    DateTime? currentClockTime,
    bool? isSubmittingAction,
    String? actionMessage,
    String? errorMessage,
    double? userLatitude,
    double? userLongitude,
    double? gpsAccuracyMeters,
    bool? isInsideGeofence,
    bool? isGpsAcquired,
    AttendanceSuccessInfo? attendanceSuccess,
    bool clearAttendanceSuccess = false,
  }) {
    return AttendanceLoaded(
      data: data ?? this.data,
      currentClockTime: currentClockTime ?? this.currentClockTime,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      actionMessage: actionMessage,
      errorMessage: errorMessage,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      isGpsAcquired: isGpsAcquired ?? this.isGpsAcquired,
      attendanceSuccess: clearAttendanceSuccess ? null : attendanceSuccess,
    );
  }

  @override
  List<Object?> get props => [
        data,
        currentClockTime,
        isSubmittingAction,
        actionMessage,
        errorMessage,
        userLatitude,
        userLongitude,
        gpsAccuracyMeters,
        isInsideGeofence,
        isGpsAcquired,
        attendanceSuccess,
      ];
}

class AttendanceFailure extends AttendanceState {
  final String message;
  final int? statusCode;

  const AttendanceFailure(this.message, {this.statusCode});

  /// Menandakan error 404 Not Found (URL tidak ditemukan atau karyawan belum memiliki jadwal kerja aktif).
  bool get isNotFound => statusCode == 404;

  @override
  List<Object?> get props => [message, statusCode];
}

