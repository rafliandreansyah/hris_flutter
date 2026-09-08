import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// App Bar khusus halaman Attendance & Check-In yang dapat hilang dan muncul
/// ketika discroll (SliverAppBar dengan floating: true & snap: true).
///
/// Memuat hanya 2 icon sesuai kebutuhan:
/// 1. Sisi kiri : Tombol Back
/// 2. Sisi kanan: Tombol Update Lokasi Sekarang
class AttendanceTopAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onUpdateLocationPressed;
  final bool isUpdatingLocation;

  const AttendanceTopAppBar({
    super.key,
    this.title = 'Attendance & Check-In',
    this.subtitle = 'Oasish Global Tech • Design & Product',
    this.onUpdateLocationPressed,
    this.isUpdatingLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final onSurfaceColor =
        isDark ? AppColors.darkOnSurface : AppColors.onBackground;
    final surfaceVariantColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;

    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        color: onSurfaceColor,
        tooltip: 'Kembali',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: surfaceVariantColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: isUpdatingLocation
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandTeal,
                  ),
                )
              : const Icon(LucideIcons.locateFixed),
          color: AppColors.brandTeal,
          tooltip: 'Update Lokasi Sekarang',
          onPressed: onUpdateLocationPressed,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
