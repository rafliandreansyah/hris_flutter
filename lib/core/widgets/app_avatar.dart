import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

/// Widget avatar serbaguna (reusable) untuk profil pegawai, atasan, atau rekan kerja.
///
/// Mendukung pemuatan gambar dari URL [imageUrl] dengan fallback otomatis ke
/// inisial nama [initials] atau diekstrak dari [name] jika gambar bernilai null,
/// kosong, atau gagal dimuat via jaringan.
class AppAvatar extends StatelessWidget {
  /// URL gambar avatar yang akan dimuat.
  final String? imageUrl;

  /// Nama lengkap untuk diekstrak inisialnya jika [initials] tidak disediakan.
  final String? name;

  /// Inisial eksplisit (misal: 'JD', 'AR').
  final String? initials;

  /// Diameter avatar dalam satuan logical pixel.
  final double size;

  /// Ukuran font untuk teks inisial. Jika null, otomatis dihitung dari [size].
  final double? fontSize;

  /// Bobot font untuk inisial.
  final FontWeight fontWeight;

  /// Warna latar belakang untuk kotak/lingkaran inisial.
  final Color? backgroundColor;

  /// Warna teks inisial.
  final Color? textColor;

  /// Warna garis batas avatar.
  final Color? borderColor;

  /// Ketebalan garis batas avatar.
  final double borderWidth;

  /// Apakah menampilkan border di sekeliling avatar.
  final bool showBorder;

  /// Bentuk avatar (default: [BoxShape.circle]).
  final BoxShape shape;

  /// Radius sudut jika [shape] bernilai [BoxShape.rectangle].
  final BorderRadius? borderRadius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.initials,
    this.size = 40.0,
    this.fontSize,
    this.fontWeight = FontWeight.w700,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showBorder = true,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  /// Helper statis untuk mengekstrak inisial 1-2 huruf kapital dari nama.
  static String extractInitials(String? name, {String? explicitInitials}) {
    if (explicitInitials != null && explicitInitials.trim().isNotEmpty) {
      return explicitInitials.trim().toUpperCase();
    }
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts.first.isNotEmpty ? parts.first[0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    } else {
      final single = parts.first;
      if (single.length >= 2) {
        return single.substring(0, 2).toUpperCase();
      }
      return single.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.accentTealLight;
    final defaultFg = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final defaultBorder = isDark
        ? AppColors.darkPrimary
        : AppColors.primaryFixedDim;

    final effectiveBg = backgroundColor ?? defaultBg;
    final effectiveFg = textColor ?? defaultFg;
    final effectiveBorderColor = borderColor ?? defaultBorder;

    final computedInitials = extractInitials(name, explicitInitials: initials);
    final effectiveFontSize = fontSize ?? (size * 0.38).clamp(10.0, 32.0);

    final border = showBorder && borderWidth > 0
        ? Border.all(color: effectiveBorderColor, width: borderWidth)
        : null;

    final effectiveBorderRadius = shape == BoxShape.circle
        ? BorderRadius.circular(size / 2)
        : (borderRadius ?? BorderRadius.circular(size * 0.25));

    final hasValidUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasValidUrl) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: effectiveBg,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? effectiveBorderRadius : null,
          border: border,
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: Image.network(
            imageUrl!.trim(),
            fit: BoxFit.cover,
            width: size,
            height: size,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildInitialsContainer(
                computedInitials,
                effectiveBg,
                effectiveFg,
                effectiveFontSize,
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildInitialsContainer(
              computedInitials,
              effectiveBg,
              effectiveFg,
              effectiveFontSize,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? effectiveBorderRadius : null,
        border: border,
      ),
      alignment: Alignment.center,
      child: _buildInitialsText(computedInitials, effectiveFg, effectiveFontSize),
    );
  }

  Widget _buildInitialsContainer(
    String text,
    Color bg,
    Color fg,
    double textSize,
  ) {
    return Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: _buildInitialsText(text, fg, textSize),
    );
  }

  Widget _buildInitialsText(String text, Color fg, double textSize) {
    return Text(
      text,
      style: AppTypography.titleMedium.copyWith(
        color: fg,
        fontWeight: fontWeight,
        fontSize: textSize,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}
