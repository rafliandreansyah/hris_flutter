import 'package:flutter/material.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_employee_picker_modal.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal Form untuk Serah Terima Unit dari Gudang Pool ke Karyawan (POST /api/v1/assets/:id/handover)
class AssetPoolHandoverModal extends StatefulWidget {
  final AssetDetailData asset;
  final Future<void> Function(HandoverAssetPayload payload) onSubmit;

  const AssetPoolHandoverModal({
    super.key,
    required this.asset,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required AssetDetailData asset,
    required Future<void> Function(HandoverAssetPayload payload) onSubmit,
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
        child: AssetPoolHandoverModal(
          asset: asset,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<AssetPoolHandoverModal> createState() => _AssetPoolHandoverModalState();
}

class _AssetPoolHandoverModalState extends State<AssetPoolHandoverModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  EmployeeDirectoryItem? _selectedEmployee;
  DateTime _assignedDate = DateTime.now();
  DateTime? _expectedReturnDate;
  String _condition = 'GOOD';
  bool _isSubmitting = false;

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectEmployee() async {
    final emp = await AssetEmployeePickerModal.show(
      context,
      title: 'Pilih Karyawan Penerima',
      selectedEmployeeId: _selectedEmployee?.id,
      source: AssetPickerSource.directory,
    );
    if (emp != null && mounted) {
      setState(() {
        _selectedEmployee = emp;
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
      initialDate: _expectedReturnDate ?? DateTime.now().add(const Duration(days: 30)),
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

    if (_selectedEmployee == null) {
      AppDialogUtil.showValidationError(
        context,
        message: 'Silakan pilih karyawan penerima fasilitas.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = HandoverAssetPayload(
      employeeId: _selectedEmployee!.id,
      assignedDate: _assignedDate,
      expectedReturnDate: _expectedReturnDate,
      conditionOnCheckout: _condition,
      checkoutNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      await widget.onSubmit(payload);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Error handled by BLoC listener in screen
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
                        'Serah Terima Fasilitas',
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
                    // 1. Selector Karyawan Penerima (Mandatory *)
                    RichText(
                      text: TextSpan(
                        text: 'Karyawan Penerima',
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
                      onTap: _selectEmployee,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackgroundSubtle
                              : AppColors.backgroundSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedEmployee == null
                                ? borderCol
                                : AppColors.brandTeal,
                            width: _selectedEmployee == null ? 1 : 1.5,
                          ),
                        ),
                        child: _selectedEmployee == null
                            ? Row(
                                children: [
                                  const Icon(
                                    LucideIcons.userPlus,
                                    size: 18,
                                    color: AppColors.brandTeal,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Pilih karyawan dari direktori...',
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
                                      employee: _selectedEmployee,
                                      avatarSize: 40,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.x, size: 16),
                                    onPressed: () {
                                      setState(() => _selectedEmployee = null);
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Tanggal Serah Terima (Mandatory *)
                    RichText(
                      text: TextSpan(
                        text: 'Tanggal Serah Terima',
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

                    // 3. Estimasi Pengembalian (Opsional)
                    Text(
                      'Estimasi Pengembalian (Opsional)',
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
                              LucideIcons.calendarClock,
                              size: 18,
                              color: AppColors.surfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _expectedReturnDate != null
                                  ? _dateFormat.format(_expectedReturnDate!)
                                  : 'Tidak ditentukan (Penggunaan Tetap)',
                              style: AppTypography.bodySmall.copyWith(
                                color: _expectedReturnDate != null
                                    ? textCol
                                    : subtitleCol,
                                fontWeight: _expectedReturnDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (_expectedReturnDate != null)
                              InkWell(
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

                    // 4. Kondisi Fisik Saat Keluar
                    Text(
                      'Kondisi Fisik Saat Keluar',
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

                    // 5. Catatan Serah Terima
                    AppTextField(
                      controller: _notesController,
                      label: 'Catatan Serah Terima',
                      hintText: 'Misal: Dilengkapi charger asli dan tas laptop...',
                      maxLines: 3,
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
                    text: 'Proses Serah Terima',
                    leadingIcon: LucideIcons.check,
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
