import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Satu aksi di menu titik tiga halaman detail.
class AppDetailMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const AppDetailMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  /// Aksi standar "Bagikan".
  factory AppDetailMenuItem.share(VoidCallback onTap) => AppDetailMenuItem(
    icon: LucideIcons.share2,
    label: 'Bagikan',
    onTap: onTap,
  );

  /// Aksi standar "Salin Link".
  factory AppDetailMenuItem.copyLink(VoidCallback onTap) => AppDetailMenuItem(
    icon: LucideIcons.link,
    label: 'Salin Link',
    onTap: onTap,
  );
}

/// Menu titik tiga (overflow) standar di AppBar halaman detail.
///
/// Menggabungkan aksi sekunder (bagikan, salin link, hapus, dll.) dalam
/// satu ikon agar header tetap ringkas. Tidak dirender bila [items] kosong.
class AppDetailMoreMenu extends StatelessWidget {
  final List<AppDetailMenuItem> items;
  final Color? iconColor;

  const AppDetailMoreMenu({super.key, required this.items, this.iconColor});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final menuBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return PopupMenuButton<int>(
      tooltip: 'Opsi lainnya',
      icon: Icon(
        LucideIcons.ellipsisVertical,
        color: iconColor ?? textCol,
        size: 20,
      ),
      color: menuBg,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderInput),
      position: PopupMenuPosition.under,
      onSelected: (index) => items[index].onTap(),
      itemBuilder: (context) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(
                  items[i].icon,
                  size: 18,
                  color: items[i].isDestructive ? AppColors.errorRed : textCol,
                ),
                const SizedBox(width: AppSpacing.md - 4),
                Text(
                  items[i].label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: items[i].isDestructive
                        ? AppColors.errorRed
                        : textCol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
