import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';

abstract class EmployeeRepository {
  /// Mengambil daftar pegawai dari backend HRIS.
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  });

  /// Mengambil detail profil lengkap pegawai berdasarkan ID.
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId);
}
