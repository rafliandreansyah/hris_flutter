import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Status pengajuan berupa ikon saja (tanpa teks) agar ringkas & konsisten.
///
/// Makna status dijaga lewat warna ([AppStatusTone]), [Tooltip] saat ditekan
/// lama, dan label semantik untuk pembaca layar.
class AppStatusIcon extends StatelessWidget {
  final String label;
  final AppStatusTone tone;
  final IconData? icon;
  final double size;

  const AppStatusIcon({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.size = 32,
  });

  /// Ikon + nada dari teks status API/enum (requested, approved, rejected, …).
  /// [label] default-nya label Indonesia standar untuk status tersebut.
  factory AppStatusIcon.fromStatus(
    String status, {
    Key? key,
    String? label,
    double size = 32,
  }) {
    final s = status.toLowerCase().trim();
    return AppStatusIcon(
      key: key,
      label: label ?? labelFor(s),
      tone: AppStatusTone.fromStatus(s),
      icon: iconFor(s),
      size: size,
    );
  }

  /// Label Indonesia seragam untuk status pengajuan.
  static String labelFor(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'approved':
      case 'disetujui':
        return 'Disetujui';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      case 'canceled':
      case 'cancelled':
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'disbursed':
      case 'paid':
      case 'dicairkan':
        return 'Dicairkan';
      case 'settlement_in_progress':
      case 'settlementinprogress':
        return 'Proses Penyelesaian';
      case 'settled':
      case 'selesai':
        return 'Selesai';
      default:
        return 'Menunggu Persetujuan';
    }
  }

  /// Ikon untuk status; status tak dikenal dianggap menunggu.
  static IconData iconFor(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'approved':
      case 'disetujui':
        return LucideIcons.circleCheck;
      case 'rejected':
      case 'ditolak':
        return LucideIcons.circleX;
      case 'canceled':
      case 'cancelled':
      case 'dibatalkan':
        return LucideIcons.ban;
      case 'disbursed':
      case 'paid':
      case 'dicairkan':
        return LucideIcons.wallet;
      case 'settlement_in_progress':
      case 'settlementinprogress':
        return LucideIcons.hourglass;
      case 'settled':
      case 'selesai':
        return LucideIcons.badgeCheck;
      default:
        return LucideIcons.clock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, _) = appStatusToneColors(tone, isDark);
    final resolvedIcon = icon ?? _defaultIconFor(tone);

    return Semantics(
      label: 'Status: $label',
      child: Tooltip(
        message: label,
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(resolvedIcon, size: size * 0.55, color: fg),
        ),
      ),
    );
  }

  static IconData _defaultIconFor(AppStatusTone tone) {
    switch (tone) {
      case AppStatusTone.success:
        return LucideIcons.circleCheck;
      case AppStatusTone.error:
        return LucideIcons.circleX;
      case AppStatusTone.info:
        return LucideIcons.wallet;
      case AppStatusTone.warning:
        return LucideIcons.clock;
      case AppStatusTone.neutral:
        return LucideIcons.circleDot;
    }
  }
}
