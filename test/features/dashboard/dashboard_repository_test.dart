import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/repositories/dashboard_repository_impl.dart';

class _MockDashboardRemoteDataSource implements DashboardRemoteDataSource {
  DashboardResponseModel? mockDashboardResponse;
  MenuResponseModel? mockMenuResponse;
  bool shouldThrow = false;
  ApiException? errorToThrow;

  @override
  Future<DashboardResponseModel> getEmployeeDashboard() async {
    if (shouldThrow) {
      throw errorToThrow ??
          const ApiException(message: 'Remote error', statusCode: 500);
    }
    return mockDashboardResponse!;
  }

  @override
  Future<MenuResponseModel> getAuthMenus() async {
    if (shouldThrow) {
      throw errorToThrow ??
          const ApiException(message: 'Remote error', statusCode: 500);
    }
    return mockMenuResponse!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardRepositoryImpl Tests', () {
    late _MockDashboardRemoteDataSource mockRemoteDataSource;
    late SecureStorageService storageService;
    late DashboardRepositoryImpl repository;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      mockRemoteDataSource = _MockDashboardRemoteDataSource();
      storageService = SecureStorageService.withStorage(const FlutterSecureStorage());
      repository = DashboardRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        storageService: storageService,
      );
    });

    test('getDashboardData saves employeeId and returns data on success', () async {
      mockRemoteDataSource.mockDashboardResponse = const DashboardResponseModel(
        success: true,
        message: 'Success',
        data: DashboardData(
          id: 'emp-uuid-777',
          firstName: 'Siti',
          email: 'siti@example.com',
          timeServer: '2026-09-06T08:00:00.000Z',
        ),
      );

      final result = await repository.getDashboardData();

      expect(result.id, equals('emp-uuid-777'));
      expect(result.firstName, equals('Siti'));
      expect(await storageService.getEmployeeId(), equals('emp-uuid-777'));
    });

    test('getDashboardData does not save employeeId when id is empty', () async {
      mockRemoteDataSource.mockDashboardResponse = const DashboardResponseModel(
        success: true,
        message: 'Success',
        data: DashboardData(
          id: '',
          firstName: 'Guest',
          email: 'guest@example.com',
        ),
      );

      final result = await repository.getDashboardData();

      expect(result.firstName, equals('Guest'));
      expect(await storageService.getEmployeeId(), isNull);
    });

    test('getDashboardData throws ApiException when success is false', () async {
      mockRemoteDataSource.mockDashboardResponse = const DashboardResponseModel(
        success: false,
        message: 'Profil karyawan tidak ditemukan',
        data: null,
      );

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Profil karyawan tidak ditemukan',
          ),
        ),
      );
      expect(await storageService.getEmployeeId(), isNull);
    });

    test('getDashboardData throws fallback ApiException when message is null', () async {
      mockRemoteDataSource.mockDashboardResponse = const DashboardResponseModel(
        success: false,
        message: null,
        data: null,
      );

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal memuat data dashboard karyawan.',
          ),
        ),
      );
    });

    test('getDashboardData propagates ApiException when datasource fails', () async {
      mockRemoteDataSource.shouldThrow = true;
      mockRemoteDataSource.errorToThrow =
          const ApiException(message: 'Koneksi terputus', statusCode: 503);

      expect(
        () => repository.getDashboardData(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Koneksi terputus',
          ),
        ),
      );
    });

    test('getMenus returns list of menu items on success', () async {
      mockRemoteDataSource.mockMenuResponse = const MenuResponseModel(
        success: true,
        message: 'OK',
        data: [
          MenuItemModel(id: 'm1', name: 'Aktivitas', code: 'mobile_activity'),
          MenuItemModel(id: 'm2', name: 'Lembur', code: 'mobile_overtime'),
        ],
      );

      final result = await repository.getMenus();

      expect(result.length, equals(2));
      expect(result[0].name, equals('Aktivitas'));
      expect(result[1].code, equals('mobile_overtime'));
    });

    test('getMenus throws ApiException when success is false', () async {
      mockRemoteDataSource.mockMenuResponse = const MenuResponseModel(
        success: false,
        message: 'Gagal mendapatkan hak akses menu',
        data: [],
      );

      expect(
        () => repository.getMenus(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal mendapatkan hak akses menu',
          ),
        ),
      );
    });

    test('getMenus propagates ApiException when datasource fails', () async {
      mockRemoteDataSource.shouldThrow = true;
      mockRemoteDataSource.errorToThrow =
          const ApiException(message: 'Server error', statusCode: 500);

      expect(
        () => repository.getMenus(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ),
      );
    });
  });
}
