import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';

/// Kriteria filter untuk pengajuan presensi luar kantor.
class AttendanceRequestFilterCriteria extends Equatable {
  final DateTimeRange? dateRange;
  final String? companyId;
  final String? company;
  final String? departmentId;
  final String? department;
  final String? positionId;
  final String? position;

  /// Filter status: 'requested' (default), 'approved', 'rejected', 'all'.
  final String status;

  const AttendanceRequestFilterCriteria({
    this.dateRange,
    this.companyId,
    this.company,
    this.departmentId,
    this.department,
    this.positionId,
    this.position,
    this.status = 'requested',
  });

  bool get hasActiveFilter =>
      dateRange != null ||
      (company != null && company != 'Semua Perusahaan') ||
      (companyId != null && companyId!.isNotEmpty) ||
      (department != null && department != 'Semua Departemen') ||
      (departmentId != null && departmentId!.isNotEmpty) ||
      (position != null && position != 'Semua Jabatan') ||
      (positionId != null && positionId!.isNotEmpty) ||
      (status.isNotEmpty && status != 'requested');

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if ((company != null && company != 'Semua Perusahaan') ||
        (companyId != null && companyId!.isNotEmpty)) {
      count++;
    }
    if ((department != null && department != 'Semua Departemen') ||
        (departmentId != null && departmentId!.isNotEmpty)) {
      count++;
    }
    if ((position != null && position != 'Semua Jabatan') ||
        (positionId != null && positionId!.isNotEmpty)) {
      count++;
    }
    if (status.isNotEmpty && status != 'requested') {
      count++;
    }
    return count;
  }

  AttendanceRequestFilterCriteria copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? companyId,
    String? company,
    String? departmentId,
    String? department,
    String? positionId,
    String? position,
    String? status,
  }) {
    return AttendanceRequestFilterCriteria(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
      status: status ?? this.status,
    );
  }

  /// Tanggal mulai format 'yyyy-MM-dd' untuk API.
  String? get startDateParam {
    final start = dateRange?.start;
    if (start == null) return null;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  /// Tanggal selesai format 'yyyy-MM-dd' untuk API.
  String? get endDateParam {
    final end = dateRange?.end;
    if (end == null) return null;
    return '${end.year.toString().padLeft(4, '0')}-'
        '${end.month.toString().padLeft(2, '0')}-'
        '${end.day.toString().padLeft(2, '0')}';
  }

  AppRequestFilterData toAppData() {
    return AppRequestFilterData(
      dateRange: dateRange,
      companyId: companyId,
      company: company,
      departmentId: departmentId,
      department: department,
      positionId: positionId,
      position: position,
      status: status,
    );
  }

  static AttendanceRequestFilterCriteria fromAppData(AppRequestFilterData data) {
    return AttendanceRequestFilterCriteria(
      dateRange: data.dateRange,
      companyId: data.companyId,
      company: data.company,
      departmentId: data.departmentId,
      department: data.department,
      positionId: data.positionId,
      position: data.position,
      status: data.status,
    );
  }

  @override
  List<Object?> get props => [
        dateRange,
        companyId,
        company,
        departmentId,
        department,
        positionId,
        position,
        status,
      ];
}

/// Menampilkan Modal Bottom Sheet Filter Pengajuan Presensi Luar Kantor.
/// Menggunakan reusable [AppRequestFilterBottomSheet] berbasis Stitch M3.
Future<AttendanceRequestFilterCriteria?> showAttendanceRequestFilterBottomSheet(
  BuildContext context, {
  required AttendanceRequestFilterCriteria initialCriteria,
  OrganizationFilterRepository? repository,
  OrganizationFilterBloc? organizationFilterBloc,
}) async {
  final result = await showAppRequestFilterBottomSheet(
    context,
    title: 'Filter Pengajuan Presensi',
    initialData: initialCriteria.toAppData(),
    repository: repository,
    organizationFilterBloc: organizationFilterBloc,
  );

  if (result == null) return null;
  return AttendanceRequestFilterCriteria.fromAppData(result);
}

/// Widget Filter Pengajuan Presensi yang mendelegasikan ke [AppRequestFilterBottomSheet].
class AttendanceRequestFilterBottomSheet extends StatelessWidget {
  final AttendanceRequestFilterCriteria initialCriteria;

  const AttendanceRequestFilterBottomSheet({
    super.key,
    required this.initialCriteria,
  });

  @override
  Widget build(BuildContext context) {
    return AppRequestFilterBottomSheet(
      title: 'Filter Pengajuan Presensi',
      initialData: initialCriteria.toAppData(),
    );
  }
}
