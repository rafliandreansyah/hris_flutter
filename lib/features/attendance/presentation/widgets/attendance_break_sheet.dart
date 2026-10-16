import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_break.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet konfirmasi mulai / selesai istirahat dengan catatan opsional.
///
/// Mengembalikan catatan (bisa string kosong) bila dikonfirmasi, atau `null`
/// bila dibatalkan.
Future<String?> showAttendanceBreakSheet(
  BuildContext context, {
  required bool isEnding,
  required bool isGpsReady,
  AttendanceBreakStatus? status,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => AttendanceBreakSheet(
      isEnding: isEnding,
      isGpsReady: isGpsReady,
      status: status,
    ),
  );
}

class AttendanceBreakSheet extends StatefulWidget {
  final bool isEnding;
  final bool isGpsReady;
  final AttendanceBreakStatus? status;

  const AttendanceBreakSheet({
    super.key,
    required this.isEnding,
    required this.isGpsReady,
    this.status,
  });

  @override
  State<AttendanceBreakSheet> createState() => _AttendanceBreakSheetState();
}

class _AttendanceBreakSheetState extends State<AttendanceBreakSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final textSecondary =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final brand = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final insetBottom = MediaQuery.of(context).viewInsets.bottom;

    final title = widget.isEnding ? 'Selesai Istirahat' : 'Mulai Istirahat';
    final subtitle = widget.isEnding
        ? 'Akhiri istirahat Anda dan kembali bekerja.'
        : 'Waktu istirahat akan dicatat sejak sekarang.';

    final allocated = widget.status?.allocatedBreakMinutes;
    final used = widget.status?.totalBreakMinutes ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md + insetBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.coffee, size: 18, color: brand),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(color: textSecondary),
          ),
          if (allocated != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Jatah istirahat: $allocated menit • terpakai $used menit',
              key: const ValueKey('attendance_break_sheet_allowance'),
              style: AppTypography.bodySmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Catatan (opsional)',
            hintText: 'Mis. makan siang, salat',
            controller: _noteController,
            prefixIcon: LucideIcons.messageSquare,
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            key: const ValueKey('attendance_break_sheet_gps'),
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: (widget.isGpsReady ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md + 4),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isGpsReady ? LucideIcons.mapPin : LucideIcons.mapPinOff,
                  size: 16,
                  color: widget.isGpsReady ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.isGpsReady
                        ? 'Lokasi terdeteksi'
                        : 'Menunggu lokasi GPS. Aktifkan GPS untuk melanjutkan.',
                    style: AppTypography.bodySmall.copyWith(color: textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Batal',
                  variant: AppButtonVariant.outlined,
                  height: 50,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: AppButton(
                  text: title,
                  height: 50,
                  leadingIcon: widget.isEnding ? LucideIcons.play : LucideIcons.coffee,
                  onPressed: widget.isGpsReady ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
