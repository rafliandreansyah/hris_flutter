import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_photo_picker_card.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Data hasil input pengembalian kasbon (refund).
class CashAdvanceRefundInput {
  final double amount;
  final String paymentMethod;
  final String? notes;
  final XFile? receiptFile;

  const CashAdvanceRefundInput({
    required this.amount,
    required this.paymentMethod,
    this.notes,
    this.receiptFile,
  });
}

/// Dialog input pengembalian dana sisa kasbon (*refund*).
class CashAdvanceRefundDialog extends StatefulWidget {
  final double maxAmount;

  const CashAdvanceRefundDialog({super.key, required this.maxAmount});

  static Future<CashAdvanceRefundInput?> show(
    BuildContext context, {
    required double maxAmount,
  }) {
    return showDialog<CashAdvanceRefundInput>(
      context: context,
      builder: (context) => CashAdvanceRefundDialog(maxAmount: maxAmount),
    );
  }

  @override
  State<CashAdvanceRefundDialog> createState() =>
      _CashAdvanceRefundDialogState();
}

class _CashAdvanceRefundDialogState extends State<CashAdvanceRefundDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'transfer'; // 'transfer' | 'cash'
  XFile? _receiptFile;
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final rawText = _amountController.text
        .replaceAll(RegExp(r'[^0-9]'), '');
    final parsedAmount = double.tryParse(rawText);

    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() {
        _amountError = 'Masukkan nominal pengembalian yang valid';
      });
      return;
    }

    if (parsedAmount > widget.maxAmount) {
      setState(() {
        _amountError =
            'Nominal melebihi sisa kasbon (${formatRupiah(widget.maxAmount)})';
      });
      return;
    }

    Navigator.of(context).pop(
      CashAdvanceRefundInput(
        amount: parsedAmount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        receiptFile: _receiptFile,
      ),
    );
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
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.handCoins,
                        color: brandColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kembalikan Sisa Kasbon',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Maks. sisa: ${formatRupiah(widget.maxAmount)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleCol,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Nominal
                AppTextField(
                  label: 'Nominal Pengembalian (Rp) *',
                  hintText: 'Contoh: 250000',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.wallet,
                  onChanged: (val) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
                if (_amountError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _amountError!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Metode Pengembalian
                Text(
                  'Metode Pengembalian *',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMethodRadio(
                        title: 'Transfer Bank',
                        icon: LucideIcons.arrowLeftRight,
                        value: 'transfer',
                        isSelected: _paymentMethod == 'transfer',
                        onTap: () => setState(() => _paymentMethod = 'transfer'),
                        isDark: isDark,
                        brandColor: brandColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMethodRadio(
                        title: 'Tunai (Cash)',
                        icon: LucideIcons.banknote,
                        value: 'cash',
                        isSelected: _paymentMethod == 'cash',
                        onTap: () => setState(() => _paymentMethod = 'cash'),
                        isDark: isDark,
                        brandColor: brandColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Catatan
                AppTextField(
                  label: 'Catatan (Opsional)',
                  hintText: 'Keterangan pengembalian sisa dana...',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                // Bukti Nota / Kwitansi
                Text(
                  'Bukti Pengembalian (Foto / Struk)',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 8),
                AppPhotoPickerCard(
                  file: _receiptFile,
                  uploadPlaceholderTitle: 'Tap untuk Upload Bukti',
                  uploadPlaceholderSubtitle:
                      'Foto bukti transfer atau kwitansi tunai (Maks 100 KB)',
                  onFileChanged: (file, _) {
                    setState(() => _receiptFile = file);
                  },
                ),
                const SizedBox(height: 20),

                // Action Buttons
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
                        text: 'Kirim',
                        variant: AppButtonVariant.primary,
                        height: 44,
                        borderRadius: 12,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodRadio({
    required String title,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color brandColor,
  }) {
    final borderCol = isSelected
        ? brandColor
        : (isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted);
    final bgCol = isSelected
        ? brandColor.withValues(alpha: isDark ? 0.15 : 0.08)
        : (isDark ? AppColors.darkSurfaceContainer : AppColors.backgroundSubtle);
    final textCol = isSelected
        ? brandColor
        : (isDark ? AppColors.darkOnSurface : AppColors.onSurface);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textCol),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textCol,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
