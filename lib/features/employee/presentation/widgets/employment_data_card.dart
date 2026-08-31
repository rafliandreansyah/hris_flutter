import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Data Ketenagakerjaan & Personal Pegawai
class EmploymentDataCard extends StatelessWidget {
  final String joinDate;
  final String contractExpiry;
  final String employeeId;
  final String nik;
  final String placeDob;
  final String gender;
  final String bloodType;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  const EmploymentDataCard({
    super.key,
    this.joinDate = '28 Agustus 2024',
    this.contractExpiry = 'Karyawan Tetap',
    this.employeeId = 'EMP-2024-019',
    this.nik = '3171012345670001',
    this.placeDob = 'Surabaya, 20 Februari 1995',
    this.gender = 'Perempuan',
    this.bloodType = 'O+',
    this.bankName = 'Bank BCA',
    this.accountNumber = '8801-2345-6789',
    this.accountHolder = 'Sarah Jenkins',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final bankBoxBg = isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employment & Personal Data',
            style: AppTypography.titleSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Join Date & Contract Expiry
          Row(
            children: [
              Expanded(
                child: _DataItem(
                  label: 'Join Date',
                  value: joinDate,
                  textCol: textCol,
                  labelCol: labelCol,
                ),
              ),
              Expanded(
                child: _DataItem(
                  label: 'Contract Expiry',
                  value: contractExpiry,
                  textCol: textCol,
                  labelCol: labelCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Employee ID & NIK
          Row(
            children: [
              Expanded(
                child: _DataItem(
                  label: 'Employee ID',
                  value: employeeId,
                  textCol: textCol,
                  labelCol: labelCol,
                ),
              ),
              Expanded(
                child: _DataItem(
                  label: 'NIK',
                  value: nik,
                  textCol: textCol,
                  labelCol: labelCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Divider(height: 1, thickness: 1, color: borderCol),
          const SizedBox(height: 14),

          // Row 3: Place & DOB
          _DataItem(
            label: 'Place/DOB',
            value: placeDob,
            textCol: textCol,
            labelCol: labelCol,
          ),
          const SizedBox(height: 14),

          // Row 4: Gender & Blood Type
          Row(
            children: [
              Expanded(
                child: _DataItem(
                  label: 'Gender',
                  value: gender,
                  textCol: textCol,
                  labelCol: labelCol,
                ),
              ),
              Expanded(
                child: _DataItem(
                  label: 'Blood Type',
                  value: bloodType,
                  textCol: textCol,
                  labelCol: labelCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bank Account Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bankBoxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                  ),
                  child: const Icon(
                    LucideIcons.landmark,
                    size: 18,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$bankName • $accountNumber',
                        style: AppTypography.titleSmall.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Atas Nama: $accountHolder',
                        style: AppTypography.labelSmall.copyWith(
                          color: labelCol,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final String label;
  final String value;
  final Color textCol;
  final Color labelCol;

  const _DataItem({
    required this.label,
    required this.value,
    required this.textCol,
    required this.labelCol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: textCol,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
