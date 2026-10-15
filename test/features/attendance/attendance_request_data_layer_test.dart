import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/datasources/attendance_request_remote_datasource.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_request_repository_impl.dart';

import '../../helpers/recording_api_client.dart';

void main() {
  late RecordingApiClient api;
  late AttendanceRequestRemoteDataSourceImpl dataSource;

  setUp(() {
    api = RecordingApiClient();
    dataSource = AttendanceRequestRemoteDataSourceImpl(apiClient: api);
  });

  group('AttendanceRequestRemoteDataSourceImpl.getAttendanceRequests', () {
    test('default: status requested, approver=false, tanpa filter kosong', () async {
      api.responseData = {'success': true, 'data': []};

      await dataSource.getAttendanceRequests(page: 1, size: 20);

      expect(api.last.method, 'GET');
      expect(api.last.path, ApiEndpoints.attendanceRequests);
      expect(api.last.queryParameters, {
        'page': 1,
        'size': 20,
        'approver': false,
        'status': 'requested',
      });
    });

    test('status "all" dipertahankan, filter di-trim, approver=true', () async {
      api.responseData = {'success': true, 'data': []};

      await dataSource.getAttendanceRequests(
        page: 2,
        size: 10,
        companyId: ' c1 ',
        departmentId: 'd1',
        positionId: '   ',
        search: ' budi ',
        status: 'all',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        approver: true,
      );

      expect(api.last.queryParameters, {
        'page': 2,
        'size': 10,
        'approver': true,
        'companyId': 'c1',
        'departmentId': 'd1',
        'search': 'budi',
        'status': 'all',
        'startDate': '2026-10-01',
        'endDate': '2026-10-31',
      });
    });

    test('status spesifik diteruskan ter-trim', () async {
      api.responseData = {'success': true, 'data': []};

      await dataSource.getAttendanceRequests(
        page: 1,
        size: 5,
        status: ' approved ',
      );

      expect(api.last.queryParameters!['status'], 'approved');
    });

    test('body bukan Map melempar ApiException', () async {
      api.responseData = 'rusak';

      await expectLater(
        dataSource.getAttendanceRequests(page: 1, size: 5),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal memuat data pengajuan presensi.',
          ),
        ),
      );
    });

    test('ApiException 403 dari ApiClient diteruskan dengan pesan backend', () async {
      api.errorToThrow = const ApiException(
        message: 'Bukan approver',
        statusCode: 403,
      );

      await expectLater(
        dataSource.getAttendanceRequests(page: 1, size: 5, approver: true),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Bukan approver'),
        ),
      );
    });
  });

  group('AttendanceRequestRemoteDataSourceImpl detail / approve / delete', () {
    test('getAttendanceRequestDetail memanggil endpoint detail', () async {
      api.responseData = 'rusak';

      await expectLater(
        dataSource.getAttendanceRequestDetail('req-1'),
        throwsA(isA<ApiException>()),
      );

      expect(api.last.method, 'GET');
      expect(api.last.path, ApiEndpoints.attendanceRequestDetail('req-1'));
    });

    test('approveAttendanceRequest mengirim PATCH + catatan ter-trim', () async {
      api.responseData = {'success': true};

      await dataSource.approveAttendanceRequest(
        id: 'req-1',
        isApproved: true,
        approverNotes: '  Disetujui  ',
      );

      expect(api.last.method, 'PATCH');
      expect(api.last.path, ApiEndpoints.attendanceRequestApprove('req-1'));
      expect(api.last.data, {'isApproved': true, 'approverNotes': 'Disetujui'});
    });

    test('approveAttendanceRequest tidak mengirim approverNotes bila kosong', () async {
      api.responseData = {'success': true};

      await dataSource.approveAttendanceRequest(
        id: 'req-2',
        isApproved: false,
        approverNotes: '   ',
      );
      expect(api.last.data, {'isApproved': false});

      await dataSource.approveAttendanceRequest(id: 'req-2', isApproved: false);
      expect(api.last.data, {'isApproved': false});
    });

    test('deleteAttendanceRequest mengirim DELETE ke endpoint detail', () async {
      api.responseData = {'success': true};

      await dataSource.deleteAttendanceRequest('req-3');

      expect(api.last.method, 'DELETE');
      expect(api.last.path, ApiEndpoints.attendanceRequestDetail('req-3'));
    });

    test('error 404 pada delete diteruskan (message + statusCode)', () async {
      api.errorToThrow = const ApiException(
        message: 'Pengajuan tidak ditemukan',
        statusCode: 404,
      );

      await expectLater(
        dataSource.deleteAttendanceRequest('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Pengajuan tidak ditemukan'),
        ),
      );
    });
  });

  group('AttendanceRequestRepositoryImpl', () {
    late AttendanceRequestRepositoryImpl repository;

    setUp(() {
      repository = AttendanceRequestRepositoryImpl(remoteDataSource: dataSource);
    });

    test('getAttendanceRequests meneruskan filter & approver', () async {
      api.responseData = {'success': true, 'data': []};

      await repository.getAttendanceRequests(
        page: 3,
        size: 15,
        companyId: 'c',
        status: 'all',
        approver: true,
      );

      expect(api.last.queryParameters, {
        'page': 3,
        'size': 15,
        'approver': true,
        'companyId': 'c',
        'status': 'all',
      });
    });

    test('approve & delete didelegasikan dengan argumen yang sama', () async {
      api.responseData = {'success': true};

      await repository.approveAttendanceRequest(
        id: 'r1',
        isApproved: true,
        approverNotes: 'ok',
      );
      expect(api.last.path, ApiEndpoints.attendanceRequestApprove('r1'));
      expect(api.last.data, {'isApproved': true, 'approverNotes': 'ok'});

      await repository.deleteAttendanceRequest('r1');
      expect(api.last.method, 'DELETE');
    });
  });
}
