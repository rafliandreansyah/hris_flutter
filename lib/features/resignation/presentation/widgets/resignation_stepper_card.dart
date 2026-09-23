import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ResignationStepperCard extends StatelessWidget {
  final ResignationDetailModel resignation;

  const ResignationStepperCard({
    super.key,
    required this.resignation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final status = resignation.status.toLowerCase();

    // Tentukan tahap aktif saat ini
    int currentStageNumber = 1;
    if (status == 'submitted') {
      currentStageNumber = 2;
    } else if (status == 'manager_approved') {
      currentStageNumber = 3;
    } else if (status == 'hr_approved' || status == 'in_clearance') {
      currentStageNumber = 4;
    } else if (status == 'settled') {
      currentStageNumber = 5;
    }

    final submittedDateStr = resignation.resignationDate != null
        ? DateFormat('d MMM yyyy').format(resignation.resignationDate!)
        : null;

    final managerName = resignation.managerApprover?.name ??
        resignation.employee?.departmentName ??
        'Atasan Langsung';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahapan Proses Resign',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pelacakan alur dokumen resmi HR',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF134E4A)
                      : const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Tahap $currentStageNumber dari 5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF5EEAD4)
                        : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Pengajuan Dibuat
          _buildStepItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            brandCol: brandCol,
            title: '1. Pengajuan Dibuat',
            subtitle: 'Surat resmi & rencana serah terima telah diunggah.',
            rightLabel: submittedDateStr,
            isCompleted: true,
            isCurrent: false,
            isLast: false,
          ),

          // 2. Diskusi 1-on-1 Atasan
          _buildStepItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            brandCol: brandCol,
            title: '2. Diskusi 1-on-1 Atasan',
            subtitle: status == 'submitted'
                ? 'Menunggu sesi diskusi 1-on-1 dengan $managerName.'
                : 'Diskusi bersama $managerName telah selesai.',
            rightLabel: status == 'submitted'
                ? 'Menunggu'
                : (status == 'rejected' ? 'Ditolak' : 'Disetujui'),
            rightLabelColor: status == 'submitted'
                ? Colors.amber.shade700
                : (status == 'rejected' ? Colors.red.shade600 : brandCol),
            isCompleted: currentStageNumber > 2,
            isCurrent: currentStageNumber == 2,
            isLast: false,
            extraContent: resignation.managerNotes != null &&
                    resignation.managerNotes!.trim().isNotEmpty
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderCol.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '"${resignation.managerNotes}"',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: subtitleCol,
                        height: 1.3,
                      ),
                    ),
                  )
                : null,
          ),

          // 3. Verifikasi HR & Cuti
          _buildStepItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            brandCol: brandCol,
            title: '3. Verifikasi HR & Cuti',
            subtitle:
                'Pengecekan hak sisa ${resignation.remainingLeaveDays} hari cuti tahunan & verifikasi offboarding.',
            rightLabel: currentStageNumber > 3
                ? 'Selesai'
                : (currentStageNumber == 3 ? 'Sedang Diproses' : 'Menunggu'),
            rightLabelColor: currentStageNumber >= 3 ? brandCol : subtitleCol,
            isCompleted: currentStageNumber > 3,
            isCurrent: currentStageNumber == 3,
            isLast: false,
          ),

          // 4. Live Clearance 4 Pos
          _buildStepItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            brandCol: brandCol,
            title: '4. Live Clearance 4 Pos',
            subtitle:
                'Pengembalian inventaris aset, hak akses IT, kasbon & finance.',
            rightLabel: currentStageNumber > 4
                ? 'Selesai'
                : (currentStageNumber == 4 ? 'Sedang Berjalan' : 'Menunggu'),
            rightLabelColor: currentStageNumber >= 4 ? brandCol : subtitleCol,
            isCompleted: currentStageNumber > 4,
            isCurrent: currentStageNumber == 4,
            isLast: false,
          ),

          // 5. Penerbitan Paklaring
          _buildStepItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            brandCol: brandCol,
            title: '5. Penerbitan Paklaring',
            subtitle:
                'Surat referensi pengalaman kerja & paklaring digital ber-QR resmi.',
            rightLabel: currentStageNumber == 5 && status == 'settled'
                ? 'Selesai'
                : 'Tahap Akhir',
            rightLabelColor: status == 'settled' ? brandCol : subtitleCol,
            isCompleted: status == 'settled',
            isCurrent: currentStageNumber == 5 && status != 'settled',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required Color brandCol,
    required String title,
    required String subtitle,
    String? rightLabel,
    Color? rightLabelColor,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    Widget? extraContent,
  }) {
    Color iconBg;
    Widget iconWidget;

    if (isCompleted) {
      iconBg = brandCol;
      iconWidget = const Icon(LucideIcons.check, size: 14, color: Colors.white);
    } else if (isCurrent) {
      iconBg = isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1);
      iconWidget = Icon(LucideIcons.loader, size: 14, color: brandCol);
    } else {
      iconBg = isDark
          ? AppColors.darkSurfaceContainer
          : const Color(0xFFE2E8F0);
      iconWidget = Icon(LucideIcons.circle, size: 10, color: subtitleCol);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Stepper & Connecting Line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(child: iconWidget),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? brandCol.withValues(alpha: 0.4)
                        : (isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Text Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                        ),
                      ),
                      if (rightLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (rightLabelColor ?? brandCol)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rightLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: rightLabelColor ?? brandCol,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleCol,
                      height: 1.35,
                    ),
                  ),
                  ?extraContent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
