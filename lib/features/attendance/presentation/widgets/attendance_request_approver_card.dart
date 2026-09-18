import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

/// Card 4: Approver Profile Card (Pejabat Penerima Otorisasi)
/// Sesuai spesifikasi Google Stitch Screen ID: `c0c581134c61461a8585cf77a66f1dd7`.
class AttendanceRequestApproverCard extends StatelessWidget {
  final AttendanceRequestEmployeeModel? approver;

  const AttendanceRequestApproverCard({super.key, this.approver});

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

    final app = approver;

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
            'PEJABAT PENERIMA OTORISASI',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (app == null) ...[
            Text(
              'Belum ada approver yang ditugaskan.',
              style: AppTypography.bodySmall.copyWith(color: subtitleCol),
            ),
          ] else ...[
            Row(
              children: [
                _buildAvatar(app, isDark, borderCol),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.fullName.isNotEmpty ? app.fullName : 'Approver',
                        style: AppTypography.titleMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (app.position?.name != null &&
                              app.position!.name.isNotEmpty)
                            app.position!.name,
                          if (app.department?.name != null &&
                              app.department!.name.isNotEmpty)
                            app.department!.name,
                        ].join(' • '),
                        style: AppTypography.labelMedium.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${app.company?.name ?? 'Oasis Corp'} • ID: ${app.employeeNumber ?? (app.id.length > 8 ? app.id.substring(0, 8) : app.id)}',
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
        ],
      ),
    );
  }

  Widget _buildAvatar(
    AttendanceRequestEmployeeModel app,
    bool isDark,
    Color borderCol,
  ) {
    final photo = app.photoUrl;
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
              errorWidget: (_, _, _) => _buildInitials(app),
              placeholder: (_, _) => _buildInitials(app),
            )
          : _buildInitials(app),
    );
  }

  Widget _buildInitials(AttendanceRequestEmployeeModel app) {
    return Center(
      child: Text(
        app.initials,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF0F766E),
        ),
      ),
    );
  }
}
