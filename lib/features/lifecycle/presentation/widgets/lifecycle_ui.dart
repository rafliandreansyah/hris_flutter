import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Tanggal kalender (WIB) untuk tampilan, mis. `5 Nov 2026`.
String lcFormatDate(DateTime? d) =>
    d == null ? '-' : '${d.day} ${_months[d.month - 1]} ${d.year}';

class LifecycleColors {
  final bool isDark;
  const LifecycleColors(this.isDark);

  factory LifecycleColors.of(BuildContext context) =>
      LifecycleColors(Theme.of(context).brightness == Brightness.dark);

  Color get background => isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
  Color get card => isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
  Color get border => isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
  Color get text => isDark ? AppColors.darkOnSurface : AppColors.onSurface;
  Color get subtitle => isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
  Color get brand => isDark ? AppColors.inversePrimary : AppColors.brandTeal;
}

/// Kartu standar (border + radius token) untuk seluruh layar lifecycle.
class LifecycleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const LifecycleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return Material(
      color: c.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: c.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class LifecycleSectionTitle extends StatelessWidget {
  final String text;
  const LifecycleSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: c.subtitle,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

enum LifecycleTone { neutral, info, success, warning, danger }

class LifecycleStatusPill extends StatelessWidget {
  final String label;
  final LifecycleTone tone;

  const LifecycleStatusPill({super.key, required this.label, this.tone = LifecycleTone.neutral});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      LifecycleTone.success => (AppColors.successContainer, AppColors.onSuccessContainer),
      LifecycleTone.warning => (AppColors.warningContainer, AppColors.onWarningContainer),
      LifecycleTone.danger => (AppColors.errorContainer, AppColors.onErrorContainer),
      LifecycleTone.info => (AppColors.primaryContainer, AppColors.onPrimaryContainer),
      LifecycleTone.neutral => (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.borderFull),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

LifecycleTone evaluationStatusTone(String status) => switch (status) {
      'draft' => LifecycleTone.warning,
      'revision_requested' => LifecycleTone.danger,
      'submitted' || 'hr_reviewed' => LifecycleTone.info,
      'decided' || 'executed' => LifecycleTone.success,
      _ => LifecycleTone.neutral,
    };

/// Placeholder shimmer-less sederhana dipakai bila lebar kecil; daftar utama memakai RequestCardShimmerLoading.
class LifecycleErrorState extends StatelessWidget {
  final String message;
  final int? statusCode;
  final VoidCallback onRetry;

  const LifecycleErrorState({
    super.key,
    required this.message,
    this.statusCode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 48, color: c.subtitle),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: c.text),
        ),
        const SizedBox(height: AppSpacing.md),
        // 404: sumber daya tidak ada, hanya opsi kembali (tanpa coba lagi)
        if (statusCode != 404)
          Center(child: TextButton(onPressed: onRetry, child: const Text('Coba Lagi'))),
      ],
    );
  }
}
