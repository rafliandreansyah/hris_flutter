import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract class ScheduleAttendanceEvent extends Equatable {
  const ScheduleAttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal form schedule attendance
class ScheduleAttendanceStarted extends ScheduleAttendanceEvent {
  final String? initialMethod;
  final String? initialType;

  const ScheduleAttendanceStarted({
    this.initialMethod,
    this.initialType,
  });

  @override
  List<Object?> get props => [initialMethod, initialType];
}

/// Mengubah metode presensi: 'photo' | 'biometric'
class ScheduleAttendanceMethodChanged extends ScheduleAttendanceEvent {
  final String attendanceMethod;

  const ScheduleAttendanceMethodChanged(this.attendanceMethod);

  @override
  List<Object?> get props => [attendanceMethod];
}

/// Mengubah tipe pengajuan presensi: 'in' | 'out' | 'inout'
class ScheduleAttendanceTypeChanged extends ScheduleAttendanceEvent {
  final String attendanceType;

  const ScheduleAttendanceTypeChanged(this.attendanceType);

  @override
  List<Object?> get props => [attendanceType];
}

/// Mengubah tanggal presensi terjadwal
class ScheduleAttendanceDateChanged extends ScheduleAttendanceEvent {
  final DateTime date;

  const ScheduleAttendanceDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

/// Mengubah jam masuk terencana
class ScheduleAttendanceInTimeChanged extends ScheduleAttendanceEvent {
  final TimeOfDay time;

  const ScheduleAttendanceInTimeChanged(this.time);

  @override
  List<Object?> get props => [time];
}

/// Mengubah jam pulang terencana
class ScheduleAttendanceOutTimeChanged extends ScheduleAttendanceEvent {
  final TimeOfDay time;

  const ScheduleAttendanceOutTimeChanged(this.time);

  @override
  List<Object?> get props => [time];
}

/// Memperbarui koordinat dan alamat lokasi masuk
class ScheduleAttendanceInLocationChanged extends ScheduleAttendanceEvent {
  final double latitude;
  final double longitude;
  final String address;

  const ScheduleAttendanceInLocationChanged({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

/// Memperbarui koordinat dan alamat lokasi pulang
class ScheduleAttendanceOutLocationChanged extends ScheduleAttendanceEvent {
  final double latitude;
  final double longitude;
  final String address;

  const ScheduleAttendanceOutLocationChanged({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

/// Mengaktifkan atau menonaktifkan opsi bahwa lokasi in dan out sama
class ScheduleAttendanceSameLocationToggled extends ScheduleAttendanceEvent {
  final bool isSame;

  const ScheduleAttendanceSameLocationToggled(this.isSame);

  @override
  List<Object?> get props => [isSame];
}

/// Memperbarui foto selfie masuk
class ScheduleAttendanceInPhotoChanged extends ScheduleAttendanceEvent {
  final XFile? photo;

  const ScheduleAttendanceInPhotoChanged(this.photo);

  @override
  List<Object?> get props => [photo];
}

/// Memperbarui foto selfie pulang
class ScheduleAttendanceOutPhotoChanged extends ScheduleAttendanceEvent {
  final XFile? photo;

  const ScheduleAttendanceOutPhotoChanged(this.photo);

  @override
  List<Object?> get props => [photo];
}

/// Memperbarui teks alasan presensi terjadwal
class ScheduleAttendanceReasonChanged extends ScheduleAttendanceEvent {
  final String reason;

  const ScheduleAttendanceReasonChanged(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// Mengirimkan formulir permohonan presensi terjadwal ke backend
class ScheduleAttendanceSubmitted extends ScheduleAttendanceEvent {
  const ScheduleAttendanceSubmitted();
}
