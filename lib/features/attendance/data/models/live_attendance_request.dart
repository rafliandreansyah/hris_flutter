import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Model payload permintaan untuk endpoint Live Attendance (`POST /attendances/requests/live`).
class LiveAttendanceRequest {
  /// Metode presensi ('photo' | 'biometric')
  final String attendanceMethod;

  /// Koordinat latitude
  final double latitude;

  /// Koordinat longitude
  final double longitude;

  /// Jenis presensi ('in' | 'out')
  final String attendanceType;

  /// Berkas foto selfie / bukti kehadiran (hanya disertakan jika `attendanceMethod == 'photo'`)
  final XFile? file;

  /// Alamat lengkap hasil reverse-geocoding Mapbox
  final String address;

  /// Alasan presensi di luar kantor
  final String reason;

  const LiveAttendanceRequest({
    this.attendanceMethod = 'photo',
    required this.latitude,
    required this.longitude,
    required this.attendanceType,
    this.file,
    required this.address,
    required this.reason,
  });

  /// Mengonversi payload ke dalam format Map yang siap digunakan oleh [FormData.fromMap].
  Future<Map<String, dynamic>> toFormDataMap() async {
    final map = <String, dynamic>{
      'attendanceMethod': attendanceMethod,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'attendanceType': attendanceType,
      'address': address.trim(),
      'reason': reason.trim(),
    };

    if (file != null) {
      final fileName = file!.name.isNotEmpty
          ? file!.name
          : file!.path.split(RegExp(r'[/\\]')).last;
      map['file'] = await MultipartFile.fromFile(
        file!.path,
        filename: fileName,
      );
    }

    return map;
  }
}
