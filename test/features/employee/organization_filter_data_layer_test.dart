import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/datasources/organization_filter_remote_datasource.dart';
import 'package:hris_flutter/features/employee/data/repositories/organization_filter_repository_impl.dart';

import '../../helpers/recording_api_client.dart';

void main() {
  late RecordingApiClient api;
  late OrganizationFilterRemoteDataSourceImpl dataSource;

  setUp(() {
    api = RecordingApiClient();
    dataSource = OrganizationFilterRemoteDataSourceImpl(apiClient: api);
  });

  group('OrganizationFilterRemoteDataSourceImpl', () {
    test('getCompanies tanpa search mengirim query null', () async {
      api.responseData = {
        'data': [
          {'id': 'c1', 'name': 'PT A'},
        ],
      };

      final result = await dataSource.getCompanies();

      expect(api.last.method, 'GET');
      expect(api.last.path, ApiEndpoints.companies);
      expect(api.last.queryParameters, isNull);
      expect(result.single.name, 'PT A');
    });

    test('getCompanies dengan search mengirim query ter-trim', () async {
      api.responseData = {'data': []};

      await dataSource.getCompanies(search: '  oasis ');

      expect(api.last.queryParameters, {'search': 'oasis'});
    });

    test('getDepartments mengirim companyId & search yang terisi saja', () async {
      api.responseData = {
        'data': [
          {'id': 'd1', 'name': 'Finance'},
        ],
      };

      final result = await dataSource.getDepartments(
        companyId: 'c1',
        search: ' ',
      );

      expect(api.last.path, ApiEndpoints.departments);
      expect(api.last.queryParameters, {'companyId': 'c1'});
      expect(result.single.name, 'Finance');
    });

    test('getPositions mengirim company, department, search', () async {
      api.responseData = {
        'data': [
          {'id': 'p1', 'name': 'Staff'},
        ],
      };

      final result = await dataSource.getPositions(
        companyId: 'c1',
        departmentId: 'd1',
        search: 'sta',
      );

      expect(api.last.path, ApiEndpoints.positions);
      expect(api.last.queryParameters, {
        'companyId': 'c1',
        'departmentId': 'd1',
        'search': 'sta',
      });
      expect(result.single.name, 'Staff');
    });

    test('respons tanpa list melempar ApiException berpesan spesifik', () async {
      api.responseData = {'message': 'oops'};
      await expectLater(
        dataSource.getCompanies(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'oops')),
      );

      api.responseData = null;
      await expectLater(
        dataSource.getDepartments(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal memuat data departemen.',
          ),
        ),
      );
      await expectLater(
        dataSource.getPositions(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal memuat data jabatan.',
          ),
        ),
      );
    });

    test('ApiException (mis. 403) dari ApiClient diteruskan utuh', () async {
      api.errorToThrow = const ApiException(message: 'Terlarang', statusCode: 403);

      await expectLater(
        dataSource.getCompanies(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Terlarang'),
        ),
      );
    });
  });

  group('OrganizationFilterRepositoryImpl', () {
    test('meneruskan parameter ke datasource', () async {
      final repository = OrganizationFilterRepositoryImpl(remoteDataSource: dataSource);
      api.responseData = {'data': []};

      await repository.getCompanies(search: 'a');
      expect(api.last.queryParameters, {'search': 'a'});

      await repository.getDepartments(companyId: 'c', search: 'b');
      expect(api.last.queryParameters, {'companyId': 'c', 'search': 'b'});

      await repository.getPositions(companyId: 'c', departmentId: 'd', search: 'e');
      expect(api.last.queryParameters, {
        'companyId': 'c',
        'departmentId': 'd',
        'search': 'e',
      });
    });
  });
}
