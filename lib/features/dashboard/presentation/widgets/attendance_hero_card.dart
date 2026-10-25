import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Hero Card Absensi Dashboard (Teal Oasis)
class AttendanceHeroCard extends StatelessWidget {
  final String currentTime;
  final String currentDate;
  final String company;
  final String schedule;
  final String timezone;
  final String clockInTime;
  final String clockOutTime;
  final bool isClockedIn;
  final bool isDayOff;
  final bool hasSchedule;
  final VoidCallback? onClockPressed;

  const AttendanceHeroCard({
    super.key,
    this.currentTime = '--:--',
    this.currentDate = '--',
    this.company = 'Lokasi kerja belum diatur',
    this.schedule = '--:-- - --:--',
    this.timezone = '--:--',
    this.clockInTime = '--:--',
    this.clockOutTime = '--:--',
    this.isClockedIn = false,
    this.isDayOff = false,
    this.hasSchedule = true,
    this.onClockPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandTeal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle circles decoration
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Main Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Status, Time & Date (+ zona waktu)
              Text(
                l10n?.currentStatus ?? 'STATUS SAAT INI',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentTealLight,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentTime,
                style: AppTypography.headlineLarge.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '$currentDate • ${AppDateUtil.timezoneLabel(timezone)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 18),

              // Jadwal & lokasi kerja — disusun vertikal agar tidak terpotong
              _InfoLine(
                icon: isDayOff
                    ? LucideIcons.calendarOff
                    : (!hasSchedule ? LucideIcons.calendarX : LucideIcons.clock),
                text: schedule,
                color: isDayOff
                    ? const Color(0xFFFEF08A)
                    : (!hasSchedule
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.accentTealLight),
                bold: isDayOff,
              ),
              const SizedBox(height: 6),
              _InfoLine(
                icon: LucideIcons.building2,
                text: company,
                color: AppColors.accentTealLight,
              ),
              const SizedBox(height: 10),

              // Clock In & Clock Out Row
              Wrap(
                spacing: 20,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.logIn,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n?.clockInShort ?? 'Masuk'}: $clockInTime',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.logOut,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n?.clockOutShort ?? 'Pulang'}: $clockOutTime',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol aksi: Absen Masuk / Absen Pulang
              AppButton(
                key: const ValueKey('dashboard_clock_button'),
                text: isClockedIn
                    ? (l10n?.clockOutAction ?? 'Absen Pulang')
                    : (l10n?.clockInAction ?? 'Absen Masuk'),
                leadingIcon: LucideIcons.fingerprint,
                height: 48,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandTeal,
                onPressed: onClockPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool bold;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
