import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal dialog konfirmasi untuk menyetujui atau menolak permohonan presensi luar kantor
/// dilengkapi input catatan approver (*approverNotes*).
class AttendanceRequestActionDialog extends StatefulWidget {
  final bool isApproved;

  const AttendanceRequestActionDialog({super.key, required this.isApproved});

  static Future<String?> show(
    BuildContext context, {
    required bool isApproved,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AttendanceRequestActionDialog(isApproved: isApproved),
    );
  }

  @override
  State<AttendanceRequestActionDialog> createState() =>
      _AttendanceRequestActionDialogState();
}

class _AttendanceRequestActionDialogState
    extends State<AttendanceRequestActionDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final primaryActionColor = widget.isApproved
        ? (isDark ? AppColors.inversePrimary : AppColors.brandTeal)
        : const Color(0xFFEF4444);

    final titleText = widget.isApproved
        ? 'Setujui Presensi Luar Kantor'
        : 'Tolak Presensi Luar Kantor';
    final descText = widget.isApproved
        ? 'Apakah Anda yakin ingin menyetujui permohonan presensi luar kantor ini? Anda dapat menyertakan catatan persetujuan (opsional).'
        : 'Apakah Anda yakin ingin menolak permohonan presensi luar kantor ini? Anda dapat menyertakan alasan penolakan.';

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryActionColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isApproved ? LucideIcons.check : LucideIcons.x,
                    color: primaryActionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titleText,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textCol,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              descText,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Textfield Catatan
            Text(
              'Catatan Approver ${widget.isApproved ? "(Opsional)" : ""}',
              style: AppTypography.labelSmall.copyWith(
                color: textCol,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: AppTypography.bodyMedium.copyWith(color: textCol),
              decoration: InputDecoration(
                hintText: widget.isApproved
                    ? 'Tulis catatan persetujuan...'
                    : 'Tulis alasan penolakan presensi...',
                hintStyle: AppTypography.bodySmall.copyWith(color: subtitleCol),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderCol),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderCol),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryActionColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            // Footer Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: widget.isApproved ? 'Setujui' : 'Tolak',
                    variant: widget.isApproved
                        ? AppButtonVariant.primary
                        : AppButtonVariant.danger,
                    onPressed: () {
                      final notes = _notesController.text.trim();
                      Navigator.of(context).pop(notes);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
