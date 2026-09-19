import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Pengumuman / Feed Updates Dashboard.
/// Menampilkan daftar pengumuman terbaru, atau pesan info jika belum ada pengumuman.
class UpdatesFeedCard extends StatelessWidget {
  final List<AnnouncementItem> announcements;
  final bool? hasAnnouncement;
  final String? title;
  final String? timeAndCategory;
  final VoidCallback? onSeeAll;
  final VoidCallback? onItemTap;
  final void Function(AnnouncementItem item)? onAnnouncementTap;

  const UpdatesFeedCard({
    super.key,
    this.announcements = const [],
    this.hasAnnouncement,
    this.title,
    this.timeAndCategory,
    this.onSeeAll,
    this.onItemTap,
    this.onAnnouncementTap,
  });

  /// Format waktu relatif pengumuman (e.g. "2h lalu · Company Announcement").
  static String formatAnnouncementTime(String? createdAt) {
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

  List<AnnouncementItem> _resolveItems() {
    if (announcements.isNotEmpty) {
      return announcements;
    }
    final legacyHas = hasAnnouncement ?? (title != null && title!.isNotEmpty);
    if (legacyHas && title != null && title!.isNotEmpty) {
      return [
        AnnouncementItem(
          id: '',
          title: title!,
          createdAt: null,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final cardBg =
        isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF1F5F9);
    final iconBoxBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final iconCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final items = _resolveItems();
    final isAvailable = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Updates',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isAvailable)
              GestureDetector(
                onTap: onSeeAll ?? () => context.push(Routes.ANNOUNCEMENT),
                child: Text(
                  'See All',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Jika Belum Ada Pengumuman
        if (!isAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineMuted
                    : AppColors.outlineMuted.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.bellOff,
                    size: 20,
                    color: labelCol,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tidak ada pengumuman',
                        style: AppTypography.bodyMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saat ini belum ada pengumuman terbaru dari perusahaan',
                        style: AppTypography.labelSmall.copyWith(
                          color: labelCol,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // Announcement Item List
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildAnnouncementCard(
              context: context,
              item: items[i],
              isDark: isDark,
              textCol: textCol,
              labelCol: labelCol,
              cardBg: cardBg,
              iconBoxBg: iconBoxBg,
              iconCol: iconCol,
              subtitle: (timeAndCategory != null &&
                      items.length == 1 &&
                      items.first.createdAt == null)
                  ? timeAndCategory!
                  : formatAnnouncementTime(items[i].createdAt),
            ),
          ],
      ],
    );
  }

  Widget _buildAnnouncementCard({
    required BuildContext context,
    required AnnouncementItem item,
    required bool isDark,
    required Color textCol,
    required Color labelCol,
    required Color cardBg,
    required Color iconBoxBg,
    required Color iconCol,
    required String subtitle,
  }) {
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted.withValues(alpha: 0.6);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (onAnnouncementTap != null) {
            onAnnouncementTap!(item);
          } else if (onItemTap != null) {
            onItemTap!();
          } else if (item.id.isNotEmpty) {
            context.push(Routes.ANNOUNCEMENT_DETAIL, extra: item.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderCol,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.megaphone,
                  size: 20,
                  color: iconCol,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: labelCol,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: labelCol,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
