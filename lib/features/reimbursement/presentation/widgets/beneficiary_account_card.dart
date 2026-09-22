import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu tampilan rekening payroll tujuan pencairan (Reimbursement & Kasbon)
/// yang disinkronkan dengan desain Google Stitch Project 17152850901645837896.
///
/// Jika rekening ada di profil pegawai: menampilkan nomor rekening & nama pemilik.
/// Jika belum ada rekening: menampilkan informasi peringatan bahwa rekening belum terdaftar di HR.
class BeneficiaryAccountCard extends StatelessWidget {
  final String? bankName;
  final String? bankNumber;
  final String? bankAccount;
  final String? employeePosition;
  final bool isLoading;

  const BeneficiaryAccountCard({
    super.key,
    this.bankName,
    this.bankNumber,
    this.bankAccount,
    this.employeePosition,
    this.isLoading = false,
  });

  bool get hasBankAccount =>
      bankName != null &&
      bankName!.trim().isNotEmpty &&
      bankNumber != null &&
      bankNumber!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 14,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 200,
                    height: 12,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!hasBankAccount) {
      // Kondisi Belum Ada Rekening di Profil HR
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF451A03).withValues(alpha: 0.3)
              : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF78350F).withValues(alpha: 0.5)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekening Bank Belum Terdaftar',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anda belum memiliki rekening bank yang tercatat di profil HR. Harap hubungi tim HR untuk mendaftarkan rekening tujuan pencairan dana.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? const Color(0xFFFCD34D).withValues(alpha: 0.8)
                          : const Color(0xFFB45309),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Kondisi Rekening Ada di Profil HR (Stitch Design)
    final cleanBankName = bankName!.trim();
    final badgeInfo = _getBankBadgeInfo(cleanBankName);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.landmark,
                        size: 18,
                        color: brandColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Rekening Tujuan Pencairan',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textCol,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF059669)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.circleCheck,
                        size: 12,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rekening Payroll Aktif',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF15803D),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Content Rekening
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Logo Badge
                Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeInfo.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeInfo.shortLabel,
                    style: AppTypography.labelMedium.copyWith(
                      color: badgeInfo.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cleanBankName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textCol,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(color: subtitleCol),
                            ),
                          ),
                          Text(
                            bankNumber!.trim(),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleCol,
                            fontSize: 12.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'a.n ${bankAccount?.trim() ?? '-'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (employeePosition != null &&
                                employeePosition!.trim().isNotEmpty) ...[
                              TextSpan(
                                text: ' (${employeePosition!.trim()})',
                                style: TextStyle(
                                  color: subtitleCol.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Lock Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 14,
                  color: brandColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kasir finance akan mentransfer dana ke rekening ini secara otomatis setelah disetujui.',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11.5,
                      height: 1.3,
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

  _BankBadgeInfo _getBankBadgeInfo(String bankName) {
    final lower = bankName.toLowerCase();
    if (lower.contains('bca')) {
      return const _BankBadgeInfo(
        shortLabel: 'BCA',
        backgroundColor: Color(0xFF00529C),
        textColor: Colors.white,
      );
    } else if (lower.contains('mandiri')) {
      return const _BankBadgeInfo(
        shortLabel: 'MDR',
        backgroundColor: Color(0xFF003D79),
        textColor: Color(0xFFFFB81C),
      );
    } else if (lower.contains('bni')) {
      return const _BankBadgeInfo(
        shortLabel: 'BNI',
        backgroundColor: Color(0xFFF15A24),
        textColor: Colors.white,
      );
    } else if (lower.contains('bri')) {
      return const _BankBadgeInfo(
        shortLabel: 'BRI',
        backgroundColor: Color(0xFF005596),
        textColor: Colors.white,
      );
    } else if (lower.contains('jago')) {
      return const _BankBadgeInfo(
        shortLabel: 'JAGO',
        backgroundColor: Color(0xFFF8991D),
        textColor: Colors.white,
      );
    } else if (lower.contains('cimb')) {
      return const _BankBadgeInfo(
        shortLabel: 'CIMB',
        backgroundColor: Color(0xFFED1C24),
        textColor: Colors.white,
      );
    } else {
      final words = bankName.split(' ').where((w) => w.isNotEmpty).toList();
      String label = 'BANK';
      if (words.isNotEmpty) {
        if (words.length == 1) {
          label = words[0].substring(0, words[0].length.clamp(0, 4)).toUpperCase();
        } else {
          label = words.take(3).map((w) => w[0]).join().toUpperCase();
        }
      }
      return _BankBadgeInfo(
        shortLabel: label,
        backgroundColor: const Color(0xFF0D9488),
        textColor: Colors.white,
      );
    }
  }
}

class _BankBadgeInfo {
  final String shortLabel;
  final Color backgroundColor;
  final Color textColor;

  const _BankBadgeInfo({
    required this.shortLabel,
    required this.backgroundColor,
    required this.textColor,
  });
}
