import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/currency_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_bloc.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_state.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_attendance_recap_card.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_breakdown_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

class PayrollDetailScreen extends StatelessWidget {
  final String id;
  final PayrollRepository? repository;
  final PayrollDetailBloc? bloc;

  const PayrollDetailScreen({
    super.key,
    required this.id,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<PayrollDetailBloc>.value(
        value: bloc!,
        child: _PayrollDetailView(id: id),
      );
    }

    return BlocProvider<PayrollDetailBloc>(
      create: (context) {
        final repo = repository ?? context.read<PayrollRepository>();
        return PayrollDetailBloc(repository: repo)
          ..add(PayrollDetailFetched(id));
      },
      child: _PayrollDetailView(id: id),
    );
  }
}

class _PayrollDetailView extends StatelessWidget {
  final String id;

  const _PayrollDetailView({required this.id});

  void _handleShare(PayrollDetailModel detail) {
    final text = StringBuffer()
      ..writeln('📄 SLIP GAJI - ${detail.period.label.toUpperCase()}')
      ..writeln('Perusahaan: ${detail.company.name}')
      ..writeln('Nama: ${detail.employee.name}')
      ..writeln('NIK: ${detail.employee.nik}')
      ..writeln('Departemen: ${detail.employee.department}')
      ..writeln('Jabatan: ${detail.employee.position}')
      ..writeln('Status: ${detail.status.toUpperCase()}')
      ..writeln('--------------------------------')
      ..writeln('Pendapatan Kotor: ${formatRupiah(detail.grossSalary)}')
      ..writeln('Total Potongan: ${formatRupiah(detail.deductions)}')
      ..writeln('Take Home Pay (Gaji Bersih): ${formatRupiah(detail.netSalary)}')
      ..writeln('Terbilang: ${detail.terbilang}');

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'Slip Gaji ${detail.period.label} - ${detail.employee.name}',
      ),
    );
  }

  void _openPdfViewer(BuildContext context, PayrollDetailModel detail) {
    final pdfUrl = detail.payslipUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      context.read<PayrollDetailBloc>().add(
            const PayrollDetailDownloadRequested(force: true),
          );
      return;
    }

    context.push(
      Routes.PDF_VIEWER,
      extra: {
        'title': 'Slip Gaji - ${detail.period.label}',
        'fileName': 'Slip_Gaji_${detail.period.label.replaceAll(" ", "_")}.pdf',
        'fileUrl': pdfUrl,
      },
    );
  }

  Future<void> _handleTogglePrivacy(
    BuildContext context,
    bool isCurrentlyMasked,
  ) async {
    if (isCurrentlyMasked) {
      try {
        final authenticated = await BiometricService.instance.authenticate(
          localizedReason:
              'Konfirmasi identitas Anda untuk menampilkan nominal rincian slip gaji',
          biometricOnly: false,
        );

        if (!authenticated) return;
        if (!context.mounted) return;

        context
            .read<PayrollDetailBloc>()
            .add(const PayrollDetailPrivacyToggled());
      } on BiometricException catch (e) {
        if (!context.mounted) return;
        if (e.code == 'NOT_ENROLLED' || e.code == 'NOT_AVAILABLE') {
          AppDialogUtil.showWarning(
            context,
            title: 'Keamanan Perangkat Belum Diatur',
            message:
                'Untuk membuka nominal slip gaji, silakan aktifkan kunci layar (PIN, Pola, Sandi, atau Biometrik) pada menu Pengaturan smartphone Anda terlebih dahulu.',
            confirmText: 'Mengerti',
          );
        } else {
          AppDialogUtil.showError(
            context,
            title: 'Autentikasi Gagal',
            message: e.message,
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Autentikasi Gagal',
          message: 'Gagal melakukan verifikasi keamanan perangkat.',
        );
      }
    } else {
      context
          .read<PayrollDetailBloc>()
          .add(const PayrollDetailPrivacyToggled());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;

    return BlocConsumer<PayrollDetailBloc, PayrollDetailState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }

        // When PDF is newly generated/ready after download request
        if (state.downloadedPdfUrl != null &&
            state.downloadedPdfUrl!.isNotEmpty) {
          final detail = state.detail;
          final periodLabel = detail?.period.label ?? 'Dokumen';
          context.push(
            Routes.PDF_VIEWER,
            extra: {
              'title': 'Slip Gaji - $periodLabel',
              'fileName': 'Slip_Gaji_${periodLabel.replaceAll(" ", "_")}.pdf',
              'fileUrl': state.downloadedPdfUrl!,
            },
          );
        }
      },
      builder: (context, state) {
        final detail = state.detail;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              detail != null
                  ? 'Slip Gaji - ${detail.period.label}'
                  : 'Rincian Slip Gaji',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (detail != null) ...[
                IconButton(
                  icon: Icon(
                    state.isPrivacyMasked
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                    color: AppColors.brandTeal,
                  ),
                  tooltip: state.isPrivacyMasked
                      ? 'Tampilkan Nominal'
                      : 'Sembunyikan Nominal',
                  onPressed: () =>
                      _handleTogglePrivacy(context, state.isPrivacyMasked),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share2, size: 20),
                  tooltip: 'Bagikan Rincian',
                  onPressed: () => _handleShare(detail),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          bottomNavigationBar: detail == null
              ? null
              : _buildBottomActions(context, detail, state),
          body: _buildBody(context, state, isDark),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    PayrollDetailState state,
    bool isDark,
  ) {
    if (state.status == PayrollDetailStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandTeal,
          strokeWidth: 2.5,
        ),
      );
    }

    final detail = state.detail;
    if (detail == null) {
      return Center(
        child: Text(
          'Data rincian slip gaji tidak ditemukan.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        context.read<PayrollDetailBloc>().add(PayrollDetailFetched(id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Company Header Card
            _buildCompanyCard(context, detail, isDark),
            const SizedBox(height: AppSpacing.md),

            // 2. Employee Info Card
            _buildEmployeeCard(
              context,
              detail,
              state.isPrivacyMasked,
              isDark,
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Attendance Recap Card
            PayrollAttendanceRecapCard(attendance: detail.attendanceRecap),
            const SizedBox(height: AppSpacing.md),

            // 4. Breakdown Section (Pendapatan & Potongan)
            PayrollBreakdownSection(
              earnings: detail.earnings,
              deductions: detail.deductionsList,
              grossSalary: detail.grossSalary,
              totalDeductions: detail.deductions,
              isPrivacyMasked: state.isPrivacyMasked,
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Net Salary / Take Home Pay Summary Card
            _buildTakeHomePayCard(
              context,
              detail,
              state.isPrivacyMasked,
              isDark,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard(
    BuildContext context,
    PayrollDetailModel detail,
    bool isDark,
  ) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);
    final resolvedLogo = detail.company.resolvedLogoUrl;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          if (resolvedLogo != null && resolvedLogo.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: CachedNetworkImage(
                imageUrl: resolvedLogo,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => _buildFallbackCompanyIcon(),
              ),
            )
          else
            _buildFallbackCompanyIcon(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.company.name,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
                if (detail.company.address != null &&
                    detail.company.address!.isNotEmpty)
                  Text(
                    detail.company.address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCompanyIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.brandTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(
        LucideIcons.building2,
        color: AppColors.brandTeal,
        size: 24,
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    PayrollDetailModel detail,
    bool isPrivacyMasked,
    bool isDark,
  ) {
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.user,
                  size: 16,
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Data Karyawan',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Nama Lengkap', detail.employee.name, isDark),
          _buildInfoRow(
              'Nomor Induk Karyawan (NIK)', detail.employee.nik, isDark),
          _buildInfoRow(
              'Departemen / Divisi', detail.employee.department, isDark),
          _buildInfoRow('Jabatan', detail.employee.position, isDark),
          if (detail.basicSalary > 0)
            _buildInfoRow(
              'Gaji Pokok',
              isPrivacyMasked
                  ? 'Rp •••••••'
                  : formatRupiah(detail.basicSalary),
              isDark,
            ),
          if (detail.dailySalary != null && detail.dailySalary! > 0)
            _buildInfoRow(
              'Gaji Harian',
              isPrivacyMasked
                  ? 'Rp ••••••• / hari'
                  : '${formatRupiah(detail.dailySalary!)} / hari',
              isDark,
            ),
          if (detail.employee.bankName != null &&
              detail.employee.bankName!.isNotEmpty)
            _buildInfoRow(
              'Rekening Pembayaran',
              '${detail.employee.bankName} - ${detail.employee.accountNumber ?? "-"}',
              isDark,
            ),
          if (detail.employee.taxStatus != null &&
              detail.employee.taxStatus!.isNotEmpty)
            _buildInfoRow(
                'Status PTKP Pajak', detail.employee.taxStatus!, isDark),
          if (detail.employee.bpjsEmployment != null &&
              detail.employee.bpjsEmployment!.isNotEmpty)
            _buildInfoRow(
              'No. BPJS Ketenagakerjaan',
              detail.employee.bpjsEmployment!,
              isDark,
            ),
          if (detail.employee.bpjsHealth != null &&
              detail.employee.bpjsHealth!.isNotEmpty)
            _buildInfoRow(
              'No. BPJS Kesehatan',
              detail.employee.bpjsHealth!,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeHomePayCard(
    BuildContext context,
    PayrollDetailModel detail,
    bool isPrivacyMasked,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.brandTeal.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Take Home Pay (Gaji Bersih)',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPrivacyMasked
                ? 'Rp ••••••••••'
                : formatRupiah(detail.netSalary),
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (detail.terbilang.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Terbilang: ${detail.terbilang}',
              style: AppTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    PayrollDetailModel detail,
    PayrollDetailState state,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.sm,
        AppSpacing.marginMobile,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Lihat PDF',
                leadingIcon: LucideIcons.fileText,
                variant: AppButtonVariant.outlined,
                onPressed: () => _openPdfViewer(context, detail),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                text: 'Unduh PDF',
                leadingIcon: LucideIcons.download,
                variant: AppButtonVariant.primary,
                isLoading: state.isDownloading,
                onPressed: () {
                  context.read<PayrollDetailBloc>().add(
                        const PayrollDetailDownloadRequested(force: true),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
