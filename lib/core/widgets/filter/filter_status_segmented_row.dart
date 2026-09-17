import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

/// Opsi pilihan status untuk [FilterStatusSegmentedRow].
class FilterStatusOption {
  final String label;
  final String value;

  const FilterStatusOption({
    required this.label,
    required this.value,
  });

  /// 4 Opsi status default untuk seluruh modul pengajuan (Presensi, Cuti, Lembur).
  static const List<FilterStatusOption> defaultRequestStatusOptions = [
    FilterStatusOption(label: 'Semua', value: 'all'),
    FilterStatusOption(label: 'Diajukan', value: 'requested'),
    FilterStatusOption(label: 'Approved', value: 'approved'),
    FilterStatusOption(label: 'Rejected', value: 'rejected'),
  ];
}

/// Baris status segmented chips horizontal proporsional sesuai standar Stitch M3 "Teal Oasis".
class FilterStatusSegmentedRow extends StatelessWidget {
  final String title;
  final List<FilterStatusOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final String? helperText;

  const FilterStatusSegmentedRow({
    super.key,
    this.title = 'Status Pengajuan',
    this.options = FilterStatusOption.defaultRequestStatusOptions,
    required this.selectedValue,
    required this.onSelected,
    this.helperText = 'Default memuat status pengajuan diminta (requested)',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final fieldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: textCol,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildChip(
                  option: options[i],
                  isDark: isDark,
                  brandColor: brandColor,
                  labelCol: labelCol,
                  borderCol: borderCol,
                  fieldBg: fieldBg,
                ),
              ),
            ],
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: AppTypography.labelSmall.copyWith(
              color: labelCol,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required FilterStatusOption option,
    required bool isDark,
    required Color brandColor,
    required Color labelCol,
    required Color borderCol,
    required Color fieldBg,
  }) {
    final isSelected =
        option.value.toLowerCase() == selectedValue.toLowerCase();
    final chipBg = isSelected
        ? (isDark
            ? brandColor.withValues(alpha: 0.18)
            : const Color(0xFFF0FDFA))
        : fieldBg;
    final chipBorder = isSelected ? brandColor : borderCol;
    final chipTextCol =
        isSelected ? (isDark ? brandColor : const Color(0xFF0D9488)) : labelCol;

    return InkWell(
      onTap: () => onSelected(option.value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          option.label,
          style: AppTypography.bodySmall.copyWith(
            color: chipTextCol,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
