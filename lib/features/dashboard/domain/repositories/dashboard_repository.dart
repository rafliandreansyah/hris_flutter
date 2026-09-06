import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';

/// Kontrak repositori untuk mengambil data Dashboard dan Menu.
abstract class DashboardRepository {
  /// Mengambil data dashboard karyawan (/employee/dashboard)
  Future<DashboardData> getDashboardData();

  /// Mengambil daftar menu aktif (/auth/menus)
  Future<List<MenuItemModel>> getMenus();
}
