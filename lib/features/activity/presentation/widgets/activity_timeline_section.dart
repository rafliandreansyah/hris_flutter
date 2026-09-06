import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Section Timeline Progres 2-Fase (Activity Progress Timeline) sesuai spesifikasi Google Stitch
class ActivityTimelineSection extends StatelessWidget {
  final List<ActivityPhaseItem> phases;

  const ActivityTimelineSection({
    super.key,
    required this.phases,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Activity Progress Timeline',
            style: AppTypography.titleMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Timeline items with connected vertical line
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: phases.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final phase = phases[index];
            final isLast = index == phases.length - 1;
            return _buildTimelinePhaseRow(
              context: context,
              phase: phase,
              isLast: isLast,
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelinePhaseRow({
    required BuildContext context,
    required ActivityPhaseItem phase,
    required bool isLast,
    required bool isDark,
  }) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final isPhase1 = phase.phaseNumber == 1;
    final nodeColor =
        isPhase1 ? const Color(0xFF0D9488) : const Color(0xFF10B981);
    final nodeIcon = isPhase1 ? LucideIcons.play : LucideIcons.check;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Left: Node Icon & Connecting Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Circular Node Icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      nodeIcon,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                // Connecting line if not the last phase
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: borderCol,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 2. Right: Content Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
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
                  // Phase Title & Time
                  Text(
                    phase.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phase.time,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: subtitleCol,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Label / Category
                  Text(
                    phase.label,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtitleCol,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description Notes
                  Text(
                    phase.notes,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: textCol,
                    ),
                  ),

                  // Image Attachment if present
                  if (phase.imageUrl != null && phase.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showImagePreview(
                        context,
                        phase.imageUrl!,
                        phase.title,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: phase.imageUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 120,
                                color: isDark
                                    ? AppColors.darkSurfaceContainerHigh
                                    : AppColors.surfaceContainerHigh,
                                child: Center(
                                  child: Icon(
                                    LucideIcons.image,
                                    color: subtitleCol.withValues(alpha: 0.5),
                                    size: 24,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 120,
                                color: isDark
                                    ? AppColors.darkSurfaceContainerHigh
                                    : AppColors.surfaceContainerHigh,
                                child: Center(
                                  child: Icon(
                                    LucideIcons.image,
                                    color: subtitleCol,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            // Zoom hint overlay on bottom right
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.maximize2,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Lihat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog preview foto ukuran penuh
  void _showImagePreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar with title & close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Zoomable Interactive Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        LucideIcons.image,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
