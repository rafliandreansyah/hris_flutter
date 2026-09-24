import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal Bottom Sheet untuk Penolakan Penyerahan Fasilitas.
/// Sesuai Stitch Screen: "Oasish Tolak Penyerahan Fasilitas Modal"
/// (ID: ba7f392bdb3c4ba88c132a064abb4a93).
class AssetRejectBottomSheet extends StatefulWidget {
  final AssetListItem asset;
  final Future<void> Function(String reason) onReject;

  const AssetRejectBottomSheet({
    super.key,
    required this.asset,
    required this.onReject,
  });

  /// Menampilkan modal bottom sheet penolakan fasilitas
  static Future<bool?> show(
    BuildContext context, {
    required AssetListItem asset,
    required Future<void> Function(String reason) onReject,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssetRejectBottomSheet(
        asset: asset,
        onReject: onReject,
      ),
    );
  }

  @override
  State<AssetRejectBottomSheet> createState() => _AssetRejectBottomSheetState();
}

class _AssetRejectBottomSheetState extends State<AssetRejectBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _selectedChipReason;

  static const List<String> _quickReasons = [
    'Barang dalam kondisi cacat / rusak fisik saat diserahkan.',
    'Salah penerima, aset ini bukan alokasi untuk unit kerja saya.',
    'Kelengkapan aksesori atau dokumen aset tidak sesuai checklist.',
    'Spesifikasi tidak memadai untuk kebutuhan tugas harian.',
  ];

  static const List<String> _quickReasonLabels = [
    'Barang cacat / rusak',
    'Salah penerima',
    'Kelengkapan tidak sesuai',
    'Tidak sesuai kebutuhan',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isValid => _reasonController.text.trim().length >= 5;

  Future<void> _handleReject() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onReject(_reasonController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final cardBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    final mediaQuery = MediaQuery.of(context);
    final initiatorName =
        widget.asset.transferredFrom?.employeeName ?? 'Pemegang sebelumnya';
    final currentLength = _reasonController.text.trim().length;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderCol,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header Modal Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.triangleAlert,
                        size: 20,
                        color: AppColors.errorRed,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tolak Penyerahan',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Konfirmasi pembatalan serah terima',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 20, color: subtitleCol),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 3. Konten Modal
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning Banner Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.triangleAlert,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF92400E),
                                  height: 1.45,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Perhatian: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(
                                    text:
                                        'Setelah ditolak, fasilitas ini akan tetap menjadi tanggung jawab pemegang sebelumnya (',
                                  ),
                                  TextSpan(
                                    text: initiatorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        '). Anda tidak akan menerima aset ini.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Ringkasan Kartu Aset
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.brandTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppColors.brandTeal.withValues(alpha: 0.2),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              widget.asset.categoryIcon,
                              size: 22,
                              color: AppColors.brandTeal,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.asset.name,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: textCol,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.asset.assetCode +
                                      (widget.asset.serialNumber != null
                                          ? ' • Seri ${widget.asset.serialNumber}'
                                          : ''),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (widget.asset.transferredFrom != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Dari',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        widget.asset.transferredFrom!.initials,
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.brandTeal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.asset.transferredFrom!.shortName,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: textCol,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Label Alasan Penolakan dengan Asterisk Merah
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textCol,
                            ),
                            children: const [
                              TextSpan(text: 'Alasan Penolakan'),
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
                        Text(
                          'Wajib diisi',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Textarea Input
                    TextField(
                      controller: _reasonController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      maxLength: 500,
                      buildCounter: (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      style: AppTypography.bodyMedium.copyWith(color: textCol),
                      decoration: InputDecoration(
                        hintText:
                            'Jelaskan alasan Anda menolak penerimaan fasilitas ini secara rinci (min. 5 karakter)...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: subtitleCol.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.all(14),
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
                          borderSide: const BorderSide(
                            color: AppColors.errorRed,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Counter & Syarat Karakter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 14,
                              color: currentLength < 5 && currentLength > 0
                                  ? AppColors.errorRed
                                  : subtitleCol,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Min. 5 karakter',
                              style: AppTypography.labelSmall.copyWith(
                                color: currentLength < 5 && currentLength > 0
                                    ? AppColors.errorRed
                                    : subtitleCol,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$currentLength / 500',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Pilihan Alasan Cepat Chips
                    Text(
                      'Pilihan Alasan Cepat:',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_quickReasons.length, (index) {
                        final reasonText = _quickReasons[index];
                        final label = _quickReasonLabels[index];
                        final isSelected = _selectedChipReason == reasonText;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedChipReason = reasonText;
                              _reasonController.text = reasonText;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.errorRed.withValues(alpha: 0.1)
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.errorRed
                                    : borderCol,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              label,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? AppColors.errorRed
                                    : textCol,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // 4. Footer Docked Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(top: BorderSide(color: borderCol)),
                ),
                child: Column(
                  children: [
                    AppButton(
                      text: 'Tolak Penyerahan',
                      leadingIcon: LucideIcons.circleX,
                      isLoading: _isSubmitting,
                      onPressed: _isValid ? _handleReject : null,
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      height: 48,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal, Kembali',
                        style: AppTypography.bodyMedium.copyWith(
                          color: subtitleCol,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
