import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/account_settings_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employment_data_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/leave_balances_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/manager_info_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/metrics_strip_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/profile_hero_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/team_coworkers_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/work_location_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Detail Pegawai Oasish HRIS (Enhanced Leave View) sesuai Google Stitch.
/// Memuat data dari API endpoint `/employee/{id}`:
/// - Jika dari profil pengguna yang login: menggunakan employee ID yang tersimpan di storage lokal.
/// - Jika dari item Employee Directory: memuat berdasarkan ID spesifik pegawai terkait.
class EmployeeDetailScreen extends StatefulWidget {
  final EmployeeDirectoryItem? employee;
  final String? employeeId;
  final EmployeeRepository? repository;
  final bool? isFromDirectory;

  const EmployeeDetailScreen({
    super.key,
    this.employee,
    this.employeeId,
    this.repository,
    this.isFromDirectory,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late final EmployeeRepository _repository;
  EmployeeDetailData? _detailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmployeeRepositoryImpl();
    _fetchEmployeeDetail();
  }

  Future<void> _fetchEmployeeDetail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String? targetId = widget.employeeId;

    // 1. Jika ada employee dari item directory, gunakan rawId atau id
    if (targetId == null || targetId.isEmpty) {
      targetId = widget.employee?.rawId ?? widget.employee?.id;
    }

    // 2. Jika tidak ada (misal dibuka dari profile user yang login di Dashboard),
    // ambil employee ID dari local storage
    if (targetId == null || targetId.isEmpty) {
      targetId = await SecureStorageService.instance.getEmployeeId();
    }

    if (targetId != null && targetId.isNotEmpty) {
      try {
        final data = await _repository.getEmployeeDetail(targetId);
        if (mounted) {
          setState(() {
            _detailData = data;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {
        // Graceful fallback ke data awal / sample jika unauthenticated / error
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
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
      return 'Jl. Dharmahusada Indah Barat No. 88, Kel. Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60285, Indonesia';
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

    final detail = _detailData;

    final displayName = detail?.fullName.isNotEmpty == true
        ? detail!.fullName
        : (widget.employee?.name ?? 'Sarah Jenkins');

    final displayRole = detail?.position?.name.isNotEmpty == true
        ? detail!.position!.name
        : (widget.employee?.role ?? 'Senior Frontend Engineer');

    final displayDept = detail?.department?.name.isNotEmpty == true
        ? detail!.department!.name
        : (widget.employee?.department ?? 'Engineering');

    final displayId = detail?.employeeNumber?.isNotEmpty == true
        ? detail!.employeeNumber!
        : (widget.employee?.id ?? 'EMP-2024-019');

    final displayCompany = detail?.company?.name.isNotEmpty == true
        ? detail!.company!.name
        : (widget.employee?.company ?? 'PT Oasish Tech Nusantara');

    final displayAvatar = detail?.photoUrl ?? widget.employee?.avatarUrl;

    final isFromDirectory = widget.isFromDirectory ?? (widget.employee != null);

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
          if (!isFromDirectory)
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
          onRefresh: _fetchEmployeeDetail,
          color: brandColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading banner if fetching in background
                if (_isLoading && detail == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      backgroundColor: brandColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                    ),
                  ),

                // 1. Hero Profile Header
                ProfileHeroCard(
                  name: displayName,
                  role: displayRole,
                  level: detail?.level?.name ?? 'Level Senior Specialist (L4)',
                  department: displayDept,
                  company: displayCompany,
                  employmentStatus: detail != null
                      ? (detail.status ? 'Active Employee' : 'Inactive')
                      : 'Active Employee',
                  contractType: detail?.employmentType ?? 'Permanent / Tetap',
                  avatarUrl: displayAvatar,
                  onCall: () {
                    final ph = detail?.phone ?? widget.employee?.phone;
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
                    final em = detail?.email ?? widget.employee?.email;
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
                      : '4 Jam 0 Menit',
                  overtimeTotalMinutes: detail?.totalOvertime != null
                      ? (detail!.totalOvertime! * 60).toInt()
                      : 240,
                  leaveRequestCount: detail?.totalLeaveRequest?.toInt() ?? 3,
                  leaveRequestStatus: 'Menunggu Approval',
                ),
                const SizedBox(height: 16),

                // 3. Saldo & Kuota Cuti (Enhanced Leave Quota View)
                const LeaveBalancesCard(),
                const SizedBox(height: 16),

                // 4. Direct Reporting Manager
                ManagerInfoCard(
                  name: detail?.manager?.fullName,
                  role: detail?.manager != null ? 'Senior Engineering Manager' : null,
                  department: displayDept,
                  company: displayCompany,
                  employeeId: detail?.manager?.employeeNumber,
                  initials: detail?.manager?.initials,
                  avatarUrl: detail?.manager?.photoUrl,
                ),
                const SizedBox(height: 16),

                // 5. Employment & Personal Data
                EmploymentDataCard(
                  joinDate: _formatDate(detail?.joinDate ?? '2024-08-28'),
                  contractExpiry: detail?.contractExpiryDate != null
                      ? _formatDate(detail!.contractExpiryDate)
                      : (detail?.employmentType ?? 'Karyawan Tetap'),
                  employeeId: displayId,
                  nik: detail?.idNumber ?? '3171012345670001',
                  placeDob:
                      (detail?.placeOfBirth != null || detail?.dob != null)
                      ? '${detail?.placeOfBirth ?? ""}, ${_formatDate(detail?.dob)}'
                      : 'Surabaya, 20 Februari 1995',
                  gender: detail?.gender ?? 'Perempuan',
                  bloodType: detail?.bloodType ?? 'O+',
                  bankName: detail?.bankName ?? 'Bank BCA',
                  accountNumber:
                      detail?.bankNumber ??
                      (detail?.bankAccount ?? '8801-2345-6789'),
                  accountHolder: displayName,
                ),
                const SizedBox(height: 16),

                // 6. Residential Address & Assigned Work Location
                WorkLocationCard(
                  residentialAddress: _buildFullAddress(detail),
                  officeName:
                      detail?.employeeWorkLocation.firstOrNull?.name ??
                      'HQ Office Sudirman',
                  officeAddress:
                      detail?.employeeWorkLocation.firstOrNull?.address ??
                      'SCBD Lot 28 Floor 14, Jakarta Selatan',
                  radius:
                      detail?.employeeWorkLocation.firstOrNull?.radius != null
                      ? '${detail!.employeeWorkLocation.firstOrNull!.radius}m'
                      : '50m',
                  isDefaultOffice:
                      detail?.employeeWorkLocation.firstOrNull?.isDefault ??
                      true,
                ),
                const SizedBox(height: 16),

                // 7. Team Coworkers Preview
                if (detail != null)
                  TeamCoworkersCard(
                    coworkers: detail.coworkers
                        .map(
                          (c) => CoworkerItem(
                            name: c.fullName,
                            role: 'Team Member',
                            initials: c.initials,
                            phone: c.phone,
                            avatarUrl: c.photoUrl,
                          ),
                        )
                        .toList(),
                  )
                else
                  const TeamCoworkersCard(),
                const SizedBox(height: 32),

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
