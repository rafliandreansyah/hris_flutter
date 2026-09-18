import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:image_picker/image_picker.dart';

class LiveAttendanceState extends Equatable {
  final DateTime currentClockTime;
  final String attendanceMethod;
  final String attendanceType;
  final double? latitude;
  final double? longitude;
  final String gpsAccuracy;
  final bool isLocating;
  final String reason;
  final XFile? photo;
  final bool isSubmitting;
  final bool submissionSuccess;
  final String? successMessage;
  final LiveAttendanceData? submissionResult;
  final String? errorMessage;

  const LiveAttendanceState({
    required this.currentClockTime,
    this.attendanceMethod = 'photo',
    this.attendanceType = 'in',
    this.latitude,
    this.longitude,
    this.gpsAccuracy = '±3m',
    this.isLocating = true,
    this.reason = '',
    this.photo,
    this.isSubmitting = false,
    this.submissionSuccess = false,
    this.successMessage,
    this.submissionResult,
    this.errorMessage,
  });

  /// True jika metode presensi mengharuskan autentikasi sensor biometrik (Fingerprint / Face ID)
  bool get isBiometricMethod =>
      attendanceMethod.toLowerCase().contains('biometric') ||
      attendanceMethod.toLowerCase().contains('finger');

  /// True jika metode presensi menggunakan foto selfie
  bool get isPhotoMethod => !isBiometricMethod;

  /// True jika koordinat valid telah didapatkan dari sensor GPS
  bool get hasValidCoordinates =>
      latitude != null &&
      longitude != null &&
      (latitude != 0.0 || longitude != 0.0);

  /// True jika seluruh isian formulir yang wajib telah terpenuhi
  bool get isFormValid {
    if (!hasValidCoordinates) return false;
    if (reason.trim().isEmpty) return false;
    if (isPhotoMethod && photo == null) return false;
    return true;
  }

  LiveAttendanceState copyWith({
    DateTime? currentClockTime,
    String? attendanceMethod,
    String? attendanceType,
    double? latitude,
    double? longitude,
    String? gpsAccuracy,
    bool? isLocating,
    String? reason,
    XFile? Function()? photo,
    bool? isSubmitting,
    bool? submissionSuccess,
    String? Function()? successMessage,
    LiveAttendanceData? Function()? submissionResult,
    String? Function()? errorMessage,
  }) {
    return LiveAttendanceState(
      currentClockTime: currentClockTime ?? this.currentClockTime,
      attendanceMethod: attendanceMethod ?? this.attendanceMethod,
      attendanceType: attendanceType ?? this.attendanceType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      isLocating: isLocating ?? this.isLocating,
      reason: reason ?? this.reason,
      photo: photo != null ? photo() : this.photo,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      successMessage:
          successMessage != null ? successMessage() : this.successMessage,
      submissionResult:
          submissionResult != null ? submissionResult() : this.submissionResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentClockTime,
        attendanceMethod,
        attendanceType,
        latitude,
        longitude,
        gpsAccuracy,
        isLocating,
        reason,
        photo?.path,
        isSubmitting,
        submissionSuccess,
        successMessage,
        submissionResult,
        errorMessage,
      ];
}
