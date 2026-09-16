import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pilihan target pembuatan aktivitas kerja
enum CreateActivityTarget {
  /// Aktivitas mandiri untuk diri sendiri (status ongoing langsung)
  self,

  /// Rencana aktivitas untuk didelegasikan ke bawahan/pegawai lain (status plan)
  subordinate,
}

/// Menampilkan Bottom Sheet pilihan pembuatan aktivitas kerja (khusus approver).
Future<CreateActivityTarget?> showCreateActivityOptionBottomSheet(
  BuildContext context,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<CreateActivityTarget>(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const _CreateActivityOptionSheetContent(),
  );
}

class _CreateActivityOptionSheetContent extends StatelessWidget {
  const _CreateActivityOptionSheetContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // 2. Header: Judul & Tombol Tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Aktivitas',
                          style: AppTypography.titleMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pilih target pembuatan aktivitas kerja',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: subtitleCol),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Opsi 1: Aktivitas Diri Sendiri
              _buildOptionCard(
                context: context,
                key: const ValueKey('create_self_activity_option'),
                icon: LucideIcons.user,
                title: 'Aktivitas Diri Sendiri',
                subtitle:
                    'Catat dan mulai aktivitas pekerjaan Anda saat ini secara langsung.',
                tag: null,
                isDark: isDark,
                textCol: textCol,
                subtitleCol: subtitleCol,
                borderCol: borderCol,
                brandColor: brandColor,
                onTap: () {
                  Navigator.of(context).pop(CreateActivityTarget.self);
                },
              ),
              const SizedBox(height: 12),

              // 4. Opsi 2: Aktivitas Bawahan / Pegawai Lain
              _buildOptionCard(
                context: context,
                key: const ValueKey('create_subordinate_activity_option'),
                icon: LucideIcons.users,
                title: 'Aktivitas Bawahan / Pegawai Lain',
                subtitle:
                    'Buat agenda penugasan atau rencana aktivitas kerja untuk didelegasikan ke pegawai.',
                tag: 'Status: Plan',
                isDark: isDark,
                textCol: textCol,
                subtitleCol: subtitleCol,
                borderCol: borderCol,
                brandColor: brandColor,
                onTap: () {
                  Navigator.of(context).pop(CreateActivityTarget.subordinate);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required String? tag,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: brandColor.withValues(alpha: 0.1),
          highlightColor: brandColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: brandColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.titleSmall.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          if (tag != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Chevron
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: subtitleCol,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
