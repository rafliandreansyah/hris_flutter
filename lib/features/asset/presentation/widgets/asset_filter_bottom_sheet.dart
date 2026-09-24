import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_filter_criteria.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal Bottom Sheet Filter Fasilitas.
/// Sesuai Stitch Screen: "Oasish Filter Fasilitas Modal Sheet"
/// (ID: 7f28cc7c8bfa41f7b58964d4276b5155).
class AssetFilterBottomSheet extends StatefulWidget {
  final AssetFilterCriteria initialCriteria;
  final List<AssetCategoryModel> categories;
  final ValueChanged<AssetFilterCriteria> onApply;

  const AssetFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.categories,
    required this.onApply,
  });

  /// Menampilkan modal bottom sheet filter fasilitas
  static Future<void> show(
    BuildContext context, {
    required AssetFilterCriteria initialCriteria,
    required List<AssetCategoryModel> categories,
    required ValueChanged<AssetFilterCriteria> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssetFilterBottomSheet(
        initialCriteria: initialCriteria,
        categories: categories,
        onApply: onApply,
      ),
    );
  }

  @override
  State<AssetFilterBottomSheet> createState() => _AssetFilterBottomSheetState();
}

class _AssetFilterBottomSheetState extends State<AssetFilterBottomSheet> {
  late String _selectedStatus;
  late String? _selectedCategoryId;
  late String? _selectedCategoryName;
  late String _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialCriteria.status;
    _selectedCategoryId = widget.initialCriteria.categoryId;
    _selectedCategoryName = widget.initialCriteria.categoryName;
    _selectedSortBy = widget.initialCriteria.sortBy;
  }

  int get _activeCount {
    int count = 0;
    if (_selectedStatus != 'all' && _selectedStatus.isNotEmpty) count++;
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) count++;
    if (_selectedSortBy != 'newest') count++;
    return count;
  }

  void _handleReset() {
    setState(() {
      _selectedStatus = 'all';
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedSortBy = 'newest';
    });
  }

  void _handleApply() {
    final updatedCriteria = widget.initialCriteria.copyWith(
      status: _selectedStatus,
      categoryId: _selectedCategoryId,
      clearCategory: _selectedCategoryId == null,
      categoryName: _selectedCategoryName,
      sortBy: _selectedSortBy,
    );
    widget.onApply(updatedCriteria);
    Navigator.of(context).pop();
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
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final statusOptions = [
      (
        value: 'all',
        title: 'Semua Status',
        badge: 'Semua',
        subtitle: 'Tampilkan seluruh catatan inventaris',
        dotColor: primaryCol,
      ),
      (
        value: 'ACTIVE',
        title: 'Aktif',
        badge: null,
        subtitle: 'Sedang digunakan pegawai',
        dotColor: const Color(0xFF0D9488),
      ),
      (
        value: 'PENDING_ACCEPTANCE',
        title: 'Menunggu Konfirmasi',
        badge: null,
        subtitle: 'Serah terima belum disetujui',
        dotColor: const Color(0xFFF59E0B),
      ),
      (
        value: 'RETURNED',
        title: 'Riwayat (Dikembalikan)',
        badge: null,
        subtitle: 'Aset telah diserahkan kembali',
        dotColor: const Color(0xFF64748B),
      ),
      (
        value: 'REJECTED',
        title: 'Ditolak',
        badge: null,
        subtitle: 'Penyerahan fasilitas ditolak',
        dotColor: const Color(0xFFEF4444),
      ),
      (
        value: 'AVAILABLE',
        title: 'Pool Gudang (Tersedia)',
        badge: null,
        subtitle: 'Aset siap dialihkan',
        dotColor: const Color(0xFF3B82F6),
      ),
    ];

    final sortOptions = [
      (
        value: 'newest',
        title: 'Terbaru',
        icon: LucideIcons.calendarDays,
      ),
      (
        value: 'oldest',
        title: 'Terlama',
        icon: LucideIcons.history,
      ),
      (
        value: 'name_asc',
        title: 'Nama A-Z',
        icon: LucideIcons.arrowDownAZ,
      ),
      (
        value: 'name_desc',
        title: 'Nama Z-A',
        icon: LucideIcons.arrowUpZA,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 2. Header Filter Fasilitas
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Filter Fasilitas',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textCol,
                    ),
                  ),
                  if (_activeCount > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brandTeal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '$_activeCount Aktif',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _handleReset,
                    icon: Icon(
                      LucideIcons.rotateCcw,
                      size: 14,
                      color: primaryCol,
                    ),
                    label: Text(
                      'Reset Filter',
                      style: AppTypography.labelMedium.copyWith(
                        color: primaryCol,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 3. Scrollable Filter Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: Status Fasilitas ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STATUS FASILITAS',
                          style: AppTypography.labelMedium.copyWith(
                            color: subtitleCol,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Pilih salah satu',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Card Radio Container
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(statusOptions.length, (index) {
                          final opt = statusOptions[index];
                          final isSelected = _selectedStatus == opt.value;
                          final isLast = index == statusOptions.length - 1;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedStatus = opt.value;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                        .withValues(alpha: 0.5)
                                    : Colors.transparent,
                                border: isLast
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                          color: borderCol.withValues(alpha: 0.5),
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  // Radio Dot
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryCol
                                            : subtitleCol,
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                    alignment: Alignment.center,
                                    child: isSelected
                                        ? Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: primaryCol,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (opt.dotColor != primaryCol) ...[
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: opt.dotColor,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              opt.title,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: textCol,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (opt.badge != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  opt.badge!,
                                                  style: AppTypography.labelSmall
                                                      .copyWith(
                                                    color: AppColors.brandTeal,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          opt.subtitle,
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: subtitleCol,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- SECTION 2: Kategori Aset ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KATEGORI ASET',
                          style: AppTypography.labelMedium.copyWith(
                            color: subtitleCol,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Pilih kategori',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Chip Semua
                        _buildCategoryChip(
                          label: 'Semua',
                          isSelected: _selectedCategoryId == null,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedCategoryName = null;
                            });
                          },
                        ),
                        // Dynamic Categories
                        ...widget.categories.map((cat) {
                          final isSelected = _selectedCategoryId == cat.id;
                          return _buildCategoryChip(
                            label: cat.name,
                            icon: _getCategoryIcon(cat.code, cat.name),
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCategoryId = null;
                                  _selectedCategoryName = null;
                                } else {
                                  _selectedCategoryId = cat.id;
                                  _selectedCategoryName = cat.name;
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- SECTION 3: Urutkan Berdasarkan ---
                    Text(
                      'URUTKAN BERDASARKAN',
                      style: AppTypography.labelMedium.copyWith(
                        color: subtitleCol,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Grid 2x2 Sort Options
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: sortOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final sort = sortOptions[index];
                        final isSelected = _selectedSortBy == sort.value;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSortBy = sort.value;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                      .withValues(alpha: 0.5)
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryCol : borderCol,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sort.icon,
                                  size: 16,
                                  color: isSelected ? primaryCol : subtitleCol,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sort.title,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected ? primaryCol : textCol,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    LucideIcons.circleCheck,
                                    size: 16,
                                    color: primaryCol,
                                  )
                                else
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderCol),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),

            // 4. Sticky Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderCol)),
              ),
              child: Column(
                children: [
                  AppButton(
                    text: 'Terapkan Filter',
                    leadingIcon: LucideIcons.slidersHorizontal,
                    onPressed: _handleApply,
                    height: 50,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Tutup',
                      style: AppTypography.labelMedium.copyWith(
                        color: subtitleCol,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryCol : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryCol : borderCol,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(LucideIcons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: textCol),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : textCol,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String code, String name) {
    final c = code.toUpperCase();
    final n = name.toUpperCase();
    if (c.contains('LPT') || n.contains('LAPTOP')) return LucideIcons.laptop;
    if (c.contains('PHN') || n.contains('PHONE') || n.contains('SMARTPHONE')) {
      return LucideIcons.smartphone;
    }
    if (c.contains('VCL') || n.contains('KENDARAAN') || n.contains('MOBIL')) {
      return LucideIcons.car;
    }
    if (c.contains('OFFICE') || n.contains('KANTOR')) {
      return LucideIcons.monitor;
    }
    return LucideIcons.packageCheck;
  }
}
