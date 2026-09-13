import 'package:image_picker/image_picker.dart';

/// Model permintaan (request payload) untuk API pembuatan absensi `POST /attendances`.
class CreateAttendanceRequest {
  final String workLocationId;
  final String attendanceMethod; // 'photo' | 'biometric'
  final double latitude;
  final double longitude;
  final String attendanceType; // 'in' | 'out'
  final String? address;
  final XFile? file;

  const CreateAttendanceRequest({
    required this.workLocationId,
    required this.attendanceMethod,
    required this.latitude,
    required this.longitude,
    required this.attendanceType,
    this.address,
    this.file,
  });

  Map<String, dynamic> toFormDataMap() {
    final map = <String, dynamic>{
      'workLocationId': workLocationId,
      'attendanceMethod': attendanceMethod,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'attendanceType': attendanceType,
    };
    if (address != null && address!.trim().isNotEmpty) {
      map['address'] = address!.trim();
    }
    return map;
  }
}
