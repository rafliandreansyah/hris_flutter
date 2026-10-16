import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/employee/presentation/pages/coworker_list_screen.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_detail/employee_detail_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/account_settings_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employment_data_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/leave_balances_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/manager_info_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/metrics_strip_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/profile_hero_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/team_coworkers_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/work_location_card.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_profile_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Detail Pegawai Oasish HRIS (Enhanced Leave View) sesuai Google Stitch.
/// Menggunakan Clean Architecture + Flutter BLoC (EmployeeDetailBloc).
class EmployeeDetailScreen extends StatelessWidget {
  final EmployeeDirectoryItem? employee;
  final String? employeeId;
  final EmployeeRepository? repository;
  final EmployeeDetailBloc? employeeDetailBloc;
  final bool? isFromDirectory;

  const EmployeeDetailScreen({
    super.key,
    this.employee,
    this.employeeId,
    this.repository,
    this.employeeDetailBloc,
    this.isFromDirectory,
  });

  @override
  Widget build(BuildContext context) {
    if (employeeDetailBloc != null) {
      return BlocProvider<EmployeeDetailBloc>.value(
        value: employeeDetailBloc!,
        child: _EmployeeDetailView(
          employee: employee,
          employeeId: employeeId,
          isFromDirectory: isFromDirectory,
        ),
      );
    }

    return BlocProvider<EmployeeDetailBloc>(
      create: (ctx) => EmployeeDetailBloc(repository: repository)
        ..add(EmployeeDetailStarted(
          employeeId: employeeId,
          employee: employee,
        )),
      child: _EmployeeDetailView(
        employee: employee,
        employeeId: employeeId,
        isFromDirectory: isFromDirectory,
      ),
    );
  }
}

class _EmployeeDetailView extends StatelessWidget {
  final EmployeeDirectoryItem? employee;
  final String? employeeId;
  final bool? isFromDirectory;

  const _EmployeeDetailView({
    this.employee,
    this.employeeId,
    this.isFromDirectory,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _buildFullAddress(EmployeeDetailData? data) {
    if (data == null) {
      // Jangan tampilkan alamat contoh; kosong bila data belum tersedia.
      return '-';
    }
    final parts = [
      data.address,
      if (data.village?.name != null && data.village!.name.isNotEmpty)
        'Kel. ${data.village!.name}',
      if (data.district?.name != null && data.district!.name.isNotEmpty)
        'Kec. ${data.district!.name}',
      data.city?.name,
      data.province?.name,
      data.postalCode,
      data.country?.name,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'Alamat belum diatur';
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final state = context.watch<EmployeeDetailBloc>().state;
    final detail = state.detail;
    final isLoading = state.isLoading;

    final displayName = detail?.fullName.isNotEmpty == true
        ? detail!.fullName
        : (employee?.name ?? '-');

    final displayRole = detail?.position?.name.isNotEmpty == true
        ? detail!.position!.name
        : (employee?.role ?? '-');

    final displayDept = detail?.department?.name.isNotEmpty == true
        ? detail!.department!.name
        : (employee?.department ?? '-');

    final displayId = detail?.employeeNumber?.isNotEmpty == true
        ? detail!.employeeNumber!
        : (employee?.id ?? '-');

    final displayCompany = detail?.company?.name.isNotEmpty == true
        ? detail!.company!.name
        : (employee?.company ?? '-');

    final displayAvatar = detail?.photoUrl ?? employee?.avatarUrl;

    final effectiveIsFromDirectory =
        isFromDirectory ?? (employee != null);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Detail',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.1,
              ),
            ),
            Text(
              '$displayId • $displayDept',
              style: AppTypography.labelSmall.copyWith(
                color: labelCol,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membagikan profil karyawan...')),
              );
            },
            icon: Icon(LucideIcons.share2, size: 20, color: textCol),
          ),
          if (!effectiveIsFromDirectory)
            IconButton(
              onPressed: () {
                showAccountSettingsBottomSheet(
                  context,
                  employeeId: displayId,
                  name: displayName,
                  role: displayRole,
                  status: detail != null
                      ? (detail.status ? 'Active Employee' : 'Inactive')
                      : 'Active Employee',
                  avatarUrl: displayAvatar,
                );
              },
              icon: Icon(LucideIcons.pencil, size: 20, color: textCol),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context
                .read<EmployeeDetailBloc>()
                .add(const EmployeeDetailRefreshed());
          },
          color: brandColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading banner if fetching in background
                if (isLoading && detail == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      backgroundColor: brandColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                    ),
                  ),

                // Error state (pesan berasal dari API; 404 hanya "Kembali")
                if (state.status == EmployeeDetailStatus.failure &&
                    detail == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.circleAlert, size: 40, color: AppColors.errorRed),
                        const SizedBox(height: 8),
                        Text(
                          state.errorMessage ?? 'Terjadi kesalahan pada sistem',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: labelCol),
                        ),
                        const SizedBox(height: 12),
                        if (state.errorStatusCode == 404)
                          AppButton(
                            text: 'Kembali',
                            leadingIcon: LucideIcons.arrowLeft,
                            width: 140,
                            height: 42,
                            onPressed: () => context.pop(),
                          )
                        else
                          AppButton(
                            text: 'Coba Lagi',
                            leadingIcon: LucideIcons.rotateCcw,
                            width: 140,
                            height: 42,
                            onPressed: () => context
                                .read<EmployeeDetailBloc>()
                                .add(const EmployeeDetailRefreshed()),
                          ),
                      ],
                    ),
                  ),

                // 1. Hero Profile Header
                ProfileHeroCard(
                  name: displayName,
                  role: displayRole,
                  level: detail?.level?.name ?? '-',
                  department: displayDept,
                  company: displayCompany,
                  employmentStatus: detail != null
                      ? (detail.status ? 'Active Employee' : 'Inactive')
                      : '-',
                  contractType: detail?.employmentType ?? '-',
                  avatarUrl: displayAvatar,
                  onCall: () {
                    final ph = detail?.phone ?? employee?.phone;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ph != null && ph.isNotEmpty
                              ? 'Menghubungi $displayName ($ph)'
                              : 'Nomor telepon belum tersedia',
                        ),
                      ),
                    );
                  },
                  onEmail: () {
                    final em = detail?.email ?? employee?.email;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mengirim email ke $em')),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Metrics Strip (Overtime & Leave Requests)
                MetricsStripCard(
                  overtimeFormatted: detail?.totalOvertime != null
                      ? '${detail!.totalOvertime} Jam'
                      : '-',
                  overtimeTotalMinutes: detail?.totalOvertime != null
                      ? (detail!.totalOvertime! * 60).toInt()
                      : 0,
                  leaveRequestCount: detail?.totalLeaveRequest?.toInt() ?? 0,
                  leaveRequestStatus: 'Menunggu Approval',
                ),
                const SizedBox(height: 16),

                // 3. Saldo & Kuota Cuti (Enhanced Leave Quota View)
                const LeaveBalancesCard(),
                const SizedBox(height: 16),

                // 4. Direct Reporting Manager
                ManagerInfoCard(
                  name: detail?.manager?.fullName,
                  role: null,
                  department: displayDept,
                  company: displayCompany,
                  employeeId: detail?.manager?.employeeNumber,
                  initials: detail?.manager?.initials,
                  avatarUrl: detail?.manager?.photoUrl,
                ),
                const SizedBox(height: 16),

                // 5. Employment & Personal Data
                EmploymentDataCard(
                  joinDate: detail?.joinDate != null ? _formatDate(detail!.joinDate) : '-',
                  contractExpiry: detail?.contractExpiryDate != null
                      ? _formatDate(detail!.contractExpiryDate)
                      : (detail?.employmentType ?? '-'),
                  employeeId: displayId,
                  nik: detail?.idNumber ?? '-',
                  placeDob:
                      (detail?.placeOfBirth != null || detail?.dob != null)
                      ? '${detail?.placeOfBirth ?? ""}, ${_formatDate(detail?.dob)}'
                      : '-',
                  gender: detail?.gender ?? '-',
                  bloodType: detail?.bloodType ?? '-',
                  bankName: detail?.bankName ?? '-',
                  accountNumber:
                      detail?.bankNumber ??
                      (detail?.bankAccount ?? '-'),
                  accountHolder: displayName,
                ),
                const SizedBox(height: 16),

                // 6. Residential Address & Assigned Work Location
                WorkLocationCard(
                  residentialAddress: _buildFullAddress(detail),
                  officeName:
                      detail?.employeeWorkLocation.firstOrNull?.name ?? '-',
                  officeAddress:
                      detail?.employeeWorkLocation.firstOrNull?.address ?? '-',
                  radius:
                      detail?.employeeWorkLocation.firstOrNull?.radius != null
                      ? '${detail!.employeeWorkLocation.firstOrNull!.radius}m'
                      : '-',
                  isDefaultOffice:
                      detail?.employeeWorkLocation.firstOrNull?.isDefault ??
                      true,
                ),
                const SizedBox(height: 16),

                // 6b. Kontrak & Riwayat Karier (hanya profil sendiri; tanpa gaji)
                if (!effectiveIsFromDirectory) ...[
                  const LifecycleProfileSection(),
                  const SizedBox(height: 16),
                ],

                // 7. Team Coworkers Preview (Hanya tampil saat melihat profil diri sendiri)
                if (!effectiveIsFromDirectory) ...[
                  Builder(
                    builder: (context) {
                      final List<EmployeeDirectoryItem> coworkerItems =
                          state.coworkers ??
                              (detail?.coworkers
                                      .map((c) => EmployeeDirectoryItem(
                                            id: c.id,
                                            rawId: c.id,
                                            name: c.fullName,
                                            role: 'Team Member',
                                            department: displayDept,
                                            company: displayCompany,
                                            email: c.email,
                                            phone: c.phone,
                                            avatarUrl: c.photoUrl,
                                            initials: c.initials,
                                            firstName: c.firstName,
                                            lastName: c.lastName,
                                            employeeNumber: c.employeeNumber,
                                            idNumber: c.idNumber,
                                          ))
                                      .toList() ??
                                  const []);

                      final coworkerCardList = coworkerItems
                          .map((c) => CoworkerItem(
                                id: c.id,
                                name: c.name,
                                role: c.role,
                                initials: c.initials,
                                phone: c.phone,
                                avatarUrl: c.avatarUrl,
                                directoryItem: c,
                              ))
                          .toList();

                      return TeamCoworkersCard(
                        coworkers: coworkerCardList,
                        onCoworkerTap: (item) {
                          if (item.directoryItem != null) {
                            context.push(
                              Routes.EMPLOYEE_DETAIL,
                              extra: item.directoryItem,
                            );
                          }
                        },
                        onViewAll: () {
                          context.push(
                            Routes.COWORKER_LIST,
                            extra: CoworkerListArgs(
                              initialCoworkers: coworkerItems,
                              employeeName: displayName,
                              departmentName: displayDept,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                // 8. Brand Version Footer
                const Center(child: AppNameVersionText()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
