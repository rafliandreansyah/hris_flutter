import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_employee_picker_modal.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal Form untuk Alih Tangan / Oper Fasilitas ke Rekan Kerja (POST /api/v1/assets/:id/transfer)
class AssetDirectTransferModal extends StatefulWidget {
  final AssetDetailData asset;
  final Future<void> Function(DirectTransferAssetPayload payload) onSubmit;

  const AssetDirectTransferModal({
    super.key,
    required this.asset,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required AssetDetailData asset,
    required Future<void> Function(DirectTransferAssetPayload payload) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Sheet ini menggambar drag handle sendiri; matikan handle bawaan tema agar tidak ganda
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AssetDirectTransferModal(
          asset: asset,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<AssetDirectTransferModal> createState() =>
      _AssetDirectTransferModalState();
}

class _AssetDirectTransferModalState extends State<AssetDirectTransferModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  EmployeeDirectoryItem? _targetEmployee;
  DateTime _assignedDate = DateTime.now();
  DateTime? _expectedReturnDate;
  String _condition = 'GOOD';
  bool _requireApproval = true;
  bool _isSubmitting = false;

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetEmployee() async {
    final currentHolderId = widget.asset.activeAssignment?.employeeId;
    final emp = await AssetEmployeePickerModal.show(
      context,
      title: 'Pilih Rekan Kerja Penerima',
      excludeEmployeeId: currentHolderId,
    );
    if (emp != null && mounted) {
      setState(() {
        _targetEmployee = emp;
      });
    }
  }

  Future<void> _pickAssignedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assignedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _assignedDate = picked;
      });
    }
  }

  Future<void> _pickExpectedReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expectedReturnDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _expectedReturnDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_targetEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rekan kerja yang akan menerima fasilitas'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = DirectTransferAssetPayload(
      targetEmployeeId: _targetEmployee!.id,
      assignedDate: _assignedDate,
      expectedReturnDate: _expectedReturnDate,
      conditionOnCheckout: _condition,
      checkoutNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      requireApproval: _requireApproval,
    );

    try {
      await widget.onSubmit(payload);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Error handled by caller
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: borderCol,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alih Tangan Fasilitas ke Rekan Kerja',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textCol,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.asset.name} (${widget.asset.assetCode})',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Selector Rekan Kerja (Mandatory *)
                    RichText(
                      text: TextSpan(
                        text: 'Rekan Kerja Penerima',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textCol,
                        ),
                        children: const [
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
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: _selectTargetEmployee,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackgroundSubtle
                              : AppColors.backgroundSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _targetEmployee == null
                                ? borderCol
                                : AppColors.brandTeal,
                            width: _targetEmployee == null ? 1 : 1.5,
                          ),
                        ),
                        child: _targetEmployee == null
                            ? Row(
                                children: [
                                  const Icon(
                                    LucideIcons.userCheck,
                                    size: 18,
                                    color: AppColors.brandTeal,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Pilih rekan kerja penerima...',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: subtitleCol,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(LucideIcons.chevronRight, size: 16),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: EmployeeInfoRow(
                                      employee: _targetEmployee,
                                      avatarSize: 40,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.x, size: 16),
                                    onPressed: () {
                                      setState(() => _targetEmployee = null);
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Tanggal Alih Tangan (Mandatory *)
                    RichText(
                      text: TextSpan(
                        text: 'Tanggal Alih Tangan',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textCol,
                        ),
                        children: const [
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
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickAssignedDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderCol),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 18,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _dateFormat.format(_assignedDate),
                              style: AppTypography.bodySmall.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(LucideIcons.chevronDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2b. Estimasi Tanggal Pengembalian (Opsional)
                    Text(
                      'Estimasi Tanggal Pengembalian (Opsional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickExpectedReturnDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderCol),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendarCheck,
                              size: 18,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _expectedReturnDate != null
                                    ? _dateFormat.format(_expectedReturnDate!)
                                    : 'Pilih tanggal pengembalian...',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _expectedReturnDate != null
                                      ? textCol
                                      : subtitleCol,
                                  fontWeight: _expectedReturnDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_expectedReturnDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => _expectedReturnDate = null);
                                },
                                child: const Icon(LucideIcons.x, size: 16),
                              )
                            else
                              const Icon(LucideIcons.chevronDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Kondisi Fisik Saat Alih Tangan
                    Text(
                      'Kondisi Fisik Saat Alih Tangan',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildConditionChip('NEW', 'Baru'),
                        _buildConditionChip('GOOD', 'Baik'),
                        _buildConditionChip('FAIR', 'Cukup'),
                        _buildConditionChip('DAMAGED', 'Rusak'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Catatan Alih Tangan
                    AppTextField(
                      controller: _notesController,
                      label: 'Catatan Alih Tangan',
                      hintText: 'Misal: Diserahkan lengkap dengan charger dan kabel...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 5. Toggle Persetujuan Penerima
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _requireApproval,
                      onChanged: (val) {
                        setState(() => _requireApproval = val);
                      },
                      activeThumbColor: AppColors.brandTeal,
                      title: Text(
                        'Membutuhkan Konfirmasi Penerima',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textCol,
                        ),
                      ),
                      subtitle: Text(
                        _requireApproval
                            ? 'Fasilitas akan berstatus Menunggu Konfirmasi sampai disetujui rekan kerja.'
                            : 'Fasilitas akan langsung dialihkan secara instan.',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: 'Kirim Alih Tangan',
                    leadingIcon: LucideIcons.arrowRightLeft,
                    isLoading: _isSubmitting,
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionChip(String value, String label) {
    final isSelected = _condition == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _condition = value);
        }
      },
      selectedColor: AppColors.accentTealLight,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.primaryHover : null,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
