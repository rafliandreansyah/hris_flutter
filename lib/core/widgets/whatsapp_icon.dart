import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hris_flutter/app/config/app_colors.dart';

/// Logo WhatsApp asli (glyph resmi dari Simple Icons, lisensi CC0) sebagai
/// pengganti ikon generik. Warna default hijau brand WhatsApp.
class WhatsAppIcon extends StatelessWidget {
  static const String assetPath = 'assets/icons/whatsapp.svg';

  final double size;

  /// Warna glyph; `null` memakai hijau brand [AppColors.whatsappGreen].
  final Color? color;

  const WhatsAppIcon({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      semanticsLabel: 'WhatsApp',
      colorFilter: ColorFilter.mode(
        color ?? AppColors.whatsappGreen,
        BlendMode.srcIn,
      ),
    );
  }
}
