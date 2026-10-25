import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Data Kepegawaian & Personal Pegawai.
///
/// Dikelompokkan per bagian (Kepegawaian, Kontak, Personal, Rekening) dan
/// field kosong ("-") otomatis disembunyikan agar kartu tetap ringkas.
class EmploymentDataCard extends StatelessWidget {
  final String joinDate;
  final String tenure;
  final String contractExpiry;
  final String employeeId;
  final String nik;
  final String email;
  final String phone;
  final String emergencyContact;
  final String placeDob;
  final String gender;
  final String bloodType;
  final String maritalStatus;
  final String religion;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  const EmploymentDataCard({
    super.key,
    this.joinDate = '-',
    this.tenure = '-',
    this.contractExpiry = '-',
    this.employeeId = '-',
    this.nik = '-',
    this.email = '-',
    this.phone = '-',
    this.emergencyContact = '-',
    this.placeDob = '-',
    this.gender = '-',
    this.bloodType = '-',
    this.maritalStatus = '-',
    this.religion = '-',
    this.bankName = '-',
    this.accountNumber = '-',
    this.accountHolder = '-',
  });

  static bool _has(String v) => v.trim().isNotEmpty && v.trim() != '-';

  /// Masa kerja dari tanggal bergabung, mis. "2 tahun 3 bulan".
  static String formatTenure(String? rawJoinDate, {DateTime? now}) {
    final join = DateTime.tryParse(rawJoinDate ?? '');
    if (join == null) return '-';
    final today = now ?? DateTime.now();
    var months = (today.year - join.year) * 12 + today.month - join.month;
    if (today.day < join.day) months--;
    if (months < 0) return '-';
    final years = months ~/ 12;
    final rest = months % 12;
    if (years == 0 && rest == 0) return 'Kurang dari 1 bulan';
    return [
      if (years > 0) '$years tahun',
      if (rest > 0) '$rest bulan',
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final bankBoxBg = isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    final sections = <(String, List<(String, String)>)>[
      (
        'Kepegawaian',
        [
          ('Tanggal Bergabung', joinDate),
          ('Masa Kerja', tenure),
          ('Akhir Kontrak', contractExpiry),
          ('No. Pegawai', employeeId),
        ],
      ),
      (
        'Kontak',
        [
          ('Email', email),
          ('Telepon', phone),
          ('Kontak Darurat', emergencyContact),
        ],
      ),
      (
        'Personal',
        [
          ('NIK', nik),
          ('Tempat, Tanggal Lahir', placeDob),
          ('Jenis Kelamin', gender),
          ('Golongan Darah', bloodType),
          ('Status Pernikahan', maritalStatus),
          ('Agama', religion),
        ],
      ),
    ]
        .map((s) => (s.$1, s.$2.where((f) => _has(f.$2)).toList()))
        .where((s) => s.$2.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pegawai',
            style: AppTypography.titleSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          for (var i = 0; i < sections.length; i++) ...[
            SizedBox(height: i == 0 ? AppSpacing.md - 4 : AppSpacing.md),
            if (i > 0) ...[
              Divider(height: 1, thickness: 1, color: borderCol),
              const SizedBox(height: AppSpacing.md - 4),
            ],
            Text(
              sections[i].$1.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: labelCol,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            LayoutBuilder(
              builder: (context, constraints) {
                final half = (constraints.maxWidth - AppSpacing.md) / 2;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md - 4,
                  children: [
                    for (final f in sections[i].$2)
                      SizedBox(
                        // Nilai panjang (email, TTL) memakai lebar penuh.
                        width: f.$2.length > 22 ? constraints.maxWidth : half,
                        child: _DataItem(
                          label: f.$1,
                          value: f.$2,
                          textCol: textCol,
                          labelCol: labelCol,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],

          // Bank Account Info Box
          if (_has(bankName) || _has(accountNumber)) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md - 4),
              decoration: BoxDecoration(
                color: bankBoxBg,
                borderRadius: AppRadius.borderInput,
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: borderCol),
                    ),
                    child: const Icon(
                      LucideIcons.landmark,
                      size: 18,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md - 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [bankName, accountNumber].where(_has).join(' • '),
                          style: AppTypography.titleSmall.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (_has(accountHolder)) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Atas Nama: $accountHolder',
                            style: AppTypography.labelSmall.copyWith(
                              color: labelCol,
                              fontSize: 11,
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
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
