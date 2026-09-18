import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScheduleAttendanceState extends Equatable {
  /// Metode presensi ('photo' | 'biometric')
  final String attendanceMethod;

  /// Jenis presensi ('in' | 'out' | 'inout')
  final String attendanceType;

  /// Tanggal presensi terjadwal
  final DateTime selectedDate;

  /// Jam masuk terencana
  final TimeOfDay inTime;

  /// Jam pulang terencana
  final TimeOfDay outTime;

  /// Koordinat & alamat masuk
  final double? inLatitude;
  final double? longitudeIn;
  final String? addressIn;

  /// Koordinat & alamat pulang
  final double? latitudeOut;
  final double? longitudeOut;
  final String? addressOut;

  /// Apakah lokasi masuk dan pulang sama
  final bool isSameLocation;

  /// Berkas foto selfie masuk
  final XFile? inPhoto;

  /// Berkas foto selfie pulang
  final XFile? outPhoto;

  /// Alasan presensi terjadwal
  final String reason;

  /// Status proses submit
  final bool isSubmitting;
  final bool submissionSuccess;
  final String? successMessage;
  final String? errorMessage;
  final int? errorCode;

  const ScheduleAttendanceState({
    this.attendanceMethod = 'photo',
    this.attendanceType = 'inout',
    required this.selectedDate,
    this.inTime = const TimeOfDay(hour: 8, minute: 30),
    this.outTime = const TimeOfDay(hour: 17, minute: 0),
    this.inLatitude,
    this.longitudeIn,
    this.addressIn,
    this.latitudeOut,
    this.longitudeOut,
    this.addressOut,
    this.isSameLocation = true,
    this.inPhoto,
    this.outPhoto,
    this.reason = '',
    this.isSubmitting = false,
    this.submissionSuccess = false,
    this.successMessage,
    this.errorMessage,
    this.errorCode,
  });

  bool get isPhotoMethod => attendanceMethod == 'photo';
  bool get isBiometricMethod => attendanceMethod == 'biometric';

  bool get hasIn => attendanceType == 'in' || attendanceType == 'inout';
  bool get hasOut => attendanceType == 'out' || attendanceType == 'inout';

  /// Alias getter untuk kompatibilitas
  double? get latitudeIn => inLatitude;
  bool get sameLocation => isSameLocation;

  bool get hasValidInLocation =>
      inLatitude != null &&
      longitudeIn != null &&
      addressIn != null &&
      addressIn!.trim().isNotEmpty;

  bool get hasValidOutLocation =>
      latitudeOut != null &&
      longitudeOut != null &&
      addressOut != null &&
      addressOut!.trim().isNotEmpty;

  /// Menghasilkan format tanggal ISO: `yyyy-MM-ddTHH:mm:ss`
  String get formattedInDateTime {
    final y = selectedDate.year.toString().padLeft(4, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    final d = selectedDate.day.toString().padLeft(2, '0');
    final h = inTime.hour.toString().padLeft(2, '0');
    final min = inTime.minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00';
  }

  /// Menghasilkan format tanggal ISO: `yyyy-MM-ddTHH:mm:ss`
  String get formattedOutDateTime {
    final y = selectedDate.year.toString().padLeft(4, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    final d = selectedDate.day.toString().padLeft(2, '0');
    final h = outTime.hour.toString().padLeft(2, '0');
    final min = outTime.minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00';
  }

  ScheduleAttendanceState copyWith({
    String? attendanceMethod,
    String? attendanceType,
    DateTime? selectedDate,
    TimeOfDay? inTime,
    TimeOfDay? outTime,
    double? inLatitude,
    double? longitudeIn,
    String? addressIn,
    double? latitudeOut,
    double? longitudeOut,
    String? addressOut,
    bool? isSameLocation,
    XFile? inPhoto,
    bool clearInPhoto = false,
    XFile? outPhoto,
    bool clearOutPhoto = false,
    String? reason,
    bool? isSubmitting,
    bool? submissionSuccess,
    String? successMessage,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? errorCode,
    bool clearErrorCode = false,
  }) {
    return ScheduleAttendanceState(
      attendanceMethod: attendanceMethod ?? this.attendanceMethod,
      attendanceType: attendanceType ?? this.attendanceType,
      selectedDate: selectedDate ?? this.selectedDate,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
      inLatitude: inLatitude ?? this.inLatitude,
      longitudeIn: longitudeIn ?? this.longitudeIn,
      addressIn: addressIn ?? this.addressIn,
      latitudeOut: latitudeOut ?? this.latitudeOut,
      longitudeOut: longitudeOut ?? this.longitudeOut,
      addressOut: addressOut ?? this.addressOut,
      isSameLocation: isSameLocation ?? this.isSameLocation,
      inPhoto: clearInPhoto ? null : (inPhoto ?? this.inPhoto),
      outPhoto: clearOutPhoto ? null : (outPhoto ?? this.outPhoto),
      reason: reason ?? this.reason,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      successMessage: successMessage ?? this.successMessage,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [
        attendanceMethod,
        attendanceType,
        selectedDate,
        inTime,
        outTime,
        inLatitude,
        longitudeIn,
        addressIn,
        latitudeOut,
        longitudeOut,
        addressOut,
        isSameLocation,
        inPhoto,
        outPhoto,
        reason,
        isSubmitting,
        submissionSuccess,
        successMessage,
        errorMessage,
        errorCode,
      ];
}
