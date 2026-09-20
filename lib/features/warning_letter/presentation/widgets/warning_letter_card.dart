import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card item Surat Peringatan sesuai desain Google Stitch M3 "Teal Oasis".
///
/// Memanfaatkan [EmployeeInfoRow] untuk identitas pegawai yang konsisten
/// dengan modul pengajuan lainnya (Absen Luar, Cuti, Lembur, Aktivitas).
class WarningLetterCard extends StatelessWidget {
  final WarningLetterItem item;
  final VoidCallback? onTap;

  const WarningLetterCard({
    super.key,
    required this.item,
    this.onTap,
  });

  /// Badge level SP (SP 1, SP 2, SP 3) dengan variasi warna sesuai tingkat keparahan.
  Widget _buildLevelBadge(bool isDark) {
    Color bg;
    Color text;

    switch (item.warningLetterType.level) {
      case 1:
        bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
        text = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        break;
      case 2:
        bg = isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5);
        text = isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
        break;
      case 3:
      default:
        bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
        text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        item.levelBadgeLabel,
        style: TextStyle(
          color: text,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Status badge aktif / tidak aktif
  Widget _buildStatusBadge(bool isDark) {
    final isActive = item.isActive;
    final bg = isActive
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final text = isActive
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final dot = isActive
        ? const Color(0xFF10B981)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Aktif' : 'Tidak Aktif',
            style: TextStyle(
              color: text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtleCol = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final brandColor =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);

    final employee = item.employee;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceCol,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Baris Identitas Pegawai + Level Badge ─────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: EmployeeInfoRow(
                      name: employee?.fullName ?? 'Pegawai',
                      role: employee?.position?.name ?? '',
                      department: employee?.department?.name ?? '',
                      company: employee?.company?.name,
                      employeeId: employee?.employeeNumber ??
                          employee?.idNumber ??
                          '',
                      avatarUrl: employee?.photoUrl,
                      initials: employee?.initials,
                      avatarSize: 42,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildLevelBadge(isDark),
                      const SizedBox(height: 6),
                      _buildStatusBadge(isDark),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── 2. Box Info Dokumen & Jenis Pelanggaran/SP ─────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: subtleCol,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineMuted.withValues(alpha: 0.5)
                        : const Color(0xFFF1F5F9),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.fileText,
                        color: brandColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.warningLetterType.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID Dokumen: ${item.id.length > 18 ? '${item.id.substring(0, 18)}...' : item.id} • Zona: ${item.timezone}',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 3. Footer: Tanggal Dibuat & Aksi Lihat Rincian ─────────
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: subtitleCol,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.formattedCreatedAt,
                              style: AppTypography.bodySmall.copyWith(
                                color: subtitleCol,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Rincian',
                          style: AppTypography.labelMedium.copyWith(
                            color: brandColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: brandColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
