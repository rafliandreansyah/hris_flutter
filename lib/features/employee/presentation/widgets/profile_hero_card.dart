import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Hero Card Profil Karyawan (Teal Oasis)
class ProfileHeroCard extends StatelessWidget {
  final String name;
  final String role;
  final String level;
  final String department;
  final String company;
  final String employmentStatus;
  final String contractType;
  final String? avatarUrl;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onChat;

  const ProfileHeroCard({
    super.key,
    this.name = 'Sarah Jenkins',
    this.role = 'Senior Frontend Engineer',
    this.level = 'Level Senior Specialist (L4)',
    this.department = 'Engineering',
    this.company = 'PT Oasish Tech Nusantara',
    this.employmentStatus = 'Active Employee',
    this.contractType = 'Permanent / Tetap',
    this.avatarUrl,
    this.onCall,
    this.onEmail,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final actionBg = isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '● ',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 10,
                        height: 1,
                      ),
                    ),
                    Text(
                      employmentStatus,
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Contract Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  contractType,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar Image with Teal Ring
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandTeal, width: 2.5),
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(
                avatarUrl ??
                    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            name,
            style: AppTypography.headlineLargeMobile.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Role & Level
          Text(
            '$role • $level',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.brandTeal,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          // Department & Company
          Text(
            '$department • $company',
            style: AppTypography.bodySmall.copyWith(
              color: labelCol,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Quick Action Buttons (Call, Email, Chat)
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  backgroundColor: actionBg,
                  onTap: onCall ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menghubungi nomor telepon karyawan...')),
                        );
                      },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.mail,
                  label: 'Email',
                  backgroundColor: actionBg,
                  onTap: onEmail ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuka email client...')),
                        );
                      },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.messageSquare,
                  label: 'Chat',
                  backgroundColor: actionBg,
                  foregroundColor: AppColors.brandTeal,
                  onTap: onChat ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuka ruang obrolan internal...')),
                        );
                      },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color? foregroundColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkOnSurface : const Color(0xFF334155));

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
