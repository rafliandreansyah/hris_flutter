import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Model payload permintaan untuk endpoint Schedule Attendance (`POST /attendances/requests/schedule`).
class ScheduleAttendanceRequest {
  /// Metode presensi ('photo' | 'biometric')
  final String attendanceMethod;

  /// Jenis presensi ('in' | 'out' | 'inout')
  final String attendanceType;

  /// Alasan / keterangan presensi terjadwal di luar kantor
  final String reason;

  /// Waktu presensi masuk terencana (format ISO: `yyyy-MM-ddTHH:mm:ss`)
  final String? attendanceInTime;

  /// Koordinat latitude lokasi masuk
  final double? latitudeIn;

  /// Koordinat longitude lokasi masuk
  final double? longitudeIn;

  /// Alamat lengkap lokasi masuk
  final String? addressIn;

  /// Berkas foto selfie masuk (hanya jika `attendanceMethod == 'photo'` dan tipe 'in' / 'inout')
  final XFile? fileIn;

  /// Waktu presensi pulang terencana (format ISO: `yyyy-MM-ddTHH:mm:ss`)
  final String? attendanceOutTime;

  /// Koordinat latitude lokasi pulang
  final double? latitudeOut;

  /// Koordinat longitude lokasi pulang
  final double? longitudeOut;

  /// Alamat lengkap lokasi pulang
  final String? addressOut;

  /// Berkas foto selfie pulang (hanya jika `attendanceMethod == 'photo'` dan tipe 'out' / 'inout')
  final XFile? fileOut;

  const ScheduleAttendanceRequest({
    this.attendanceMethod = 'photo',
    required this.attendanceType,
    required this.reason,
    this.attendanceInTime,
    this.latitudeIn,
    this.longitudeIn,
    this.addressIn,
    this.fileIn,
    this.attendanceOutTime,
    this.latitudeOut,
    this.longitudeOut,
    this.addressOut,
    this.fileOut,
  });

  /// Mengonversi payload ke format Map untuk kebutuhan [FormData.fromMap].
  Future<Map<String, dynamic>> toFormDataMap() async {
    final map = <String, dynamic>{
      'attendanceMethod': attendanceMethod,
      'attendanceType': attendanceType,
      'reason': reason.trim(),
    };

    final hasIn = attendanceType == 'in' || attendanceType == 'inout';
    final hasOut = attendanceType == 'out' || attendanceType == 'inout';

    if (hasIn) {
      if (attendanceInTime != null) {
        map['attendanceInTime'] = attendanceInTime;
      }
      if (latitudeIn != null) {
        map['latitudeIn'] = latitudeIn.toString();
      }
      if (longitudeIn != null) {
        map['longitudeIn'] = longitudeIn.toString();
      }
      if (addressIn != null && addressIn!.trim().isNotEmpty) {
        map['addressIn'] = addressIn!.trim();
      }
      if (fileIn != null && attendanceMethod == 'photo') {
        final fileName = fileIn!.name.isNotEmpty
            ? fileIn!.name
            : fileIn!.path.split(RegExp(r'[/\\]')).last;
        map['fileIn'] = await MultipartFile.fromFile(
          fileIn!.path,
          filename: fileName,
        );
      }
    }

    if (hasOut) {
      if (attendanceOutTime != null) {
        map['attendanceOutTime'] = attendanceOutTime;
      }
      if (latitudeOut != null) {
        map['latitudeOut'] = latitudeOut.toString();
      }
      if (longitudeOut != null) {
        map['longitudeOut'] = longitudeOut.toString();
      }
      if (addressOut != null && addressOut!.trim().isNotEmpty) {
        map['addressOut'] = addressOut!.trim();
      }
      if (fileOut != null && attendanceMethod == 'photo') {
        final fileName = fileOut!.name.isNotEmpty
            ? fileOut!.name
            : fileOut!.path.split(RegExp(r'[/\\]')).last;
        map['fileOut'] = await MultipartFile.fromFile(
          fileOut!.path,
          filename: fileName,
        );
      }
    }

    // Fallback default keys (latitude, longitude, address, file)
    final fallbackLat = latitudeIn ?? latitudeOut;
    final fallbackLng = longitudeIn ?? longitudeOut;
    final fallbackAddr = addressIn ?? addressOut;
    final fallbackFile = fileIn ?? fileOut;

    if (fallbackLat != null) {
      map['latitude'] = fallbackLat.toString();
    }
    if (fallbackLng != null) {
      map['longitude'] = fallbackLng.toString();
    }
    if (fallbackAddr != null && fallbackAddr.trim().isNotEmpty) {
      map['address'] = fallbackAddr.trim();
    }
    if (fallbackFile != null && attendanceMethod == 'photo') {
      final fileName = fallbackFile.name.isNotEmpty
          ? fallbackFile.name
          : fallbackFile.path.split(RegExp(r'[/\\]')).last;
      map['file'] = await MultipartFile.fromFile(
        fallbackFile.path,
        filename: fileName,
      );
    }

    return map;
  }
}
