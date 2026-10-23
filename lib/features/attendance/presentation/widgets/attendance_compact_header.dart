import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/core/widgets/app_glass_container.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header ringkas melayang di atas peta: lokasi kerja, jam server, shift, dan
/// ringkasan Masuk / Istirahat / Pulang dalam satu kartu agar halaman tanpa scroll.
class AttendanceCompactHeader extends StatelessWidget {
  final AttendanceLoaded state;

  /// Ketuk nama lokasi kerja (membuka pemilih lokasi bila ada lebih dari satu).
  final VoidCallback? onLocationTap;

  /// Ketuk statistik istirahat (membuka riwayat istirahat hari ini).
  final VoidCallback? onBreakTap;

  const AttendanceCompactHeader({
    super.key,
    required this.state,
    this.onLocationTap,
    this.onBreakTap,
  });

  String _shiftLabel() {
    final data = state.data;
    if (data.isDayOff) return 'Libur Kerja';
    if (!data.hasSchedule) return 'Tanpa Jadwal';
    return data.shiftName;
  }

  String _breakLabel() {
    final status = state.breakStatus;
    if (status == null) return '--';
    final used = status.totalMinutesAt(DateTime.now());
    final allocated = status.allocatedBreakMinutes;
    return allocated != null ? '$used/$allocated mnt' : '$used mnt';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = state.data;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final canPickLocation = data.availableWorkLocations.length > 1;

    return AppGlassContainer(
      key: const ValueKey('attendance_compact_header'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baris 1: lokasi kerja (ketuk untuk ganti bila lebih dari satu)
          InkWell(
            key: const ValueKey('attendance_header_location'),
            onTap: canPickLocation ? onLocationTap : null,
            borderRadius: AppRadius.borderLg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Kerja',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtleCol,
                            fontSize: 10.5,
                          ),
                        ),
                        Text(
                          data.hasWorkLocation
                              ? data.officeName
                              : 'Belum diatur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canPickLocation)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + AppSpacing.xs,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.arrowLeftRight,
                            size: 12,
                            color: AppColors.brandTeal,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Ganti',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.brandTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Baris 2: jam server · tanggal · shift
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  state.formattedClockTime,
                  key: const ValueKey('attendance_header_clock'),
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppDateUtil.formatDateMedium(state.currentClockTime)} · ${data.timezone}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: subtleCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _shiftLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: data.isDayOff
                              ? AppColors.warning
                              : AppColors.brandTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Baris 3: ringkasan Masuk · Istirahat · Pulang
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              // Lapisan kaca kedua yang lebih tipis untuk ringkasan
              color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.5),
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
              ),
            ),
            child: Row(
              children: [
                _Stat(
                  label: 'Masuk',
                  value: AppDateUtil.formatTimeHHmm(data.inTime),
                  icon: LucideIcons.logIn,
                  textCol: textCol,
                  subtleCol: subtleCol,
                ),
                _Divider(color: borderCol),
                _Stat(
                  key: const ValueKey('attendance_header_break'),
                  label: 'Istirahat',
                  value: _breakLabel(),
                  icon: LucideIcons.coffee,
                  highlight: data.isOnBreak,
                  textCol: textCol,
                  subtleCol: subtleCol,
                  onTap: state.breakStatus == null ? null : onBreakTap,
                ),
                _Divider(color: borderCol),
                _Stat(
                  label: 'Pulang',
                  value: AppDateUtil.formatTimeHHmm(data.outTime),
                  icon: LucideIcons.logOut,
                  textCol: textCol,
                  subtleCol: subtleCol,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: color);
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final Color textCol;
  final Color subtleCol;
  final VoidCallback? onTap;

  const _Stat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.textCol,
    required this.subtleCol,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: highlight ? AppColors.brandTeal : subtleCol,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: highlight ? AppColors.brandTeal : subtleCol,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                color: highlight ? AppColors.brandTeal : textCol,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
