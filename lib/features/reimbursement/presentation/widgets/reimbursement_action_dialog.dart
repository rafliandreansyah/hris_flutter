import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal dialog konfirmasi untuk menyetujui atau menolak pengajuan reimbursement atau kasbon
/// dilengkapi input catatan approver (*approverNotes*).
class ReimbursementActionDialog extends StatefulWidget {
  final bool isApproved;
  final String? title;
  final String? description;
  final String? notesHint;

  const ReimbursementActionDialog({
    super.key,
    required this.isApproved,
    this.title,
    this.description,
    this.notesHint,
  });

  static Future<String?> show(
    BuildContext context, {
    required bool isApproved,
    String? title,
    String? description,
    String? notesHint,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ReimbursementActionDialog(
        isApproved: isApproved,
        title: title,
        description: description,
        notesHint: notesHint,
      ),
    );
  }

  @override
  State<ReimbursementActionDialog> createState() =>
      _ReimbursementActionDialogState();
}

class _ReimbursementActionDialogState extends State<ReimbursementActionDialog> {
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

    final titleText = widget.title ??
        (widget.isApproved ? 'Setujui Pengajuan' : 'Tolak Pengajuan');
    final descText = widget.description ??
        (widget.isApproved
            ? 'Apakah Anda yakin ingin menyetujui pengajuan ini? Anda dapat menyertakan catatan tambahan (opsional).'
            : 'Apakah Anda yakin ingin menolak pengajuan ini? Anda dapat menyertakan alasan penolakan.');

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
            TextField(
              controller: _notesController,
              maxLines: 3,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: TextStyle(color: textCol, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: widget.notesHint ??
                    (widget.isApproved
                        ? 'Catatan persetujuan (opsional)...'
                        : 'Alasan penolakan (opsional)...'),
                hintStyle: TextStyle(color: subtitleCol, fontSize: 13),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
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
                  borderSide: BorderSide(color: primaryActionColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    variant: AppButtonVariant.outlined,
                    height: 44,
                    borderRadius: 12,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: widget.isApproved ? 'Setujui' : 'Tolak',
                    variant: widget.isApproved
                        ? AppButtonVariant.primary
                        : AppButtonVariant.danger,
                    height: 44,
                    borderRadius: 12,
                    onPressed: () {
                      Navigator.of(context).pop(_notesController.text.trim());
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
