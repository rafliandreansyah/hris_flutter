import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/datasources/employee_remote_datasource.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';

import '../../helpers/recording_api_client.dart';

Map<String, dynamic> _employeeJson(String id, String first) => {
      'id': id,
      'firstName': first,
      'lastName': 'Test',
      'email': '$first@oasish.com',
      'employeeNumber': 'EMP-$id',
    };

void main() {
  late RecordingApiClient api;
  late EmployeeRemoteDataSourceImpl dataSource;

  setUp(() {
    api = RecordingApiClient();
    dataSource = EmployeeRemoteDataSourceImpl(apiClient: api);
  });

  group('EmployeeRemoteDataSourceImpl', () {
    test('getEmployees hanya mengirim filter yang terisi (di-trim)', () async {
      api.responseData = {
        'success': true,
        'data': [_employeeJson('1', 'Budi')],
        'meta': {'page': 2, 'size': 10, 'total': 1, 'totalPages': 1},
      };

      final result = await dataSource.getEmployees(
        page: 2,
        size: 10,
        companyId: ' c-1 ',
        departmentId: '   ',
        positionId: null,
        search: ' budi ',
      );

      expect(api.last.method, 'GET');
      expect(api.last.path, ApiEndpoints.employee);
      expect(api.last.queryParameters, {
        'page': 2,
        'size': 10,
        'companyId': 'c-1',
        'search': 'budi',
      });
      expect(result.data, hasLength(1));
      expect(result.data.first.name, contains('Budi'));
    });

    test('getEmployees memakai size default 30', () async {
      api.responseData = {'success': true, 'data': []};

      await dataSource.getEmployees(page: 1);

      expect(api.last.queryParameters, {'page': 1, 'size': 30});
    });

    test('getEmployees melempar ApiException bila body bukan Map', () async {
      api.responseData = 'bukan json';

      await expectLater(
        dataSource.getEmployees(page: 1),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal memuat data pegawai.',
          ),
        ),
      );
    });

    test('getEmployeeDetail memanggil /employee/{id} dan mem-parse data', () async {
      api.responseData = {
        'success': true,
        'data': {..._employeeJson('9', 'Sari'), 'status': true},
      };

      final detail = await dataSource.getEmployeeDetail('emp-9');

      expect(api.last.method, 'GET');
      expect(api.last.path, '${ApiEndpoints.employee}/emp-9');
      expect(detail.firstName, 'Sari');
    });

    test('getEmployeeDetail memakai pesan backend bila data tidak valid', () async {
      api.responseData = {'success': false, 'message': 'Pegawai tidak ada'};

      await expectLater(
        dataSource.getEmployeeDetail('x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Pegawai tidak ada',
          ),
        ),
      );
    });

    test('getCoworkers mem-parse list dan mengabaikan elemen non-Map', () async {
      api.responseData = {
        'success': true,
        'data': [_employeeJson('1', 'Ani'), 'sampah', 42],
      };

      final result = await dataSource.getCoworkers();

      expect(api.last.path, ApiEndpoints.employeeCoworkers);
      expect(result, hasLength(1));
    });

    test('getCoworkers melempar ApiException bila data bukan list', () async {
      api.responseData = {'success': true, 'data': 'x'};

      await expectLater(
        dataSource.getCoworkers(),
        throwsA(isA<ApiException>()),
      );
    });

    test('updatePassword mengirim PUT dengan oldPassword & newPassword', () async {
      api.responseData = {'success': true, 'message': 'Password diganti'};

      final message = await dataSource.updatePassword(
        oldPassword: 'lama123',
        newPassword: 'baru456',
      );

      expect(api.last.method, 'PUT');
      expect(api.last.path, ApiEndpoints.employeeUpdatePassword);
      expect(api.last.data, {'oldPassword': 'lama123', 'newPassword': 'baru456'});
      expect(message, 'Password diganti');
    });

    test('updatePassword melempar ApiException berpesan backend saat success=false', () async {
      api.responseData = {'success': false, 'message': 'Password lama salah'};

      await expectLater(
        dataSource.updatePassword(oldPassword: 'x', newPassword: 'y'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Password lama salah',
          ),
        ),
      );
    });

    test('ApiException dari ApiClient diteruskan apa adanya (message + statusCode)', () async {
      api.errorToThrow = const ApiException(
        message: 'Sesi berakhir',
        statusCode: 401,
      );

      await expectLater(
        dataSource.getCoworkers(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Sesi berakhir'),
        ),
      );
    });
  });

  group('EmployeeRepositoryImpl', () {
    late EmployeeRepositoryImpl repository;

    setUp(() {
      repository = EmployeeRepositoryImpl(remoteDataSource: dataSource);
    });

    test('getEmployees meneruskan seluruh parameter ke datasource', () async {
      api.responseData = {'success': true, 'data': []};

      await repository.getEmployees(
        page: 4,
        size: 5,
        companyId: 'c',
        departmentId: 'd',
        positionId: 'p',
        search: 'q',
      );

      expect(api.last.queryParameters, {
        'page': 4,
        'size': 5,
        'companyId': 'c',
        'departmentId': 'd',
        'positionId': 'p',
        'search': 'q',
      });
    });

    test('getEmployeeDetail, getCoworkers, updatePassword didelegasikan', () async {
      api.responseData = {
        'success': true,
        'data': {..._employeeJson('1', 'Lia'), 'status': true},
      };
      expect((await repository.getEmployeeDetail('1')).firstName, 'Lia');

      api.responseData = {'success': true, 'data': []};
      expect(await repository.getCoworkers(), isEmpty);

      api.responseData = {'success': true, 'message': 'OK'};
      expect(
        await repository.updatePassword(oldPassword: 'a', newPassword: 'b'),
        'OK',
      );
    });

    test('error ApiException diteruskan repository', () async {
      api.errorToThrow = const ApiException(message: 'Gagal', statusCode: 500);

      await expectLater(
        repository.getEmployees(page: 1),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}
