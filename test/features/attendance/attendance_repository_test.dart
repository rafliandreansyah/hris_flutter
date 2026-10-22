import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

class _MockAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  Map<String, dynamic>? mockAttendanceInfo;
  Map<String, dynamic>? mockDashboardAttendance;
  CreateAttendanceResponse? mockCreateResponse;
  AttendanceLogListResponse? mockLogsResponse;
  List<EmployeeDirectoryItem>? mockEmployees;
  AttendanceDetailModel? mockDetail;
  Map<String, dynamic>? mockDefaultWorkLocationResponse;
  Map<String, dynamic>? mockBreakToday;
  final List<({bool isStart, Map<String, dynamic> payload})> breakSubmissions = [];

  CreateAttendanceRequest? lastRecordedRequest;
  bool shouldThrow = false;
  ApiException? errorToThrow;

  @override
  Future<Map<String, dynamic>> fetchAttendanceInfo() async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockAttendanceInfo ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchBreakToday() async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockBreakToday ?? {};
  }

  @override
  Future<Map<String, dynamic>> submitBreak({
    required bool isStart,
    required Map<String, dynamic> payload,
  }) async {
    breakSubmissions.add((isStart: isStart, payload: payload));
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> fetchDashboardAttendance() async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockDashboardAttendance ?? {};
  }

  @override
  Future<CreateAttendanceResponse> recordAttendance(CreateAttendanceRequest request) async {
    lastRecordedRequest = request;
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockCreateResponse ??
        const CreateAttendanceResponse(
          success: true,
          message: 'Success',
        );
  }



  @override
  Future<AttendanceLogListResponse> getAttendanceLogs({
    String? employeeId,
    bool lastMonth = false,
    int page = 1,
    int size = 20,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  }) async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockLogsResponse ??
        const AttendanceLogListResponse(
          success: true,
          message: 'Success',
          data: [],
          meta: AttendanceLogPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
        );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockEmployees ?? [];
  }


  @override
  Future<AttendanceDetailModel> getAttendanceDetail(String id) async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockDetail ??
        AttendanceDetailModel(
          id: id,
          attendanceType: 'in',
          attendanceMethod: 'photo',
        );
  }

  @override
  Future<Map<String, dynamic>> setDefaultWorkLocation({
    String? workLocationId,
    String? employeeWorkLocationId,
  }) async {
    if (shouldThrow) throw errorToThrow ?? const ApiException(message: 'Error');
    return mockDefaultWorkLocationResponse ?? {'success': true, 'message': 'OK'};
  }
}

void main() {
  group('AttendanceRepositoryImpl Tests', () {
    late _MockAttendanceRemoteDataSource mockDataSource;
    late AttendanceRepositoryImpl repository;

    setUp(() {
      mockDataSource = _MockAttendanceRemoteDataSource();
      repository = AttendanceRepositoryImpl(remoteDataSource: mockDataSource);
    });

    test('getTodayAttendance parses complete payload with work location, schedule, and shift', () async {
      mockDataSource.mockAttendanceInfo = {
        'success': true,
        'data': {
          'firstName': 'Budi',
          'lastName': 'Santoso',
          'employeeNumber': 'EMP-001',
          'timezone': 'Asia/Jakarta',
          'timeServer': '2026-10-13T08:00:00Z',
          'position': {'name': 'Senior Engineer'},
          'company': {'name': 'PT Tech Nusantara'},
          'department': {'name': 'Engineering'},
          'todaySchedule': {
            'shift': {
              'name': 'Pagi',
              'startTime': '08:00:00',
              'endTime': '17:00:00',
              'isFlexibleTime': false,
            },
          },
          'employeeWorkLocation': [
            {
              'id': 'ewl-1',
              'isDefault': true,
              'workLocation': {
                'id': 'loc-1',
                'name': 'Kantor Pusat',
                'address': 'Jl. Sudirman No. 1',
                'latitude': -6.2088,
                'longitude': 106.8456,
                'radius': 100.0,
                'isAnyWhere': false,
              },
            }
          ],
          'attendanceSummary': {
            'todayAttendance': {
              'id': 'att-today-1',
              'inTime': '07:55:00',
              'outTime': null,
              'isOnBreak': false,
            },
          },
        },
      };

      final result = await repository.getTodayAttendance();

      expect(result.employeeName, equals('Budi Santoso'));
      expect(result.employeeRole, equals('Senior Engineer'));
      expect(result.employeeId, equals('EMP-001'));
      expect(result.companyName, equals('PT Tech Nusantara'));
      expect(result.departmentName, equals('Engineering'));
      expect(result.officeName, equals('Kantor Pusat'));
      expect(result.officeLatitude, equals(-6.2088));
      expect(result.officeLongitude, equals(106.8456));
      expect(result.geofenceRadiusMeters, equals(100.0));
      expect(result.inTime, equals('07:55'));
      expect(result.outTime, isNull);
      expect(result.hasSchedule, isTrue);
    });

    test('getTodayAttendance handles isAnyWhere work location', () async {
      mockDataSource.mockAttendanceInfo = {
        'success': true,
        'data': {
          'firstName': 'Rina',
          'employeeNumber': 'EMP-002',
          'employeeWorkLocation': [
            {
              'id': 'ewl-2',
              'isDefault': true,
              'workLocation': {
                'id': 'loc-any',
                'name': 'Work From Anywhere',
                'address': 'Fleksibel',
                'isAnyWhere': true,
              },
            }
          ],
        },
      };

      final result = await repository.getTodayAttendance();

      expect(result.officeName, equals('Work From Anywhere'));
      expect(result.isInsideGeofence, isTrue);
      expect(result.geofenceRadiusMeters, equals(0.0));
    });

    test('getTodayAttendance throws 404 ApiException when data is null', () async {
      mockDataSource.mockAttendanceInfo = {
        'success': false,
        'data': null,
        'message': 'Jadwal kerja tidak ditemukan',
      };

      expect(
        () => repository.getTodayAttendance(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Jadwal kerja tidak ditemukan')),
      );
    });

    test('clockIn records attendance with attendanceType in', () async {
      mockDataSource.mockAttendanceInfo = {
        'success': true,
        'data': {
          'firstName': 'Budi',
          'employeeWorkLocation': [
            {
              'id': 'ewl-1',
              'isDefault': true,
              'workLocation': {
                'id': 'loc-1',
                'name': 'HQ',
                'latitude': -6.2088,
                'longitude': 106.8456,
              },
            }
          ],
        },
      };

      await repository.clockIn(
        latitude: -6.2088,
        longitude: 106.8456,
        workLocationId: 'loc-1',
      );

      expect(mockDataSource.lastRecordedRequest?.attendanceType, equals('in'));
      expect(mockDataSource.lastRecordedRequest?.workLocationId, equals('loc-1'));
    });

    group('alamat presensi mengikuti lokasi kerja', () {
      Map<String, dynamic> infoWith(Map<String, dynamic> workLocation) => {
            'success': true,
            'data': {
              'firstName': 'Budi',
              'employeeWorkLocation': [
                {'id': 'ewl-1', 'isDefault': true, 'workLocation': workLocation},
              ],
            },
          };

      test('mengirim alamat lokasi kerja bila tersedia', () async {
        mockDataSource.mockAttendanceInfo = infoWith({
          'id': 'loc-1',
          'name': 'HQ',
          'address': 'Jl. Sudirman No. 1',
          'latitude': -6.2,
          'longitude': 106.8,
        });

        await repository.clockIn(latitude: -6.2, longitude: 106.8, workLocationId: 'loc-1');

        expect(mockDataSource.lastRecordedRequest?.address, 'Jl. Sudirman No. 1');
      });

      test('mengirim nama lokasi kerja bila alamat kosong', () async {
        mockDataSource.mockAttendanceInfo = infoWith({
          'id': 'loc-1',
          'name': 'HQ',
          'address': '',
          'latitude': -6.2,
          'longitude': 106.8,
        });

        await repository.clockOut(latitude: -6.2, longitude: 106.8, workLocationId: 'loc-1');

        expect(mockDataSource.lastRecordedRequest?.address, 'HQ');
      });

      test('absen di mana saja memakai alamat hasil reverse geocoding (Mapbox)', () async {
        double? geoLat;
        repository = AttendanceRepositoryImpl(
          remoteDataSource: mockDataSource,
          addressFetcher: ({required latitude, required longitude}) async {
            geoLat = latitude;
            return 'Jl. Braga, Bandung';
          },
        );
        mockDataSource.mockAttendanceInfo = infoWith({
          'id': 'loc-any',
          'name': 'Work From Anywhere',
          'address': 'Fleksibel',
          'isAnyWhere': true,
        });

        await repository.clockIn(latitude: -6.91, longitude: 107.6, workLocationId: 'loc-any');

        expect(geoLat, -6.91);
        expect(mockDataSource.lastRecordedRequest?.address, 'Jl. Braga, Bandung');
      });
    });

    test('clockOut records attendance with attendanceType out', () async {
      mockDataSource.mockAttendanceInfo = {
        'success': true,
        'data': {
          'firstName': 'Budi',
          'employeeWorkLocation': [
            {
              'id': 'ewl-1',
              'isDefault': true,
              'workLocation': {
                'id': 'loc-1',
                'name': 'HQ',
                'latitude': -6.2088,
                'longitude': 106.8456,
              },
            }
          ],
        },
      };

      await repository.clockOut(
        latitude: -6.2088,
        longitude: 106.8456,
        workLocationId: 'loc-1',
      );

      expect(mockDataSource.lastRecordedRequest?.attendanceType, equals('out'));
    });

    group('istirahat (break)', () {
      const todayJson = {
        'success': true,
        'data': {
          'attendanceId': 'att-1',
          'isOnBreak': true,
          'activeBreak': {
            'id': 'b-2',
            'attendanceId': 'att-1',
            'startTime': '2026-10-15T12:30:00+07:00',
            'endTime': null,
            'durationMinutes': null,
          },
          'totalBreakMinutes': 20,
          'overbreakMinutes': 0,
          'allocatedBreakMinutes': 60,
          'isFlexibleBreak': false,
          'breaks': [
            {
              'id': 'b-1',
              'attendanceId': 'att-1',
              'startTime': '2026-10-15T10:00:00+07:00',
              'endTime': '2026-10-15T10:20:00+07:00',
              'durationMinutes': 20,
              'note': 'ngopi',
            },
            {
              'id': 'b-2',
              'attendanceId': 'att-1',
              'startTime': '2026-10-15T12:30:00+07:00',
              'endTime': null,
              'durationMinutes': null,
            },
          ],
        },
      };

      test('getBreakStatus mem-parse sesi, jatah, dan sesi aktif', () async {
        mockDataSource.mockBreakToday = Map<String, dynamic>.from(todayJson);

        final status = await repository.getBreakStatus();

        expect(status.attendanceId, 'att-1');
        expect(status.isOnBreak, isTrue);
        expect(status.activeBreak?.id, 'b-2');
        expect(status.activeBreak?.isOngoing, isTrue);
        expect(status.allocatedBreakMinutes, 60);
        expect(status.totalBreakMinutes, 20);
        expect(status.breaks, hasLength(2));
        expect(status.breaks.first.note, 'ngopi');
        expect(status.breaks.first.durationMinutes, 20);
      });

      test('getBreakStatus tanpa data mengembalikan status kosong', () async {
        mockDataSource.mockBreakToday = {'success': true, 'data': null};

        final status = await repository.getBreakStatus();

        expect(status.isOnBreak, isFalse);
        expect(status.breaks, isEmpty);
      });

      test('startBreak mengirim payload bersih lalu mengembalikan status terbaru', () async {
        mockDataSource.mockBreakToday = Map<String, dynamic>.from(todayJson);

        final status = await repository.startBreak(
          attendanceId: 'att-1',
          latitude: -6.2,
          longitude: 106.8,
          note: '  makan siang ',
          address: '   ',
          workLocationId: 'wl-1',
        );

        final sent = mockDataSource.breakSubmissions.single;
        expect(sent.isStart, isTrue);
        expect(sent.payload, {
          'attendanceId': 'att-1',
          'latitude': -6.2,
          'longitude': 106.8,
          'note': 'makan siang',
          'workLocationId': 'wl-1',
        });
        expect(status.isOnBreak, isTrue);
      });

      test('endBreak memanggil endpoint selesai dan tidak mengirim field kosong', () async {
        mockDataSource.mockBreakToday = {
          'success': true,
          'data': {'isOnBreak': false, 'totalBreakMinutes': 45},
        };

        final status = await repository.endBreak(
          attendanceId: 'att-1',
          latitude: -6.2,
          longitude: 106.8,
        );

        final sent = mockDataSource.breakSubmissions.single;
        expect(sent.isStart, isFalse);
        expect(sent.payload.keys, unorderedEquals(['attendanceId', 'latitude', 'longitude']));
        expect(status.isOnBreak, isFalse);
        expect(status.totalBreakMinutes, 45);
      });

      test('ApiException (pesan + statusCode) diteruskan saat start gagal', () async {
        mockDataSource.shouldThrow = true;
        mockDataSource.errorToThrow = const ApiException(
          message: 'Anda sudah dalam sesi istirahat',
          statusCode: 400,
        );

        await expectLater(
          repository.startBreak(attendanceId: 'att-1', latitude: 1, longitude: 2),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 400)
                .having((e) => e.message, 'message', 'Anda sudah dalam sesi istirahat'),
          ),
        );
      });
    });

    test('getAttendanceLogs enriches missing timezones with fallback', () async {
      mockDataSource.mockAttendanceInfo = {
        'success': true,
        'data': {'timezone': 'Asia/Makassar'},
      };
      await repository.getTodayAttendance();

      mockDataSource.mockLogsResponse = AttendanceLogListResponse(
        success: true,
        message: 'Success',
        data: [
          AttendanceLogItem(
            id: 'log-1',
            date: '2026-10-13',
            dateTime: DateTime(2026, 10, 13, 8, 0),
            type: AttendanceLogType.clockIn,
            timezone: null,
          ),
        ],
        meta: const AttendanceLogPaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1),
      );

      final result = await repository.getAttendanceLogs();

      expect(result.data.first.timezone, equals('Asia/Makassar'));
    });

    test('setDefaultWorkLocation returns backend message on success', () async {
      mockDataSource.mockDefaultWorkLocationResponse = {
        'success': true,
        'message': 'Lokasi kantor baru berhasil ditetapkan',
      };

      final msg = await repository.setDefaultWorkLocation(workLocationId: 'loc-new');
      expect(msg, equals('Lokasi kantor baru berhasil ditetapkan'));
    });
  });
}
