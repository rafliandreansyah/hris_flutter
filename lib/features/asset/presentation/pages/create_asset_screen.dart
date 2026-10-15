import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_state.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_employee_picker_modal.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Pendaftaran Master Unit Aset Baru (POST /api/v1/assets)
class CreateAssetScreen extends StatelessWidget {
  final AssetRepository? repository;

  const CreateAssetScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateAssetBloc>(
      create: (context) =>
          CreateAssetBloc(repository: repository)..add(const CreateAssetStarted()),
      child: const _CreateAssetView(),
    );
  }
}

class _CreateAssetView extends StatefulWidget {
  const _CreateAssetView();

  @override
  State<_CreateAssetView> createState() => _CreateAssetViewState();
}

class _CreateAssetViewState extends State<_CreateAssetView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCategoryId;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  String _condition = 'GOOD';
  EmployeeDirectoryItem? _directAssignee;

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _costController.dispose();
    _vendorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _pickWarrantyExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _warrantyExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null && mounted) {
      setState(() => _warrantyExpiry = picked);
    }
  }

  Future<void> _selectDirectAssignee() async {
    final emp = await AssetEmployeePickerModal.show(
      context,
      title: 'Pilih Karyawan (Langsung Ditugaskan)',
    );
    if (emp != null && mounted) {
      setState(() => _directAssignee = emp);
    }
  }

  void _handleSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori aset')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    double? cost;
    if (_costController.text.trim().isNotEmpty) {
      final sanitized = _costController.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll('Rp', '')
          .trim();
      cost = double.tryParse(sanitized);
    }

    final payload = CreateAssetPayload(
      categoryId: _selectedCategoryId!,
      assetCode: _codeController.text.trim(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isNotEmpty
          ? _brandController.text.trim()
          : null,
      model: _modelController.text.trim().isNotEmpty
          ? _modelController.text.trim()
          : null,
      serialNumber: _serialController.text.trim().isNotEmpty
          ? _serialController.text.trim()
          : null,
      purchaseDate: _purchaseDate,
      purchaseCost: cost,
      warrantyExpiry: _warrantyExpiry,
      vendor: _vendorController.text.trim().isNotEmpty
          ? _vendorController.text.trim()
          : null,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'Gudang Inventaris Utama',
      condition: _condition,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      assignedToEmployeeId: _directAssignee?.id,
    );

    context.read<CreateAssetBloc>().add(CreateAssetSubmitted(payload));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return BlocConsumer<CreateAssetBloc, CreateAssetState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {
          AppDialogUtil.showSuccess(
            context,
            message: state.successMessage!,
            onOk: () => Navigator.of(context).pop(true),
          );
        } else if (state.errorMessage != null && !state.isSubmitting) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: bgCol.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 1.5,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: textCol,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            titleSpacing: 0,
            title: Text(
              'Daftarkan Aset Baru',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 18,
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                text: 'Daftarkan Aset',
                leadingIcon: LucideIcons.plus,
                isLoading: state.isSubmitting,
                onPressed: _handleSubmit,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dropdown Kategori Aset (Mandatory *)
                  RichText(
                    text: TextSpan(
                      text: 'Kategori Aset',
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

                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                    hint: Text(
                      'Pilih Kategori...',
                      style: AppTypography.bodySmall.copyWith(color: subtitleCol),
                    ),
                    items: state.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(
                          cat.name,
                          style: AppTypography.bodySmall.copyWith(color: textCol),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategoryId = val);
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kategori aset wajib dipilih';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Kode Aset & Nama Unit (Mandatory *)
                  AppTextField(
                    controller: _codeController,
                    label: 'Kode Aset *',
                    hintText: 'Misal: AST-2024-001',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Kode aset wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _nameController,
                    label: 'Nama Unit Aset *',
                    hintText: 'Misal: MacBook Pro M3 Max 16"',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama unit aset wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Brand & Model
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _brandController,
                          label: 'Merk / Brand',
                          hintText: 'Misal: Apple',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _modelController,
                          label: 'Model / Tipe',
                          hintText: 'Misal: A2991',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Nomor Seri (S/N)
                  AppTextField(
                    controller: _serialController,
                    label: 'Nomor Seri / IMEI / Plat',
                    hintText: 'Misal: C02G1234MD6R',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Tanggal Pembelian & Garansi
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Beli',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textCol,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickPurchaseDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  border: Border.all(color: borderCol),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 16,
                                      color: AppColors.brandTeal,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _purchaseDate != null
                                            ? _dateFormat.format(_purchaseDate!)
                                            : 'Pilih...',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: _purchaseDate != null
                                              ? textCol
                                              : subtitleCol,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Masa Garansi',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textCol,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickWarrantyExpiry,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  border: Border.all(color: borderCol),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendarClock,
                                      size: 16,
                                      color: AppColors.surfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _warrantyExpiry != null
                                            ? _dateFormat.format(_warrantyExpiry!)
                                            : 'Pilih...',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: _warrantyExpiry != null
                                              ? textCol
                                              : subtitleCol,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Harga Pembelian & Vendor
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _costController,
                          label: 'Harga Beli (Rp)',
                          hintText: '35000000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _vendorController,
                          label: 'Vendor / Rekanan',
                          hintText: 'iBox Store',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 7. Lokasi Rak / Gudang
                  AppTextField(
                    controller: _locationController,
                    label: 'Lokasi Rak / Gudang',
                    hintText: 'Misal: Gudang IT Lt. 2, Rak B-03',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 8. Kondisi Fisik Awal
                  Text(
                    'Kondisi Fisik Saat Pendaftaran',
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

                  // 9. Penugasan Langsung (Opsional)
                  Text(
                    'Penugasan Langsung ke Karyawan (Opsional)',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDirectAssignee,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol),
                      ),
                      child: _directAssignee == null
                          ? Row(
                              children: [
                                const Icon(
                                  LucideIcons.userPlus,
                                  size: 18,
                                  color: AppColors.surfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Biarkan kosong jika masuk ke gudang pool...',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 12,
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
                                    employee: _directAssignee,
                                    avatarSize: 38,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.x, size: 16),
                                  onPressed: () {
                                    setState(() => _directAssignee = null);
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 10. Catatan Tambahan
                  AppTextField(
                    controller: _notesController,
                    label: 'Catatan Unit',
                    hintText: 'Keterangan tambahan kelengkapan unit...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
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
      selectedColor: const AppColors.accentTealLight,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? const AppColors.primaryHover : null,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
