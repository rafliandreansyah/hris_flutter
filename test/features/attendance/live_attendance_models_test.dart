import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('LiveAttendanceRequest Tests', () {
    test('toFormDataMap mengonversi request mode photo dengan file multipart', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_selfie.jpg');
      tempFile.writeAsStringSync('dummy-image-content');

      final request = LiveAttendanceRequest(
        attendanceMethod: 'photo',
        latitude: -6.2297,
        longitude: 106.8166,
        attendanceType: 'in',
        file: XFile(tempFile.path),
        address: 'Menara Mandiri, Jl. Jend. Sudirman, Jakarta',
        reason: 'Tugas monitoring lapangan project Alpha',
      );

      final map = await request.toFormDataMap();

      expect(map['attendanceMethod'], 'photo');
      expect(map['latitude'], '-6.2297');
      expect(map['longitude'], '106.8166');
      expect(map['attendanceType'], 'in');
      expect(map['address'], 'Menara Mandiri, Jl. Jend. Sudirman, Jakarta');
      expect(map['reason'], 'Tugas monitoring lapangan project Alpha');
      expect(map.containsKey('file'), isTrue);
      expect(map['file'], isNotNull);

      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('toFormDataMap mengonversi request mode biometric tanpa file foto', () async {
      const request = LiveAttendanceRequest(
        attendanceMethod: 'biometric',
        latitude: -6.2297,
        longitude: 106.8166,
        attendanceType: 'out',
        file: null,
        address: 'Menara Mandiri, Jakarta',
        reason: 'Selesai tugas luar',
      );

      final map = await request.toFormDataMap();

      expect(map['attendanceMethod'], 'biometric');
      expect(map['latitude'], '-6.2297');
      expect(map['longitude'], '106.8166');
      expect(map['attendanceType'], 'out');
      expect(map['address'], 'Menara Mandiri, Jakarta');
      expect(map['reason'], 'Selesai tugas luar');
      expect(map.containsKey('file'), isFalse);
    });
  });

  group('LiveAttendanceResponse & Data Tests', () {
    test('fromJson berhasil mem-parse respons API presensi live backend', () {
      final json = {
        'success': true,
        'message': 'Presensi live berhasil dikirim',
        'data': {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'type': 'live_outside',
          'attendanceType': 'in',
          'attendanceTime': '2026-08-29T23:51:00.000Z',
          'attendanceInTime': '23:51',
          'attendanceOutTime': null,
        },
      };

      final response = LiveAttendanceResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'Presensi live berhasil dikirim');
      expect(response.data, isNotNull);
      expect(response.data!.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(response.data!.type, 'live_outside');
      expect(response.data!.attendanceType, 'in');
      expect(response.data!.attendanceInTime, '23:51');
      expect(response.data!.attendanceOutTime, isNull);

      final outputJson = response.toJson();
      expect(outputJson['success'], isTrue);
      expect(outputJson['data']['id'], '123e4567-e89b-12d3-a456-426614174000');
    });

    test('props Equatable berfungsi konsisten', () {
      const data1 = LiveAttendanceData(id: 'id-1', attendanceType: 'in');
      const data2 = LiveAttendanceData(id: 'id-1', attendanceType: 'in');
      const data3 = LiveAttendanceData(id: 'id-2', attendanceType: 'out');

      expect(data1, equals(data2));
      expect(data1 == data3, isFalse);

      const resp1 = LiveAttendanceResponse(
        success: true,
        message: 'OK',
        data: data1,
      );
      const resp2 = LiveAttendanceResponse(
        success: true,
        message: 'OK',
        data: data2,
      );
      expect(resp1, equals(resp2));
    });
  });
}
