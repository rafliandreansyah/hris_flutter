import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/filter/app_filter_sheet_frame.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kriteria filter untuk daftar pengumuman Oasish HRIS.
class AnnouncementFilterCriteria {
  final String? category;
  final String? priority;

  const AnnouncementFilterCriteria({
    this.category,
    this.priority,
  });

  bool get hasActiveFilter =>
      (category != null && category!.isNotEmpty && category!.toLowerCase() != 'all') ||
      (priority != null && priority!.isNotEmpty && priority!.toLowerCase() != 'all');

  int get activeFilterCount {
    int count = 0;
    if (category != null && category!.isNotEmpty && category!.toLowerCase() != 'all') {
      count++;
    }
    if (priority != null && priority!.isNotEmpty && priority!.toLowerCase() != 'all') {
      count++;
    }
    return count;
  }

  AnnouncementFilterCriteria copyWith({
    String? category,
    bool clearCategory = false,
    String? priority,
    bool clearPriority = false,
  }) {
    return AnnouncementFilterCriteria(
      category: clearCategory ? null : (category ?? this.category),
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementFilterCriteria &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(category, priority);
}

/// Menampilkan Modal Bottom Sheet "Filter Pengumuman"
Future<AnnouncementFilterCriteria?> showAnnouncementFilterBottomSheet(
  BuildContext context, {
  required AnnouncementFilterCriteria initialCriteria,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<AnnouncementFilterCriteria>(
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
      return AnnouncementFilterBottomSheet(
        initialCriteria: initialCriteria,
      );
    },
  );
}

class AnnouncementFilterBottomSheet extends StatefulWidget {
  final AnnouncementFilterCriteria initialCriteria;

  const AnnouncementFilterBottomSheet({
    super.key,
    required this.initialCriteria,
  });

  @override
  State<AnnouncementFilterBottomSheet> createState() =>
      _AnnouncementFilterBottomSheetState();
}

class _AnnouncementFilterBottomSheetState
    extends State<AnnouncementFilterBottomSheet> {
  String? _selectedCategory;
  String? _selectedPriority;

  static const List<Map<String, String?>> _categories = [
    {'key': null, 'label': 'Semua'},
    {'key': 'general', 'label': 'Umum'},
    {'key': 'hr_policy', 'label': 'Kebijakan HR'},
    {'key': 'event', 'label': 'Kegiatan'},
    {'key': 'holiday', 'label': 'Hari Libur'},
    {'key': 'maintenance', 'label': 'Pemeliharaan'},
    {'key': 'emergency', 'label': 'Darurat'},
  ];

  static const List<Map<String, String?>> _priorities = [
    {'key': null, 'label': 'Semua'},
    {'key': 'low', 'label': 'Rendah'},
    {'key': 'medium', 'label': 'Menengah'},
    {'key': 'high', 'label': 'Tinggi'},
    {'key': 'urgent', 'label': 'Mendesak'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCriteria.category;
    _selectedPriority = widget.initialCriteria.priority;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedPriority = null;
    });
  }

  void _applyFilters() {
    final result = AnnouncementFilterCriteria(
      category: _selectedCategory,
      priority: _selectedPriority,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return AppFilterSheetFrame(
      title: 'Filter Pengumuman',
      onReset: _resetFilters,
      onApply: _applyFilters,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Kategori
          Text(
            'Kategori',
            style: AppTypography.labelMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final key = cat['key'];
              final label = cat['label']!;
              final isSelected = _selectedCategory == key;

              return _buildFilterChip(
                label: label,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = key;
                  });
                },
                isDark: isDark,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Section Prioritas
          Text(
            'Prioritas',
            style: AppTypography.labelMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _priorities.map((pri) {
              final key = pri['key'];
              final label = pri['label']!;
              final isSelected = _selectedPriority == key;

              return _buildFilterChip(
                label: label,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedPriority = key;
                  });
                },
                isDark: isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final selectedBg = isDark
        ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
        : AppColors.primaryContainer;
    final unselectedBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final unselectedBorder =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final unselectedText =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? brandColor : unselectedBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                LucideIcons.check,
                size: 14,
                color: brandColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? brandColor : unselectedText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
