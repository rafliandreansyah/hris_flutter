import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card item Surat Peringatan sesuai desain Google Stitch M3 "Teal Oasis".
///
/// Memakai [RequestListCardFrame] + [RequestCardHeader] agar seragam dengan
/// modul pengajuan lainnya (Absen Luar, Cuti, Lembur, Aktivitas).
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
        bg = isDark ? const Color(0xFF451A03) : AppColors.warningContainer;
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
  Widget _buildStatusBadge(bool isDark) => item.isActive
      ? const AppStatusChip(label: 'Aktif', tone: AppStatusTone.success)
      : const AppStatusChip(label: 'Tidak Aktif');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employee = item.employee;

    return RequestListCardFrame(
      onTap: onTap,
      header: RequestCardHeader(
        name: employee?.fullName ?? 'Pegawai',
        role: employee?.position?.name ?? '',
        department: employee?.department?.name ?? '',
        avatarUrl: employee?.resolvedAvatarUrl,
        initials: employee?.initials,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildLevelBadge(isDark),
            const SizedBox(height: 6),
            _buildStatusBadge(isDark),
          ],
        ),
      ),
      children: [
        RequestCardInfoLine(
          icon: LucideIcons.fileText,
          text: item.warningLetterType.name,
          emphasize: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        RequestCardInfoLine(
          icon: LucideIcons.calendar,
          text: item.formattedCreatedAt,
        ),
      ],
    );
  }
}
