import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceLogFilterCriteria extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final AttendanceLogType? type;
  final AttendanceLogPunctuality? punctuality;
  final bool lastMonth;

  const AttendanceLogFilterCriteria({
    this.startDate,
    this.endDate,
    this.type,
    this.punctuality,
    this.lastMonth = false,
  });

  bool get hasActiveFilter =>
      startDate != null ||
      endDate != null ||
      type != null ||
      punctuality != null ||
      lastMonth;

  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (type != null) count++;
    if (punctuality != null) count++;
    if (lastMonth) count++;
    return count;
  }

  String? get typeQuery {
    switch (type) {
      case AttendanceLogType.clockIn:
        return 'IN';
      case AttendanceLogType.clockOut:
        return 'OUT';
      case null:
        return null;
    }
  }

  String? get statusQuery {
    switch (punctuality) {
      case AttendanceLogPunctuality.onTime:
        return 'on_time';
      case AttendanceLogPunctuality.late:
        return 'late';
      case null:
        return null;
    }
  }

  String? get startDateQuery =>
      startDate == null ? null : DateFormat('yyyy-MM-dd').format(startDate!);

  String? get endDateQuery =>
      endDate == null ? null : DateFormat('yyyy-MM-dd').format(endDate!);

  AttendanceLogFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    AttendanceLogType? type,
    AttendanceLogPunctuality? punctuality,
    bool? lastMonth,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearType = false,
    bool clearPunctuality = false,
  }) {
    return AttendanceLogFilterCriteria(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      type: clearType ? null : (type ?? this.type),
      punctuality: clearPunctuality
          ? null
          : (punctuality ?? this.punctuality),
      lastMonth: lastMonth ?? this.lastMonth,
    );
  }

  @override
  List<Object?> get props => [startDate, endDate, type, punctuality, lastMonth];
}

Future<AttendanceLogFilterCriteria?> showAttendanceLogsFilterBottomSheet(
  BuildContext context, {
  required AttendanceLogFilterCriteria initialCriteria,
}) {
  return showModalBottomSheet<AttendanceLogFilterCriteria>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheetContext) =>
        AttendanceLogsFilterBottomSheet(initialCriteria: initialCriteria),
  );
}

class AttendanceLogsFilterBottomSheet extends StatefulWidget {
  final AttendanceLogFilterCriteria initialCriteria;

  const AttendanceLogsFilterBottomSheet({
    super.key,
    required this.initialCriteria,
  });

  @override
  State<AttendanceLogsFilterBottomSheet> createState() =>
      _AttendanceLogsFilterBottomSheetState();
}

class _AttendanceLogsFilterBottomSheetState
    extends State<AttendanceLogsFilterBottomSheet> {
  late AttendanceLogFilterCriteria _criteria = widget.initialCriteria;

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? _criteria.startDate
        : _criteria.endDate;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _criteria = isStart
          ? _criteria.copyWith(startDate: picked)
          : _criteria.copyWith(endDate: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final fieldBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final brandFg = isDark ? const Color(0xFF003732) : Colors.white;
    final dateFormat = DateFormat('dd MMM yyyy', 'en_US');

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkOutlineMuted
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Riwayat Absensi',
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
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
                const SizedBox(height: 4),
                Text(
                  'Saring log clock-in & clock-out sesuai periode dan status',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Periode Bulan',
                  style: AppTypography.labelMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionRow(
                  options: const ['Bulan Ini', 'Bulan Lalu'],
                  selectedIndex: _criteria.lastMonth ? 1 : 0,
                  onSelected: (index) {
                    setState(() {
                      _criteria = _criteria.copyWith(lastMonth: index == 1);
                    });
                  },
                  fieldBg: fieldBg,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                  brandColor: brandColor,
                  brandFg: brandFg,
                ),
                const SizedBox(height: 18),
                Text(
                  'Rentang Tanggal Kustom (Opsional)',
                  style: AppTypography.labelMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'Mulai',
                        value: _criteria.startDate == null
                            ? null
                            : dateFormat.format(_criteria.startDate!),
                        onTap: () => _pickDate(isStart: true),
                        onClear: _criteria.startDate == null
                            ? null
                            : () => setState(() {
                                  _criteria = _criteria.copyWith(
                                    clearStartDate: true,
                                  );
                                }),
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandColor: brandColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(
                        label: 'Selesai',
                        value: _criteria.endDate == null
                            ? null
                            : dateFormat.format(_criteria.endDate!),
                        onTap: () => _pickDate(isStart: false),
                        onClear: _criteria.endDate == null
                            ? null
                            : () => setState(() {
                                  _criteria = _criteria.copyWith(
                                    clearEndDate: true,
                                  );
                                }),
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandColor: brandColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Jenis Absensi',
                  style: AppTypography.labelMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionRow(
                  options: const ['Semua', 'Clock In', 'Clock Out'],
                  selectedIndex: _criteria.type == null
                      ? 0
                      : (_criteria.type == AttendanceLogType.clockIn ? 1 : 2),
                  onSelected: (index) {
                    setState(() {
                      _criteria = _criteria.copyWith(
                        clearType: index == 0,
                        type: index == 1
                            ? AttendanceLogType.clockIn
                            : (index == 2
                                  ? AttendanceLogType.clockOut
                                  : null),
                      );
                    });
                  },
                  fieldBg: fieldBg,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                  brandColor: brandColor,
                  brandFg: brandFg,
                ),
                const SizedBox(height: 18),
                Text(
                  'Status Kehadiran',
                  style: AppTypography.labelMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionRow(
                  options: const ['Semua', 'On Time', 'Terlambat'],
                  selectedIndex: _criteria.punctuality == null
                      ? 0
                      : (_criteria.punctuality ==
                                AttendanceLogPunctuality.onTime
                            ? 1
                            : 2),
                  onSelected: (index) {
                    setState(() {
                      _criteria = _criteria.copyWith(
                        clearPunctuality: index == 0,
                        punctuality: index == 1
                            ? AttendanceLogPunctuality.onTime
                            : (index == 2
                                  ? AttendanceLogPunctuality.late
                                  : null),
                      );
                    });
                  },
                  fieldBg: fieldBg,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                  brandColor: brandColor,
                  brandFg: brandFg,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _criteria = const AttendanceLogFilterCriteria();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textCol,
                          side: BorderSide(color: borderCol),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'Reset',
                          style: AppTypography.bodyMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_criteria),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: brandFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'Terapkan Filter',
                          style: AppTypography.bodyMedium.copyWith(
                            color: brandFg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildDateField({
    required String label,
    required String? value,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required Color fieldBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 16,
              color: value != null ? brandColor : subtitleCol,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: value != null ? textCol : subtitleCol,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(LucideIcons.x, size: 14, color: subtitleCol),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required Color fieldBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
    required Color brandFg,
  }) {
    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = index == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == options.length - 1 ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? brandColor : fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? brandColor : borderCol,
                  ),
                ),
                child: Center(
                  child: Text(
                    options[index],
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? brandFg : subtitleCol,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
