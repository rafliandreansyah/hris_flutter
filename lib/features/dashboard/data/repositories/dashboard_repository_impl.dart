import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;

  DashboardRepositoryImpl({
    DashboardRemoteDataSource? remoteDataSource,
    SecureStorageService? storageService,
  })  : _remoteDataSource =
            remoteDataSource ?? DashboardRemoteDataSourceImpl(),
        _storageService = storageService ?? SecureStorageService.instance;

  @override
  Future<DashboardData> getDashboardData() async {
    final response = await _remoteDataSource.getEmployeeDashboard();
    if (response.success && response.data != null) {
      if (response.data!.id.isNotEmpty) {
        await _storageService.saveEmployeeId(response.data!.id);
      }
      return response.data!;
    } else {
      throw ApiException(
        message: response.message ?? 'Gagal memuat data dashboard karyawan.',
      );
    }
  }

  @override
  Future<List<MenuItemModel>> getMenus() async {
    final response = await _remoteDataSource.getAuthMenus();
    if (response.success) {
      return response.data;
    } else {
      throw ApiException(
        message: response.message ?? 'Gagal memuat menu aplikasi.',
      );
    }
  }
}
