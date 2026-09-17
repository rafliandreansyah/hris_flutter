import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Menampilkan modal bottom sheet pilihan dengan dukungan pencarian otomatis
/// dan checkmark aktif sesuai standar Stitch M3 "Teal Oasis".
Future<void> showFilterOptionSelector(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String selectedValue,
  required ValueChanged<String> onSelected,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;
  final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
  final subtitleCol = isDark
      ? AppColors.darkOnSurfaceVariant
      : AppColors.onSurfaceVariant;
  final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

  String searchQuery = '';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (bottomSheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filteredOptions = options.where((opt) {
            if (searchQuery.trim().isEmpty) return true;
            return opt.toLowerCase().contains(searchQuery.toLowerCase().trim());
          }).toList();

          return Material(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(bottomSheetContext).size.height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (options.length > 5) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackgroundSubtle
                                  : AppColors.backgroundSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkOutlineMuted
                                    : AppColors.outlineMuted,
                              ),
                            ),
                            child: TextField(
                              onChanged: (val) {
                                setModalState(() {
                                  searchQuery = val;
                                });
                              },
                              style: AppTypography.bodyMedium.copyWith(
                                color: textCol,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari pilihan...',
                                hintStyle: AppTypography.bodySmall.copyWith(
                                  color: subtitleCol,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  size: 16,
                                  color: subtitleCol,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const Divider(height: 1),
                      Flexible(
                        child: filteredOptions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'Pilihan tidak ditemukan',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: subtitleCol,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredOptions.length,
                                itemBuilder: (context, index) {
                                  final opt = filteredOptions[index];
                                  final isSelected = opt == selectedValue;
                                  return ListTile(
                                    onTap: () {
                                      onSelected(opt);
                                      Navigator.of(bottomSheetContext).pop();
                                    },
                                    title: Text(
                                      opt,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isSelected
                                            ? brandColor
                                            : textCol,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            LucideIcons.check,
                                            color: brandColor,
                                            size: 18,
                                          )
                                        : null,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
