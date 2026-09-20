import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/filter/app_date_range_picker.dart';
import 'package:hris_flutter/core/widgets/filter/filter_field_selector.dart';
import 'package:hris_flutter/core/widgets/filter/filter_option_selector_modal.dart';
import 'package:hris_flutter/core/widgets/filter/filter_status_segmented_row.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_filter_criteria.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal bottom sheet filter untuk modul Surat Peringatan (Stitch M3 "Teal Oasis").
Future<WarningLetterFilterCriteria?> showWarningLetterFilterBottomSheet(
  BuildContext context, {
  required WarningLetterFilterCriteria initialCriteria,
  List<WarningLetterTypeModel> letterTypes = const [],
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<WarningLetterFilterCriteria>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheetContext) {
      return WarningLetterFilterBottomSheet(
        initialCriteria: initialCriteria,
        letterTypes: letterTypes,
      );
    },
  );
}

class WarningLetterFilterBottomSheet extends StatefulWidget {
  final WarningLetterFilterCriteria initialCriteria;
  final List<WarningLetterTypeModel> letterTypes;

  const WarningLetterFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.letterTypes = const [],
  });

  @override
  State<WarningLetterFilterBottomSheet> createState() =>
      _WarningLetterFilterBottomSheetState();
}

class _WarningLetterFilterBottomSheetState
    extends State<WarningLetterFilterBottomSheet> {
  DateTimeRange? _selectedDateRange;
  String? _selectedLetterTypeId;
  String? _selectedLetterTypeName;
  late String _selectedStatus;

  static const List<FilterStatusOption> _warningLetterStatusOptions = [
    FilterStatusOption(label: 'Semua', value: 'all'),
    FilterStatusOption(label: 'Aktif', value: 'active'),
    FilterStatusOption(label: 'Tidak Aktif', value: 'inactive'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialCriteria.dateRange;
    _selectedLetterTypeId = widget.initialCriteria.letterTypeId;
    _selectedLetterTypeName = widget.initialCriteria.letterTypeName;
    _selectedStatus = widget.initialCriteria.status.isNotEmpty
        ? widget.initialCriteria.status
        : 'all';
  }

  void _resetFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedLetterTypeId = null;
      _selectedLetterTypeName = null;
      _selectedStatus = 'all';
    });
  }

  void _applyFilters() {
    final result = WarningLetterFilterCriteria(
      dateRange: _selectedDateRange,
      letterTypeId: _selectedLetterTypeId,
      letterTypeName: _selectedLetterTypeName,
      status: _selectedStatus,
    );
    Navigator.of(context).pop(result);
  }

  String _formatDateRange(DateTimeRange range) {
    final startFormat = DateFormat('dd MMM yyyy');
    final endFormat = DateFormat('dd MMM yyyy');
    return '${startFormat.format(range.start)} - ${endFormat.format(range.end)}';
  }

  Future<void> _pickDateRange() async {
    final picked = await showAppDateRangePicker(
      context,
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _pickLetterType() async {
    final options = [
      'Semua Tipe SP',
      ...widget.letterTypes.map((e) => e.name),
    ];

    final currentSelected = _selectedLetterTypeName ?? 'Semua Tipe SP';

    await showFilterOptionSelector(
      context,
      title: 'Pilih Tipe Surat Peringatan',
      options: options,
      selectedValue: currentSelected,
      onSelected: (selected) {
        if (!mounted) return;
        setState(() {
          if (selected == 'Semua Tipe SP') {
            _selectedLetterTypeId = null;
            _selectedLetterTypeName = null;
          } else {
            final matched = widget.letterTypes.firstWhere(
              (e) => e.name == selected,
              orElse: () => WarningLetterTypeModel(
                id: '',
                name: selected,
                level: 0,
                validityPeriodMonths: 0,
              ),
            );
            _selectedLetterTypeId = matched.id.isNotEmpty ? matched.id : null;
            _selectedLetterTypeName = matched.name;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final dateRangeText = _selectedDateRange != null
        ? _formatDateRange(_selectedDateRange!)
        : 'Pilih Rentang Tanggal';

    final typeText = _selectedLetterTypeName ?? 'Semua Tipe SP';

    return Container(
      color: surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (Icon Sliders + Title + Reset Filter) ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.slidersHorizontal,
                    size: 18,
                    color: brandColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filter Surat Peringatan',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: Icon(
                    LucideIcons.rotateCcw,
                    size: 14,
                    color: brandColor,
                  ),
                  label: Text(
                    'Reset Filter',
                    style: AppTypography.labelMedium.copyWith(
                      color: brandColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderCol, thickness: 1),

          // ── Body Fields (Scrollable) ──────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Rentang Tanggal
                  FilterFieldSelector(
                    label: 'Rentang Tanggal',
                    value: dateRangeText,
                    icon: LucideIcons.calendar,
                    onTap: _pickDateRange,
                    onClear: _selectedDateRange != null
                        ? () => setState(() => _selectedDateRange = null)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Tipe Surat Peringatan
                  FilterFieldSelector(
                    label: 'Tipe Surat Peringatan',
                    value: typeText,
                    icon: LucideIcons.fileText,
                    onTap: _pickLetterType,
                    onClear: _selectedLetterTypeId != null
                        ? () => setState(() {
                              _selectedLetterTypeId = null;
                              _selectedLetterTypeName = null;
                            })
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Status Surat Peringatan (Horizontal Segmented Chips)
                  FilterStatusSegmentedRow(
                    title: 'Status Surat Peringatan',
                    options: _warningLetterStatusOptions,
                    selectedValue: _selectedStatus,
                    onSelected: (val) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    },
                    helperText: 'Pilih status keaktifan surat peringatan',
                  ),
                ],
              ),
            ),
          ),

          // ── Footer Actions (Batal & Terapkan Filter) ──────────────────
          Divider(height: 1, color: borderCol, thickness: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: AppButton(
                      text: 'Batal',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: AppButton(
                      text: 'Terapkan Filter',
                      variant: AppButtonVariant.primary,
                      leadingIcon: LucideIcons.filter,
                      onPressed: _applyFilters,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
