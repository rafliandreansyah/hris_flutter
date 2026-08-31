import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Hero Card Absensi Dashboard (Teal Oasis)
class AttendanceHeroCard extends StatelessWidget {
  final String currentTime;
  final String currentDate;
  final String location;
  final String schedule;
  final String timezone;
  final String clockInTime;
  final String clockOutTime;
  final bool isClockedIn;
  final VoidCallback? onClockPressed;

  const AttendanceHeroCard({
    super.key,
    this.currentTime = '08:45',
    this.currentDate = 'Kamis, 27 Ags',
    this.location = 'HQ, Building A',
    this.schedule = '09:00 - 18:00',
    this.timezone = 'Asia/Jakarta',
    this.clockInTime = '08:30',
    this.clockOutTime = '--:--',
    this.isClockedIn = true,
    this.onClockPressed,
  });

  @override
  Widget build(BuildContext context) {
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
              // Top Row: Status, Time, Date & Location Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT STATUS',
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
                        currentDate,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),

                  // Location Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandTeal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          location,
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
              const SizedBox(height: 20),

              // Schedule & Timezone Info
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: AppColors.accentTealLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentTealLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.globe,
                        size: 14,
                        color: AppColors.accentTealLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timezone,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentTealLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Clock In & Clock Out Row
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.logIn,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clock In: $clockInTime',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.logOut,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clock Out: $clockOutTime',
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

              // Action Button (Quick Clock In / Clock Out)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandTeal,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: onClockPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        isClockedIn ? 'Quick Clock Out' : 'Quick Clock In',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
