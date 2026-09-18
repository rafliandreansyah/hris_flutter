import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

/// Card 3: Employee Profile Card (Pemohon Presensi)
/// Sesuai spesifikasi Google Stitch Screen ID: `c0c581134c61461a8585cf77a66f1dd7`.
class AttendanceRequestEmployeeCard extends StatelessWidget {
  final AttendanceRequestEmployeeModel employee;

  const AttendanceRequestEmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final tertiaryCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF94A3B8);

    final positionName = employee.position?.name ?? '';
    final deptName = employee.department?.name ?? '';
    final positionDept = [
      if (positionName.isNotEmpty) positionName,
      if (deptName.isNotEmpty) deptName,
    ].join(' • ');

    final companyName = employee.company?.name ?? 'Oasis Corp';
    final empNumber = employee.employeeNumber ??
        (employee.id.length > 8 ? employee.id.substring(0, 8) : employee.id);

    return Container(
      width: double.infinity,
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
          Text(
            'PEMOHON PRESENSI',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAvatar(isDark, borderCol),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName.isNotEmpty
                          ? employee.fullName
                          : 'Pegawai',
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                    if (positionDept.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        positionDept,
                        style: AppTypography.labelMedium.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '$companyName • ID: $empNumber',
                      style: AppTypography.labelSmall.copyWith(
                        color: tertiaryCol,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark, Color borderCol) {
    final photo = employee.photoUrl;
    final hasPhoto = photo != null && photo.trim().isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderCol),
        color: isDark
            ? AppColors.darkSurfaceContainerHigh
            : const Color(0xFFF1F5F9),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: photo,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _buildInitials(),
              placeholder: (_, _) => _buildInitials(),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        employee.initials,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.brandTeal,
        ),
      ),
    );
  }
}
