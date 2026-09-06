import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_map_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_timeline_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Aktivitas & Verifikasi (Activity Detail & Verification)
/// Berdasarkan spesifikasi Google Stitch Oasish Flutter M3 HRIS
class ActivityDetailScreen extends StatelessWidget {
  final ActivityItem? activity;
  final String? activityId;

  const ActivityDetailScreen({
    super.key,
    this.activity,
    this.activityId,
  });

  /// Mengambil data aktivitas yang valid dari properti atau fallback ID
  ActivityItem get _resolvedActivity {
    if (activity != null) return activity!;
    if (activityId != null) {
      final found = ActivityItem.sampleActivities.firstWhere(
        (item) => item.id == activityId,
        orElse: () => ActivityItem.sampleActivities[1],
      );
      return found;
    }
    // Default fallback: Site Inspection (Budi Santoso - sesuai Stitch)
    return ActivityItem.sampleActivities[1];
  }

  @override
  Widget build(BuildContext context) {
    final item = _resolvedActivity;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.backgroundSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bgCol,
      // 1. TopAppBar: Back Button, Title & Subtitle, ONLY Share Action
      appBar: AppBar(
        backgroundColor: bgCol,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: textCol,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/activity');
            }
          },
          tooltip: 'Kembali',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Detail',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${item.id} • ${item.status.label}',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 12,
                color: subtitleCol,
              ),
            ),
          ],
        ),
        actions: [
          // Aksi AppBar: HANYA ikon share saja sesuai instruksi eksplisit
          IconButton(
            icon: Icon(
              LucideIcons.share2,
              color: textCol,
              size: 20,
            ),
            tooltip: 'Bagikan Aktivitas',
            onPressed: () => _handleShare(context, item),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 2. Body Scrollable Content
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Header Status & Employee Profile Card
            _buildProfileStatusCard(
              context: context,
              item: item,
              cardBg: cardBg,
              borderCol: borderCol,
              textCol: textCol,
              subtitleCol: subtitleCol,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Section 2: Google Maps Card
            ActivityMapCard(activity: item),

            const SizedBox(height: 24),

            // Section 3: 2-Phase Progress Timeline
            ActivityTimelineSection(phases: item.activePhases),

            const SizedBox(height: 24),

            // Section 4: Export Summary Button (PDF)
            _buildExportButton(context, item, cardBg, borderCol, isDark),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Card Status & Profil Karyawan
  Widget _buildProfileStatusCard({
    required BuildContext context,
    required ActivityItem item,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required bool isDark,
  }) {
    final categoryText = item.category ?? item.title;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Badge & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandTeal.withValues(alpha: 0.15)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categoryText,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.status.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.status.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.status.label,
                      style: TextStyle(
                        color: item.status.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Avatar + Name + Role & Department
          Row(
            children: [
              AppAvatar(
                name: item.userName,
                initials: item.initials,
                imageUrl: item.avatarUrl,
                size: 48,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                textColor: textCol,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.userRole,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: subtitleCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.department} • ${item.company}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: subtitleCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 3: Bottom Location
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderCol, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  color: Color(0xFF0D9488),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.location,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textCol,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol Export PDF
  Widget _buildExportButton(
    BuildContext context,
    ActivityItem item,
    Color cardBg,
    Color borderCol,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mengunduh ringkasan PDF untuk aktivitas ${item.id}...',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.brandTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(
          LucideIcons.download,
          size: 18,
          color: Color(0xFF0D9488),
        ),
        label: const Text(
          'Export Activity Summary (PDF)',
          style: TextStyle(
            color: Color(0xFF0D9488),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: cardBg,
          side: BorderSide(color: borderCol, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  /// Menangani aksi share laporan aktivitas
  void _handleShare(BuildContext context, ActivityItem item) {
    final shareContent = StringBuffer()
      ..writeln('📋 LAPORAN AKTIVITAS OASISH HRIS')
      ..writeln('ID: ${item.id}')
      ..writeln('Judul: ${item.title}')
      ..writeln('Karyawan: ${item.userName} (${item.userRole})')
      ..writeln('Departemen: ${item.department}')
      ..writeln('Status: ${item.status.label}')
      ..writeln('Lokasi: ${item.location}')
      ..writeln('Waktu: ${item.time}')
      ..writeln('\nDeskripsi:')
      ..writeln(item.description);

    SharePlus.instance.share(
      ShareParams(
        text: shareContent.toString(),
        subject: 'Laporan Aktivitas: ${item.title} (${item.id})',
      ),
    );
  }
}
