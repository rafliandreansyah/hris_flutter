import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';

Future<ResignationColleagueModel?> showResignationColleaguePickerModal(
  BuildContext context, {
  required List<ResignationColleagueModel> colleagues,
  ResignationColleagueModel? selectedColleague,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  String searchQuery = '';

  return showModalBottomSheet<ResignationColleagueModel?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = colleagues.where((c) {
            if (searchQuery.trim().isEmpty) return true;
            final query = searchQuery.toLowerCase().trim();
            final nameMatch = c.name.toLowerCase().contains(query);
            final deptMatch =
                c.departmentName?.toLowerCase().contains(query) ?? false;
            final posMatch =
                c.positionName?.toLowerCase().contains(query) ?? false;
            return nameMatch || deptMatch || posMatch;
          }).toList();

          return Material(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(modalContext).size.height * 0.75,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pilih Rekan Pengganti',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.of(modalContext).pop(),
                            ),
                          ],
                        ),
                      ),

                      // Search box
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari nama, jabatan, atau divisi...',
                            hintStyle: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),

                      const Divider(height: 1),

                      // List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.users,
                                        size: 40,
                                        color: isDark
                                            ? AppColors.darkOnSurfaceVariant
                                            : AppColors.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Rekan kerja tidak ditemukan',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                          color: isDark
                                              ? AppColors.darkOnSurfaceVariant
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1, indent: 64),
                                itemBuilder: (context, index) {
                                  final colleague = filtered[index];
                                  final isSelected =
                                      colleague.id == selectedColleague?.id;

                                  final initials = _getInitials(colleague.name);
                                  final subtitle = [
                                    if (colleague.positionName != null &&
                                        colleague
                                            .positionName!.trim().isNotEmpty)
                                      colleague.positionName!.trim(),
                                    if (colleague.departmentName != null &&
                                        colleague
                                            .departmentName!.trim().isNotEmpty)
                                      colleague.departmentName!.trim(),
                                  ].join(' • ');

                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    selected: isSelected,
                                    selectedTileColor: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        initials,
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      colleague.name,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: subtitle.isNotEmpty
                                        ? Text(
                                            subtitle,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: isDark
                                                  ? AppColors
                                                      .darkOnSurfaceVariant
                                                  : AppColors.onSurfaceVariant,
                                            ),
                                          )
                                        : null,
                                    trailing: isSelected
                                        ? const Icon(
                                            LucideIcons.checkCircle2,
                                            color: AppColors.primary,
                                            size: 20,
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.of(modalContext)
                                          .pop(colleague);
                                    },
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

String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return '?';
  if (parts.length == 1) {
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
