import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

class ResignationEarlyNoticeCard extends StatelessWidget {
  final int requiredNoticeDays;
  final int actualDaysDiff;
  final bool isEarlyNotice;
  final String earlyNoticeReason;
  final ValueChanged<bool> onEarlyWaiverChanged;
  final ValueChanged<String> onReasonChanged;

  const ResignationEarlyNoticeCard({
    super.key,
    required this.requiredNoticeDays,
    required this.actualDaysDiff,
    required this.isEarlyNotice,
    required this.earlyNoticeReason,
    required this.onEarlyWaiverChanged,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final cardBg = isDark
        ? const Color(0xFF78350F).withValues(alpha: 0.2)
        : const Color(0xFFFFFBEB);
    final cardBorder = isDark
        ? const Color(0xFF92400E).withValues(alpha: 0.5)
        : const Color(0xFFFDE68A);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Warning Alert Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.triangleAlert,
                size: 20,
                color: warningColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notice Period Di Bawah $requiredNoticeDays Hari',
                      style: AppTypography.titleSmall.copyWith(
                        color: warningColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Tanggal yang dipilih berjarak '),
                          TextSpan(
                            text: '$actualDaysDiff Hari Kerja',
                            style: TextStyle(
                              color: warningColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' dari hari pengajuan. Membutuhkan persetujuan manajerial khusus.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Early Waiver Checkbox Card ──
          InkWell(
            onTap: () => onEarlyWaiverChanged(!isEarlyNotice),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEarlyNotice
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.fastForward,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ajukan Percepatan Tanggal Efektif (Early Waiver)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isEarlyNotice,
                    onChanged: (val) => onEarlyWaiverChanged(val ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Reason Input if Waiver Toggled ──
          if (isEarlyNotice) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(text: 'Alasan Percepatan Pengunduran Diri'),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Wajib diisi',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.errorRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: earlyNoticeReason,
              maxLines: 2,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText:
                    'Jelaskan alasan pengajuan tanggal efektif lebih awal...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: onReasonChanged,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: 4),
            Text(
              'Wajib diisi jika mengajukan kurang dari $requiredNoticeDays hari.',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
