import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/features/employee/data/datasources/employee_remote_datasource.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';

/// Pemilih pegawai untuk melihat jadwal kerja pegawai lain.
///
/// Memakai komponen yang sama dengan daftar pegawai ([EmployeeDirectoryScreen]),
/// tetapi data diambil dari `/employee/work-schedule/employees` yang dijaga
/// permission `work_schedule.view` (403 bila tidak memiliki hak akses).
class EmployeeScheduleSelectScreen extends StatelessWidget {
  final EmployeeRepository? repository;

  const EmployeeScheduleSelectScreen({super.key, this.repository});

  void _selectEmployee(BuildContext context, EmployeeDirectoryItem emp) {
    FocusManager.instance.primaryFocus?.unfocus();

    final preview = WorkScheduleEmployee(
      id: emp.id,
      firstName: emp.firstName ?? emp.name,
      lastName: emp.lastName,
      email: emp.email,
      phone: emp.phone,
      photoUrl: emp.avatarUrl,
      employeeNumber: emp.employeeNumber,
      idNumber: emp.idNumber,
      companyName: emp.company,
      departmentName: emp.department,
      positionName: emp.role,
    );

    context.push(
      '${Routes.WORK_SCHEDULE}?employeeId=${emp.id}',
      extra: preview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeDirectoryScreen(
      employeeRepository: repository ??
          EmployeeRepositoryImpl(
            remoteDataSource: EmployeeRemoteDataSourceImpl(
              listEndpoint: ApiEndpoints.employeeWorkScheduleEmployees,
            ),
          ),
      title: 'Jadwal Pegawai',
      subtitle: 'Pilih pegawai untuk melihat jadwal kerja',
      onEmployeeTap: (emp) => _selectEmployee(context, emp),
    );
  }
}
