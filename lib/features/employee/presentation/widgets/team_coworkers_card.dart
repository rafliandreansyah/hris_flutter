import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CoworkerItem {
  final String name;
  final String role;
  final String initials;
  final String? phone;

  const CoworkerItem({
    required this.name,
    required this.role,
    required this.initials,
    this.phone,
  });
}

/// Kartu Rekan Kerja Satu Tim (Team Coworkers)
class TeamCoworkersCard extends StatelessWidget {
  final List<CoworkerItem> coworkers;
  final VoidCallback? onViewAll;

  const TeamCoworkersCard({
    super.key,
    this.coworkers = const [
      CoworkerItem(name: 'Budi Santoso', role: 'UI/UX Designer', initials: 'BS'),
      CoworkerItem(name: 'Jessica Pranata', role: 'QA Engineer', initials: 'JP'),
    ],
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final avatarBg = isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEAM COWORKERS (${coworkers.length + 1})',
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),

        // List Container
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(coworkers.length, (index) {
              final item = coworkers[index];
              final isLast = index == coworkers.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: avatarBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: borderCol),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.initials,
                                style: AppTypography.labelMedium.copyWith(
                                  color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: textCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  item.role,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: labelCol,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Call Action Button
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkBackgroundSubtle : const Color(0xFFF8FAFC),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Menghubungi ${item.name}...')),
                            );
                          },
                          icon: const Icon(
                            LucideIcons.phone,
                            size: 16,
                            color: AppColors.brandTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, thickness: 1, color: borderCol),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Outlined "Lihat Semua Rekan Kerja" Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.brandTeal, width: 1.2),
              shape: const StadiumBorder(),
              foregroundColor: AppColors.brandTeal,
            ),
            onPressed: onViewAll ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daftar lengkap rekan kerja segera dibuka')),
                  );
                },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lihat Semua Rekan Kerja (${coworkers.length + 1})',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
