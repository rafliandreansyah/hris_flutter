import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';

/// Kriteria filter untuk daftar permintaan lembur (Overtime Requests).
class OvertimeFilterCriteria extends Equatable {
  final DateTimeRange? dateRange;
  final String? companyId;
  final String? company;
  final String? departmentId;
  final String? department;
  final String? positionId;
  final String? position;

  /// Filter status pengajuan: 'requested' (default), 'approved', 'rejected', 'all'.
  final String? status;

  /// Alias statusApprove untuk backward-compatibility.
  String? get statusApprove => status;

  const OvertimeFilterCriteria({
    this.dateRange,
    this.companyId,
    this.company,
    this.departmentId,
    this.department,
    this.positionId,
    this.position,
    String? status,
    String? statusApprove,
  }) : status = status ?? statusApprove ?? 'requested';

  bool get hasActiveFilter =>
      dateRange != null ||
      (company != null && company != 'Semua Perusahaan') ||
      (companyId != null && companyId!.isNotEmpty) ||
      (department != null && department != 'Semua Departemen') ||
      (departmentId != null && departmentId!.isNotEmpty) ||
      (position != null && position != 'Semua Jabatan') ||
      (positionId != null && positionId!.isNotEmpty) ||
      (status != null && status!.isNotEmpty && status != 'requested');

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
    if (status != null && status!.isNotEmpty && status != 'requested') {
      count++;
    }
    return count;
  }

  OvertimeFilterCriteria copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? companyId,
    String? company,
    String? departmentId,
    String? department,
    String? positionId,
    String? position,
    String? status,
    String? statusApprove,
  }) {
    return OvertimeFilterCriteria(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
      status: status ?? statusApprove ?? this.status,
    );
  }

  /// Tanggal mulai terformat 'yyyy-MM-dd' untuk query parameter API.
  String? get startDateParam {
    final start = dateRange?.start;
    if (start == null) return null;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  /// Tanggal selesai terformat 'yyyy-MM-dd' untuk query parameter API.
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
      status: status ?? 'requested',
    );
  }

  static OvertimeFilterCriteria fromAppData(AppRequestFilterData data) {
    return OvertimeFilterCriteria(
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

/// Menampilkan Modal Bottom Sheet "Filter Permintaan Lembur".
/// Menggunakan reusable [AppRequestFilterBottomSheet] berbasis Stitch M3.
Future<OvertimeFilterCriteria?> showOvertimeFilterBottomSheet(
  BuildContext context, {
  required OvertimeFilterCriteria initialCriteria,
  OrganizationFilterRepository? repository,
  OrganizationFilterBloc? organizationFilterBloc,
}) async {
  final result = await showAppRequestFilterBottomSheet(
    context,
    title: 'Filter Permintaan Lembur',
    initialData: initialCriteria.toAppData(),
    statusHelperText: 'Default memuat status permintaan diminta (requested)',
    repository: repository,
    organizationFilterBloc: organizationFilterBloc,
  );

  if (result == null) return null;
  return OvertimeFilterCriteria.fromAppData(result);
}

/// Widget Filter Permintaan Lembur yang mendelegasikan ke [AppRequestFilterBottomSheet].
class OvertimeFilterBottomSheet extends StatelessWidget {
  final OvertimeFilterCriteria initialCriteria;

  const OvertimeFilterBottomSheet({
    super.key,
    required this.initialCriteria,
  });

  @override
  Widget build(BuildContext context) {
    return AppRequestFilterBottomSheet(
      title: 'Filter Permintaan Lembur',
      initialData: initialCriteria.toAppData(),
      statusHelperText: 'Default memuat status permintaan diminta (requested)',
    );
  }
}
