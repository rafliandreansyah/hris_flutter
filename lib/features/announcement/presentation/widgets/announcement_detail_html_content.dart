import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Perender konten pengumuman yang mendukung sintaks HTML lengkap
/// menggunakan pustaka industri `flutter_widget_from_html`.
class AnnouncementDetailHtmlContent extends StatelessWidget {
  final String htmlContent;

  const AnnouncementDetailHtmlContent({
    super.key,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF334155);

    if (htmlContent.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: HtmlWidget(
        htmlContent,
        textStyle: AppTypography.bodyMedium.copyWith(
          color: textCol,
          fontSize: 14.5,
          height: 1.6,
        ),
        onTapUrl: (url) async {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
          return false;
        },
        customStylesBuilder: (element) {
          if (element.localName == 'a') {
            return {'color': '#0D9488', 'text-decoration': 'underline'};
          }
          if (element.localName == 'p') {
            return {'margin-bottom': '12px'};
          }
          if (element.localName == 'h1' ||
              element.localName == 'h2' ||
              element.localName == 'h3') {
            return {'font-weight': '700', 'margin-bottom': '8px'};
          }
          return null;
        },
      ),
    );
  }
}
