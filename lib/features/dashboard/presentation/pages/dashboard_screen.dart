import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/attendance_hero_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/dashboard_shimmer_loading.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/updates_feed_card.dart';
import 'package:hris_flutter/gen/assets.gen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Utama Dashboard Oasish HRIS dengan integrasi data backend,
/// realtime server clock (termasuk detik), dan shimmer loading.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => DashboardBloc()..add(const DashboardFetchRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  // Format jam dengan detik secara tepat (HH:mm:ss)
  String _formatTimeWithSeconds(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // Format tanggal dalam Bahasa Indonesia
  String _formatDate(DateTime dt) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName';
  }

  String _formatAnnouncementTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return 'Terbaru · Company Announcement';
    }
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return 'Terbaru · Company Announcement';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu · Company Announcement';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h lalu · Company Announcement';
    } else {
      return '${diff.inDays}h lalu · Company Announcement';
    }
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
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

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
        title: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            String greetingName = 'User';
            if (state is DashboardLoaded) {
              greetingName = state.dashboardData.firstName;
            }

            return Row(
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

                // Brand & Dynamic Greeting Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Oasish',
                      style: AppTypography.headlineLargeMobile.copyWith(
                        color: isDark
                            ? AppColors.inversePrimary
                            : AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Hi, $greetingName 👋',
                      style: AppTypography.labelMedium.copyWith(
                        color: labelCol,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          // Notification Button with Unread Red Dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pusat Notifikasi segera hadir'),
                    ),
                  );
                },
                icon: Icon(LucideIcons.bell, size: 22, color: textCol),
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
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              String? photoUrl;
              String? name;
              String? initials;
              if (state is DashboardLoaded) {
                photoUrl = state.dashboardData.photoUrl;
                name = state.dashboardData.fullName;
                initials = state.dashboardData.initials;
              }

              return GestureDetector(
                onTap: () {
                  context.push(Routes.EMPLOYEE_DETAIL);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 4),
                  child: AppAvatar(
                    imageUrl: photoUrl,
                    name: name ?? 'User',
                    initials: initials,
                    size: 36,
                    showBorder: true,
                    borderColor: AppColors.brandTeal,
                    borderWidth: 1.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            // 1. Shimmer Loading State
            if (state is DashboardLoading || state is DashboardInitial) {
              return const DashboardShimmerLoading();
            }

            // 2. Error State
            if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.circleAlert,
                        size: 48,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat Dashboard',
                        style: AppTypography.titleMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: labelCol,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandTeal,
                        ),
                        onPressed: () {
                          context.read<DashboardBloc>().add(
                            const DashboardFetchRequested(),
                          );
                        },
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 3. Loaded State
            if (state is DashboardLoaded) {
              final data = state.dashboardData;
              final menus = state.menus;
              final serverTime = state.currentServerTime;

              // Hitung format jam realtime dengan detik
              final currentTimeStr = _formatTimeWithSeconds(serverTime);
              final currentDateStr = _formatDate(serverTime);

              // Data Absensi Hari Ini
              final todayAtt = data.attendanceSummary?.todayAttendance;
              final inTime = todayAtt?.inTime ?? '--:--';
              final outTime = todayAtt?.outTime ?? '--:--';
              final isClockedIn =
                  todayAtt?.inTime != null && todayAtt?.outTime == null;

              // Jadwal Shift Hari Ini
              final shift = data.todaySchedule?.shift;
              final scheduleStr = shift != null
                  ? (shift.startTime != null && shift.endTime != null
                        ? '${shift.startTime} - ${shift.endTime}'
                        : (shift.isFlexibleTime
                              ? 'Flexible Shift'
                              : '09:00 - 18:00'))
                  : '09:00 - 18:00';

              // Lokasi Perusahaan
              final locationStr = data.company?.name ?? 'HQ, Building A';

              // Pengumuman Terakhir
              final hasAnnouncement = data.latestAnnouncement.isNotEmpty;
              final announcement = hasAnnouncement
                  ? data.latestAnnouncement.first
                  : null;

              return RefreshIndicator(
                color: AppColors.brandTeal,
                onRefresh: () async {
                  context.read<DashboardBloc>().add(
                    const DashboardFetchRequested(isRefresh: true),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Section: Attendance Hero Card (Realtime Server Clock dengan Detik)
                      AttendanceHeroCard(
                        currentTime: currentTimeStr,
                        currentDate: currentDateStr,
                        location: locationStr,
                        schedule: scheduleStr,
                        timezone: data.timezone ?? 'Asia/Jakarta',
                        clockInTime: inTime,
                        clockOutTime: outTime,
                        isClockedIn: isClockedIn,
                        onClockPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isClockedIn
                                    ? 'Form Clock Out segera dibuka'
                                    : 'Form Clock In segera dibuka',
                              ),
                              backgroundColor: AppColors.brandTeal,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // 2. Section: Quick Access Bento Grid (Dinamis dari /auth/menus)
                      QuickAccessGrid(menus: menus),
                      const SizedBox(height: 24),

                      // 3. Section: Updates / Feed Pengumuman
                      UpdatesFeedCard(
                        hasAnnouncement: hasAnnouncement,
                        title: announcement?.title,
                        timeAndCategory: _formatAnnouncementTime(
                          announcement?.createdAt,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4. Bottom App Version & Brand Footer
                      Center(child: const AppNameVersionText()),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
