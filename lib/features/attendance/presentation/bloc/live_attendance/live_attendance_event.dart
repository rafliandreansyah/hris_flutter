import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class LiveAttendanceEvent extends Equatable {
  const LiveAttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal Live Attendance: memicu timer WIB dan deteksi metode presensi.
class LiveAttendanceStarted extends LiveAttendanceEvent {
  final String? initialMethod;

  const LiveAttendanceStarted({this.initialMethod});

  @override
  List<Object?> get props => [initialMethod];
}

/// Event update waktu jam real-time WIB Asia/Jakarta setiap 1 detik.
class LiveAttendanceClockTicked extends LiveAttendanceEvent {
  final DateTime time;

  const LiveAttendanceClockTicked(this.time);

  @override
  List<Object?> get props => [time];
}

/// Event saat pengguna memilih jenis presensi: 'in' (Masuk) atau 'out' (Pulang).
class LiveAttendanceTypeChanged extends LiveAttendanceEvent {
  final String attendanceType;

  const LiveAttendanceTypeChanged(this.attendanceType);

  @override
  List<Object?> get props => [attendanceType];
}

/// Event saat koordinat dan akurasi GPS diperbarui dari modul peta.
class LiveAttendanceLocationUpdated extends LiveAttendanceEvent {
  final double latitude;
  final double longitude;
  final String accuracy;

  const LiveAttendanceLocationUpdated({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy];
}

/// Event saat teks alasan presensi luar kantor berubah.
class LiveAttendanceReasonChanged extends LiveAttendanceEvent {
  final String reason;

  const LiveAttendanceReasonChanged(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// Event saat berkas foto selfie/bukti kehadiran diubah atau dihapus.
class LiveAttendancePhotoChanged extends LiveAttendanceEvent {
  final XFile? photo;

  const LiveAttendancePhotoChanged(this.photo);

  @override
  List<Object?> get props => [photo];
}

/// Event submit presensi live ke server.
class LiveAttendanceSubmitted extends LiveAttendanceEvent {
  const LiveAttendanceSubmitted();
}
