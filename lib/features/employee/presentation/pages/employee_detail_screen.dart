import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employment_data_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/leave_balances_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/manager_info_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/metrics_strip_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/profile_hero_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/team_coworkers_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/work_location_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Detail Pegawai Oasish HRIS (Enhanced Leave View) sesuai Google Stitch.
class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: textCol,
            size: 22,
          ),
          onPressed: () {
            context.pop();
          },
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
              'EMP-2024-019 • Engineering',
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
            icon: Icon(
              LucideIcons.share2,
              size: 20,
              color: textCol,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Form edit profil segera dibuka')),
              );
            },
            icon: Icon(
              LucideIcons.pencil,
              size: 20,
              color: textCol,
            ),
          ),
        ],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Profile Header
              ProfileHeroCard(
                name: 'Sarah Jenkins',
                role: 'Senior Frontend Engineer',
                level: 'Level Senior Specialist (L4)',
                department: 'Engineering',
                company: 'PT Oasish Tech Nusantara',
                employmentStatus: 'Active Employee',
                contractType: 'Permanent / Tetap',
              ),
              SizedBox(height: 16),

              // 2. Metrics Strip (Overtime & Leave Requests)
              MetricsStripCard(
                overtimeFormatted: '4 Jam 0 Menit',
                overtimeTotalMinutes: 240,
                leaveRequestCount: 3,
                leaveRequestStatus: 'Menunggu Approval',
              ),
              SizedBox(height: 16),

              // 3. Saldo & Kuota Cuti (Enhanced Leave Quota View)
              LeaveBalancesCard(),
              SizedBox(height: 16),

              // 4. Direct Reporting Manager
              ManagerInfoCard(
                name: 'Alex Rivera',
                role: 'Senior Engineering Manager',
                department: 'Engineering',
                company: 'PT Oasish Tech Nusantara',
                employeeId: 'EMP-2022-005',
                initials: 'AR',
              ),
              SizedBox(height: 16),

              // 5. Employment & Personal Data
              EmploymentDataCard(
                joinDate: '28 Agustus 2024',
                contractExpiry: 'Karyawan Tetap',
                employeeId: 'EMP-2024-019',
                nik: '3171012345670001',
                placeDob: 'Surabaya, 20 Februari 1995',
                gender: 'Perempuan',
                bloodType: 'O+',
                bankName: 'Bank BCA',
                accountNumber: '8801-2345-6789',
                accountHolder: 'Sarah Jenkins',
              ),
              SizedBox(height: 16),

              // 6. Residential Address & Assigned Work Location
              WorkLocationCard(
                residentialAddress:
                    'Jl. Dharmahusada Indah Barat No. 88, Kel. Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60285, Indonesia',
                officeName: 'HQ Office Sudirman',
                officeAddress: 'SCBD Lot 28 Floor 14, Jakarta Selatan',
                radius: '50m',
                isDefaultOffice: true,
              ),
              SizedBox(height: 16),

              // 7. Team Coworkers Preview
              TeamCoworkersCard(),
              SizedBox(height: 32),

              // 8. Brand Version Footer
              AppNameVersionText(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
