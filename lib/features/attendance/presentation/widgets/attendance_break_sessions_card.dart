import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_break.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu istirahat hari ini: timer berjalan, sisa jatah / lewat jatah, dan daftar
/// seluruh sesi istirahat. Memakai jam perangkat ([nowProvider]) yang diperbarui
/// tiap detik hanya saat ada istirahat yang sedang berjalan.
class AttendanceBreakSessionsCard extends StatefulWidget {
  final AttendanceBreakStatus status;

  /// Sumber waktu "sekarang"; dapat diganti pada test.
  final DateTime Function() nowProvider;

  const AttendanceBreakSessionsCard({
    super.key,
    required this.status,
    this.nowProvider = DateTime.now,
  });

  @override
  State<AttendanceBreakSessionsCard> createState() =>
      _AttendanceBreakSessionsCardState();
}

class _AttendanceBreakSessionsCardState
    extends State<AttendanceBreakSessionsCard> {
  Timer? _timer;
  late DateTime _now = widget.nowProvider();

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant AttendanceBreakSessionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _now = widget.nowProvider();
    _syncTimer();
  }

  void _syncTimer() {
    final needsTimer = widget.status.activeBreak != null;
    if (needsTimer && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = widget.nowProvider());
      });
    } else if (!needsTimer) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _hhmm(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

  static String _clock(Duration d) {
    final total = d.isNegative ? Duration.zero : d;
    final m = total.inMinutes.toString().padLeft(2, '0');
    final s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textPrimary =
        isDark ? AppColors.darkOnSurface : AppColors.onBackground;
    final textSecondary =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final iconBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final iconColor =
        isDark ? AppColors.darkOnPrimaryContainer : AppColors.onPrimaryContainer;
    final brand = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final status = widget.status;
    final active = status.activeBreak;
    final totalNow = status.totalMinutesAt(_now);
    final overNow = status.overbreakMinutesAt(_now);
    final remaining = status.remainingMinutesAt(_now);
    final hasAllowance = status.allocatedBreakMinutes != null;
    final isOver = hasAllowance && overNow > 0;

    final String chipText;
    final Color chipColor;
    if (active != null) {
      chipText = 'Sedang istirahat';
      chipColor = isOver ? AppColors.errorRed : brand;
    } else if (status.breaks.isNotEmpty) {
      chipText = 'Selesai';
      chipColor = AppColors.success;
    } else {
      chipText = 'Belum mulai';
      chipColor = textSecondary;
    }

    return Container(
      key: const ValueKey('attendance_break_sessions_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isOver ? AppColors.errorRed : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(LucideIcons.coffee, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md - 2),
              Expanded(
                child: Text(
                  'Istirahat',
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  chipText,
                  key: const ValueKey('attendance_break_status_chip'),
                  style: AppTypography.labelSmall.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (active != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                _clock(_now.difference(active.startTime)),
                key: const ValueKey('attendance_break_timer'),
                style: AppTypography.headlineMedium.copyWith(
                  color: isOver ? AppColors.errorRed : brand,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                hasAllowance
                    ? (isOver
                        ? 'Lewat jatah $overNow menit'
                        : 'Sisa jatah $remaining menit')
                    : 'Total hari ini $totalNow menit',
                key: const ValueKey('attendance_break_allowance_text'),
                style: AppTypography.bodySmall.copyWith(
                  color: isOver ? AppColors.errorRed : textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: AppSpacing.md - 2),
          if (status.breaks.isEmpty)
            Text(
              'Belum ada istirahat hari ini',
              style: AppTypography.bodySmall.copyWith(color: textSecondary),
            )
          else
            for (var i = 0; i < status.breaks.length; i++)
              _SessionRow(
                index: i + 1,
                item: status.breaks[i],
                now: _now,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                brand: brand,
                hhmm: _hhmm,
              ),
          if (status.breaks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasAllowance
                        ? 'Total $totalNow dari ${status.allocatedBreakMinutes} menit'
                        : 'Total $totalNow menit',
                    key: const ValueKey('attendance_break_total_text'),
                    style: AppTypography.bodySmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isOver)
                  Text(
                    '+$overNow menit',
                    key: const ValueKey('attendance_break_over_text'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final int index;
  final AttendanceBreakItem item;
  final DateTime now;
  final Color textPrimary;
  final Color textSecondary;
  final Color brand;
  final String Function(DateTime) hhmm;

  const _SessionRow({
    required this.index,
    required this.item,
    required this.now,
    required this.textPrimary,
    required this.textSecondary,
    required this.brand,
    required this.hhmm,
  });

  @override
  Widget build(BuildContext context) {
    final range = item.isOngoing
        ? '${hhmm(item.startTime)} – sekarang'
        : '${hhmm(item.startTime)} – ${hhmm(item.endTime!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: brand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: AppTypography.labelSmall.copyWith(
                color: brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.note != null && item.note!.trim().isNotEmpty)
                  Text(
                    item.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(color: textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            '${item.minutesAt(now)} mnt',
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
