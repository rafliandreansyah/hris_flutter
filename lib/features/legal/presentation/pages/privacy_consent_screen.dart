import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/legal_links.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/legal_link_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/legal/presentation/bloc/legal_consent/legal_consent_bloc.dart';
import 'package:hris_flutter/gen/assets.gen.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Layar persetujuan Kebijakan Privasi & Syarat Ketentuan yang wajib disetujui
/// saat pertama kali membuka aplikasi (sebelum login).
class PrivacyConsentScreen extends StatelessWidget {
  /// Tujuan deep link yang ditunda sampai persetujuan diberikan.
  final String? pendingLink;
  final LegalConsentBloc? bloc;

  const PrivacyConsentScreen({super.key, this.pendingLink, this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LegalConsentBloc>(
      create: (_) => bloc ?? LegalConsentBloc(),
      child: _PrivacyConsentView(pendingLink: pendingLink),
    );
  }
}

class _PrivacyConsentView extends StatelessWidget {
  final String? pendingLink;

  const _PrivacyConsentView({this.pendingLink});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final dataItems = [
      (LucideIcons.mapPin, l10n?.consentDataLocation ??
          'Lokasi presisi untuk presensi. Selama Anda clock-in hingga clock-out dan saat tugas lapangan, rute kerja direkam termasuk saat aplikasi ditutup atau di latar belakang.'),
      (LucideIcons.camera, l10n?.consentDataCamera ??
          'Kamera dan foto untuk swafoto presensi, bukti aktivitas, dan dokumen klaim.'),
      (LucideIcons.fingerprint, l10n?.consentDataBiometric ??
          'Biometrik (sidik jari / Face ID) diproses di perangkat dan tidak dikirim ke server.'),
      (LucideIcons.smartphone, l10n?.consentDataDevice ??
          'Data kepegawaian, ID perangkat, level baterai, dan token notifikasi untuk menjalankan layanan.'),
    ];

    final documents = [
      (LucideIcons.shieldCheck, l10n?.legalPrivacyPolicy ?? 'Kebijakan Privasi',
          LegalLinks.privacyPolicy),
      (LucideIcons.fileText, l10n?.legalTerms ?? 'Syarat & Ketentuan',
          LegalLinks.termsConditions),
      (LucideIcons.receipt, l10n?.legalRefundPolicy ?? 'Kebijakan Pengembalian Dana',
          LegalLinks.refundPolicy),
      (LucideIcons.circleHelp, l10n?.legalFaq ?? 'FAQ', LegalLinks.faq),
      (LucideIcons.trash2, l10n?.legalDeleteData ?? 'Hapus Akun & Data',
          LegalLinks.deleteData),
      (LucideIcons.mail, l10n?.legalContact ?? 'Kontak', LegalLinks.contact),
    ];

    final sectionStyle = AppTypography.labelSmall.copyWith(
      color: subtitleCol,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    return BlocListener<LegalConsentBloc, LegalConsentState>(
      listenWhen: (prev, curr) =>
          prev.isAccepted != curr.isAccepted ||
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage),
      listener: (context, state) {
        if (state.isAccepted) {
          // Kembali ke splash agar pemeriksaan sesi & deep link berjalan seperti biasa.
          context.replaceNamed(
            Routes.SPLASH,
            queryParameters: {'from': ?pendingLink},
          );
        } else if (state.errorMessage != null) {
          AppDialogUtil.showError(context, message: state.errorMessage!);
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.backgroundSubtle,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Image.asset(Assets.icons.logo.path, width: 72, height: 72),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n?.consentTitle ?? 'Kebijakan Privasi & Syarat Ketentuan',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n?.consentIntro ??
                      'Sebelum menggunakan Oasish, mohon baca dan setujui cara kami mengumpulkan dan memproses data Anda.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: subtitleCol),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n?.consentDataHeader ?? 'DATA YANG KAMI PROSES',
                    style: sectionStyle),
                const SizedBox(height: AppSpacing.sm),
                _ConsentCard(
                  cardBg: cardBg,
                  borderCol: borderCol,
                  children: [
                    for (final (icon, text) in dataItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + AppSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 20, color: AppColors.brandTeal),
                            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                            Expanded(
                              child: Text(
                                text,
                                style: AppTypography.bodySmall
                                    .copyWith(color: textCol),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n?.consentDocumentsHeader ?? 'DOKUMEN LEGAL',
                    style: sectionStyle),
                const SizedBox(height: AppSpacing.sm),
                _ConsentCard(
                  cardBg: cardBg,
                  borderCol: borderCol,
                  children: [
                    for (final (index, (icon, title, url))
                        in documents.indexed) ...[
                      if (index > 0)
                        Divider(height: 1, thickness: 1, color: borderCol),
                      ListTile(
                        leading: Icon(icon, size: 20, color: AppColors.brandTeal),
                        title: Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(LucideIcons.externalLink,
                            size: 18, color: subtitleCol),
                        onTap: () => LegalLinkUtil.open(context, url),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.sm,
                AppSpacing.marginMobile,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderCol)),
              ),
              child: BlocBuilder<LegalConsentBloc, LegalConsentState>(
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: const Key('consent_agreement'),
                        borderRadius: AppRadius.borderMd,
                        onTap: state.isSubmitting
                            ? null
                            : () => context.read<LegalConsentBloc>().add(
                                LegalConsentAgreementToggled(!state.isAgreed)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: state.isAgreed,
                              activeColor: AppColors.brandTeal,
                              onChanged: state.isSubmitting
                                  ? null
                                  : (value) => context
                                      .read<LegalConsentBloc>()
                                      .add(LegalConsentAgreementToggled(
                                          value ?? false)),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: AppSpacing.sm + AppSpacing.xs / 2),
                                child: Text(
                                  l10n?.consentAgreement ??
                                      'Saya telah membaca dan menyetujui Kebijakan Privasi dan Syarat & Ketentuan Oasish.',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: textCol),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        key: const Key('consent_accept_button'),
                        text: l10n?.consentAccept ?? 'Setuju & Lanjutkan',
                        isLoading: state.isSubmitting,
                        onPressed: state.isAgreed && !state.isSubmitting
                            ? () => context
                                .read<LegalConsentBloc>()
                                .add(const LegalConsentAccepted())
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final Color cardBg;
  final Color borderCol;
  final List<Widget> children;

  const _ConsentCard({
    required this.cardBg,
    required this.borderCol,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: borderCol),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}
