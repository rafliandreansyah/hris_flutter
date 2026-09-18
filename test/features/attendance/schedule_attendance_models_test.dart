import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('ScheduleAttendanceRequest Tests', () {
    test('toFormDataMap mengonversi request type "in" mode photo dengan fileIn multipart', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_schedule_in.jpg');
      tempFile.writeAsStringSync('dummy-image-in');

      final request = ScheduleAttendanceRequest(
        attendanceMethod: 'photo',
        attendanceType: 'in',
        reason: 'Penugasan audit cabang Bandung',
        attendanceInTime: '2026-09-17T08:00:00',
        latitudeIn: -6.914744,
        longitudeIn: 107.609810,
        addressIn: 'Jl. Asia Afrika, Bandung',
        fileIn: XFile(tempFile.path),
      );

      final map = await request.toFormDataMap();

      expect(map['attendanceMethod'], 'photo');
      expect(map['attendanceType'], 'in');
      expect(map['reason'], 'Penugasan audit cabang Bandung');
      expect(map['attendanceInTime'], '2026-09-17T08:00:00');
      expect(map['latitudeIn'], '-6.914744');
      expect(map['longitudeIn'], '107.60981');
      expect(map['addressIn'], 'Jl. Asia Afrika, Bandung');
      expect(map.containsKey('fileIn'), isTrue);
      expect(map['fileIn'], isNotNull);

      // Verifikasi common fallback keys untuk compatibility
      expect(map['latitude'], '-6.914744');
      expect(map['longitude'], '107.60981');
      expect(map['address'], 'Jl. Asia Afrika, Bandung');
      expect(map.containsKey('file'), isTrue);

      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('toFormDataMap mengonversi request type "out" mode biometric tanpa file', () async {
      const request = ScheduleAttendanceRequest(
        attendanceMethod: 'biometric',
        attendanceType: 'out',
        reason: 'Selesai survei lokasi proyek',
        attendanceOutTime: '2026-09-17T17:00:00',
        latitudeOut: -6.200000,
        longitudeOut: 106.816666,
        addressOut: 'Kantor Pusat, Jakarta',
      );

      final map = await request.toFormDataMap();

      expect(map['attendanceMethod'], 'biometric');
      expect(map['attendanceType'], 'out');
      expect(map['reason'], 'Selesai survei lokasi proyek');
      expect(map['attendanceOutTime'], '2026-09-17T17:00:00');
      expect(map['latitudeOut'], '-6.2');
      expect(map['longitudeOut'], '106.816666');
      expect(map['addressOut'], 'Kantor Pusat, Jakarta');
      expect(map.containsKey('fileOut'), isFalse);
      expect(map.containsKey('file'), isFalse);

      // Fallback keys untuk out
      expect(map['latitude'], '-6.2');
      expect(map['longitude'], '106.816666');
      expect(map['address'], 'Kantor Pusat, Jakarta');
    });

    test('toFormDataMap mengonversi request type "inout" mode photo dengan fileIn & fileOut', () async {
      final tempFileIn = File('${Directory.systemTemp.path}/test_sched_in.jpg');
      tempFileIn.writeAsStringSync('dummy-in');
      final tempFileOut = File('${Directory.systemTemp.path}/test_sched_out.jpg');
      tempFileOut.writeAsStringSync('dummy-out');

      final request = ScheduleAttendanceRequest(
        attendanceMethod: 'photo',
        attendanceType: 'inout',
        reason: 'Dinas harian full day di site Cilegon',
        attendanceInTime: '2026-09-17T08:00:00',
        latitudeIn: -6.012345,
        longitudeIn: 106.012345,
        addressIn: 'Site Cilegon Gerbang Utama',
        fileIn: XFile(tempFileIn.path),
        attendanceOutTime: '2026-09-17T17:00:00',
        latitudeOut: -6.012345,
        longitudeOut: 106.012345,
        addressOut: 'Site Cilegon Gerbang Utama',
        fileOut: XFile(tempFileOut.path),
      );

      final map = await request.toFormDataMap();

      expect(map['attendanceMethod'], 'photo');
      expect(map['attendanceType'], 'inout');
      expect(map['reason'], 'Dinas harian full day di site Cilegon');
      expect(map['attendanceInTime'], '2026-09-17T08:00:00');
      expect(map['attendanceOutTime'], '2026-09-17T17:00:00');
      expect(map['latitudeIn'], '-6.012345');
      expect(map['longitudeIn'], '106.012345');
      expect(map['addressIn'], 'Site Cilegon Gerbang Utama');
      expect(map.containsKey('fileIn'), isTrue);
      expect(map['latitudeOut'], '-6.012345');
      expect(map['longitudeOut'], '106.012345');
      expect(map['addressOut'], 'Site Cilegon Gerbang Utama');
      expect(map.containsKey('fileOut'), isTrue);

      if (tempFileIn.existsSync()) tempFileIn.deleteSync();
      if (tempFileOut.existsSync()) tempFileOut.deleteSync();
    });
  });

  group('ScheduleAttendanceResponse & Data Tests', () {
    test('fromJson mem-parse respons API presensi schedule backend dengan sukses', () {
      final json = {
        'success': true,
        'message': 'Pengajuan presensi terjadwal berhasil dibuat.',
        'data': {
          'id': 'sched-uuid-456',
          'type': 'schedule_outside',
          'attendanceType': 'inout',
          'attendanceInTime': '08:00',
          'attendanceOutTime': '17:00',
          'latitudeIn': -6.200000,
          'longitudeIn': 106.816666,
          'addressIn': 'Kantor Cabang',
          'latitudeOut': -6.200000,
          'longitudeOut': 106.816666,
          'addressOut': 'Kantor Cabang',
          'reason': 'Lupa absen kemarin',
          'status': 'PENDING',
        },
      };

      final response = ScheduleAttendanceResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'Pengajuan presensi terjadwal berhasil dibuat.');
      expect(response.data, isNotNull);
      expect(response.data!.id, 'sched-uuid-456');
      expect(response.data!.type, 'schedule_outside');
      expect(response.data!.attendanceType, 'inout');
      expect(response.data!.attendanceInTime, '08:00');
      expect(response.data!.attendanceOutTime, '17:00');
      expect(response.data!.status, 'PENDING');

      final outputJson = response.toJson();
      expect(outputJson['success'], isTrue);
      expect(outputJson['data']['id'], 'sched-uuid-456');
      expect(outputJson['data']['status'], 'PENDING');
    });

    test('ScheduleAttendanceData props Equatable konsisten', () {
      const data1 = ScheduleAttendanceData(id: 'id-1', attendanceType: 'in');
      const data2 = ScheduleAttendanceData(id: 'id-1', attendanceType: 'in');
      const data3 = ScheduleAttendanceData(id: 'id-2', attendanceType: 'out');

      expect(data1, equals(data2));
      expect(data1 == data3, isFalse);
    });
  });
}
