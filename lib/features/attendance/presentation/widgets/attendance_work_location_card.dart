import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card untuk menampilkan dan memilih lokasi kerja karyawan dari `employeeWorkLocation`.
class AttendanceWorkLocationCard extends StatelessWidget {
  final WorkLocationItem? selectedLocation;
  final List<WorkLocationItem> availableLocations;
  final ValueChanged<WorkLocationItem>? onLocationChanged;

  const AttendanceWorkLocationCard({
    super.key,
    required this.selectedLocation,
    this.availableLocations = const [],
    this.onLocationChanged,
  });

  bool get _canSwitch => availableLocations.length > 1;

  void _showLocationSelectionBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkOutlineMuted
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Sheet
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Lokasi Kerja',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                Text(
                  'Pilih penugasan lokasi kerja untuk pencatatan presensi hari ini:',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // List Lokasi Kerja
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableLocations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = availableLocations[index];
                      final isSelected = item.id == selectedLocation?.id;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          if (!isSelected) {
                            onLocationChanged?.call(item);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandTeal.withValues(alpha: isDark ? 0.20 : 0.08)
                                : (isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceContainerLowest),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandTeal
                                  : (isDark
                                      ? AppColors.darkOutlineMuted
                                      : AppColors.outlineMuted),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Radio selection indicator
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  isSelected
                                      ? LucideIcons.circleDot
                                      : LucideIcons.circle,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.brandTeal
                                      : (isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.outlineMuted),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Detail Lokasi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: AppTypography.titleSmall.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? AppColors.brandTeal
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (item.isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandTeal
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.brandTeal,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (item.address.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.address,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkOnSurfaceVariant
                                              : AppColors.surfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (item.isAnyWhere)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.globe,
                                                  size: 11,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Bisa Absen di Mana Saja',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.darkSurfaceContainerHigh
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.radar,
                                                  size: 11,
                                                  color: isDark
                                                      ? AppColors.darkOnSurfaceVariant
                                                      : AppColors.surfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Radius: ${item.radius.toInt()}m',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? AppColors.darkOnSurfaceVariant
                                                        : AppColors.surfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final loc = selectedLocation;
    final hasLocation = loc != null;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Default Badge + Ganti Lokasi Button
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.building2,
                  size: 18,
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Lokasi Kerja',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.onBackground,
                      ),
                    ),
                    if (loc?.isDefault == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandTeal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Ganti Lokasi button if multiple locations available
              if (_canSwitch)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showLocationSelectionBottomSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.brandTeal.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.arrowLeftRight,
                            size: 12,
                            color: AppColors.brandTeal,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ganti Lokasi',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Location Name
          Text(
            hasLocation ? loc.name : 'Lokasi kerja tidak tersedia',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: hasLocation
                  ? (isDark ? AppColors.darkOnSurface : AppColors.onBackground)
                  : AppColors.errorRed,
            ),
          ),

          // Address
          if (hasLocation && loc.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              loc.address,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.surfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Tags row (Radius / isAnyWhere)
          if (hasLocation)
            Row(
              children: [
                if (loc.isAnyWhere)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.globe,
                          size: 12,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Bisa Absen di Mana Saja',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerHigh
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.radar,
                          size: 12,
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.surfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Radius Geofence: ${loc.radius.toInt()} meter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.surfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Text(
              'Belum ada lokasi kerja yang ditentukan oleh admin.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
