import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/attendance_hero_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/leave_balance_preview_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/updates_feed_card.dart';
import 'package:hris_flutter/gen/assets.gen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Utama Dashboard Oasish HRIS sesuai dengan Google Stitch Design System.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isClockedIn = true;
  String _clockInTime = '08:30';
  String _clockOutTime = '--:--';

  void _toggleClock() {
    setState(() {
      if (_isClockedIn) {
        _isClockedIn = false;
        final now = DateTime.now();
        _clockOutTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil Clock Out! Selamat beristirahat.'),
            backgroundColor: AppColors.brandTeal,
          ),
        );
      } else {
        _isClockedIn = true;
        final now = DateTime.now();
        _clockInTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _clockOutTime = '--:--';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil Clock In! Selamat bekerja.'),
            backgroundColor: AppColors.brandTeal,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        titleSpacing: 16,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo Oasish
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderCol, width: 1),
              ),
              child: Image.asset(
                Assets.icons.logo.path,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),

            // Brand & Greeting Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Oasish',
                  style: AppTypography.headlineLargeMobile.copyWith(
                    color: isDark ? AppColors.inversePrimary : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Hi, Alex Rivera 👋',
                  style: AppTypography.labelMedium.copyWith(
                    color: labelCol,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification Button with Unread Red Dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pusat Notifikasi segera hadir')),
                  );
                },
                icon: Icon(
                  LucideIcons.bell,
                  size: 22,
                  color: textCol,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          // User Profile Avatar (Tapping navigates to Employee Detail)
          GestureDetector(
            onTap: () {
              context.push(Routes.EMPLOYEE_DETAIL);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 4),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandTeal, width: 1.5),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Section: Attendance Hero Card
              AttendanceHeroCard(
                currentTime: '08:45',
                currentDate: 'Kamis, 27 Agustus',
                location: 'HQ, Building A',
                schedule: '09:00 - 18:00',
                timezone: 'Asia/Jakarta',
                clockInTime: _clockInTime,
                clockOutTime: _clockOutTime,
                isClockedIn: _isClockedIn,
                onClockPressed: _toggleClock,
              ),
              const SizedBox(height: 24),

              // 2. Section: Quick Access Bento Grid
              const QuickAccessGrid(),
              const SizedBox(height: 24),

              // 3. Section: Leave Balance Card
              const LeaveBalancePreviewCard(),
              const SizedBox(height: 24),

              // 4. Section: Updates / Feed
              const UpdatesFeedCard(),
              const SizedBox(height: 32),

              // 5. Bottom App Version & Brand Footer
              const AppNameVersionText(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
