import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceEmployeeCard extends StatelessWidget {
  final String employeeName;
  final String employeeRole;
  final String employeeId;
  final String? photoUrl;
  final String officeName;
  final String officeDetail;
  final double geofenceRadiusMeters;
  final List<WorkLocationItem> availableWorkLocations;
  final WorkLocationItem? selectedWorkLocation;
  final ValueChanged<WorkLocationItem>? onLocationChanged;

  const AttendanceEmployeeCard({
    super.key,
    this.employeeName = 'Alex Rivera',
    this.employeeRole = 'Senior Product Designer',
    this.employeeId = '8829',
    this.photoUrl,
    this.officeName = 'Jakarta HQ Office',
    this.officeDetail = 'HQ Office — Main Lobby',
    this.geofenceRadiusMeters = 50.0,
    this.availableWorkLocations = const [],
    this.selectedWorkLocation,
    this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textPrimary =
        isDark ? AppColors.darkOnSurface : AppColors.onBackground;
    final textSecondary =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Info Row
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.surfaceContainerHigh,
                  border: Border.all(color: borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
              const SizedBox(width: 14),

              // Name & Role/ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: AppTypography.titleMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$employeeRole • ID: $employeeId',
                      style: AppTypography.bodyMedium.copyWith(
                        color: textSecondary,
                        fontSize: 13,
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

          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: borderColor,
          ),
          const SizedBox(height: 14),

          // Work Location Selector / Info Row
          _buildWorkLocationSection(context, isDark, textPrimary, textSecondary, borderColor),
        ],
      ),
    );
  }

  Widget _buildWorkLocationSection(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    // Poin 4: No work locations
    if (availableWorkLocations.isEmpty || selectedWorkLocation == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.mapPinOff,
            size: 20,
            color: AppColors.errorRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi Kerja Tidak Tersedia',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hubungi admin untuk mengatur lokasi kerja Anda',
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final hasMultiple = availableWorkLocations.length > 1;

    return InkWell(
      onTap: hasMultiple ? () => _showWorkLocationPicker(context, isDark) : null,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.building2,
            size: 20,
            color: textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedWorkLocation!.name,
                        style: AppTypography.labelMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasMultiple)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.brandTeal,
                        ),
                      ),
                  ],
                ),
                if (selectedWorkLocation!.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    selectedWorkLocation!.address,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Badge: Anywhere atau Radius
                    if (selectedWorkLocation!.isAnyWhere)
                      _buildBadge('Anywhere', AppColors.brandTeal)
                    else
                      _buildBadge(
                        'Radius: ${selectedWorkLocation!.radius.toStringAsFixed(0)}m',
                        textSecondary,
                      ),
                    if (selectedWorkLocation!.isDefault) ...[
                      const SizedBox(width: 6),
                      _buildBadge('Default', AppColors.brandTeal),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showWorkLocationPicker(BuildContext context, bool isDark) {
    final borderColor = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Lokasi Kerja',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih lokasi kerja untuk absensi hari ini',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.surfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ...availableWorkLocations.map((loc) {
                final isSelected = selectedWorkLocation?.id == loc.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onLocationChanged?.call(loc);
                        Navigator.pop(sheetContext);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandTeal.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandTeal.withValues(alpha: 0.4)
                                : borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              loc.isAnyWhere
                                  ? LucideIcons.globe
                                  : LucideIcons.building2,
                              size: 22,
                              color: isSelected
                                  ? AppColors.brandTeal
                                  : (isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.surfaceVariant),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          loc.name,
                                          style: AppTypography.labelMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isSelected
                                                ? AppColors.brandTeal
                                                : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (loc.isDefault)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: _buildBadge('Default', AppColors.brandTeal),
                                        ),
                                    ],
                                  ),
                                  if (loc.address.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      loc.address,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkOnSurfaceVariant
                                            : AppColors.surfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.isAnyWhere
                                        ? 'Bisa absen di mana saja'
                                        : 'Radius: ${loc.radius.toStringAsFixed(0)}m',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.surfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                LucideIcons.circleCheck,
                                size: 20,
                                color: AppColors.brandTeal,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder() {
    final initials = employeeName.isNotEmpty
        ? employeeName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'AR';

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.brandTeal,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
