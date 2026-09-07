import 'package:equatable/equatable.dart';

abstract class OrganizationFilterEvent extends Equatable {
  const OrganizationFilterEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memulai pemuatan companies (jika belum di-cache)
class OrganizationFilterStarted extends OrganizationFilterEvent {
  final bool forceRefresh;

  const OrganizationFilterStarted({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Event ketika pengguna memilih atau mengubah perusahaan
class OrganizationFilterCompanySelected extends OrganizationFilterEvent {
  final String? companyId;

  const OrganizationFilterCompanySelected({this.companyId});

  @override
  List<Object?> get props => [companyId];
}

/// Event ketika pengguna memilih atau mengubah departemen
class OrganizationFilterDepartmentSelected extends OrganizationFilterEvent {
  final String? companyId;
  final String? departmentId;

  const OrganizationFilterDepartmentSelected({
    this.companyId,
    this.departmentId,
  });

  @override
  List<Object?> get props => [companyId, departmentId];
}

/// Event refresh paksa semua master data
class OrganizationFilterRefreshed extends OrganizationFilterEvent {
  final String? currentCompanyId;

  const OrganizationFilterRefreshed({this.currentCompanyId});

  @override
  List<Object?> get props => [currentCompanyId];
}
