import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/utils/contact_launcher_util.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/whatsapp_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu informasi orang (pengaju / pejabat penyetuju) di halaman detail
/// pengajuan. Reusable untuk seluruh modul (cuti, lembur, presensi,
/// reimbursement, kasbon, dll).
///
/// Tata letak dibuat lega agar data panjang (mis. nama PT) tidak terpotong:
/// - Header: avatar + nama + jabatan (boleh 2 baris).
/// - Daftar info vertikal: label di atas, nilai di bawah, teks membungkus.
/// - Opsional tombol kontak (Telepon / WhatsApp / Email) — tampilkan saat
///   pengguna adalah approver yang perlu menghubungi pegawai.
/// - Opsional catatan (callout) — mis. catatan/alasan dari approver.
class RequestDetailPersonCard extends StatelessWidget {
  final String title;
  final String name;
  final String? position;

  /// Level/jenjang pegawai. Baris disembunyikan bila kosong.
  final String? level;
  final String? department;
  final String? company;
  final String? employeeNumber;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? initials;

  /// Tampilkan tombol untuk menghubungi orang ini.
  final bool showContactActions;

  /// Tampilkan baris email & telepon sebagai info (default: hanya bila
  /// tombol kontak ditampilkan, agar kartu tetap ringkas).
  final bool? showContactInfo;

  final String? notes;
  final String? notesLabel;
  final bool isRejected;

  /// Konten tambahan di bagian bawah kartu (mis. waktu persetujuan).
  final Widget? footer;

  const RequestDetailPersonCard({
    super.key,
    required this.title,
    required this.name,
    this.position,
    this.level,
    this.department,
    this.company,
    this.employeeNumber,
    this.email,
    this.phone,
    this.avatarUrl,
    this.initials,
    this.showContactActions = false,
    this.showContactInfo,
    this.notes,
    this.notesLabel,
    this.isRejected = false,
    this.footer,
  });

  /// True jika [employeeId] bukan milik pengguna yang sedang login —
  /// dipakai untuk menampilkan tombol kontak hanya saat melihat data orang lain.
  static bool isOtherPerson(String? employeeId) {
    final me = SecureStorageService.instance.employeeIdInMemory;
    if (employeeId == null || employeeId.isEmpty) return false;
    return me != null && me.isNotEmpty && me != employeeId;
  }

  bool _has(String? v) => v != null && v.trim().isNotEmpty && v.trim() != '-';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final withContactInfo = showContactInfo ?? showContactActions;
    final infoRows = <_InfoData>[
      if (_has(company))
        _InfoData(LucideIcons.building2, 'Perusahaan', company!.trim()),
      if (_has(department))
        _InfoData(LucideIcons.layers, 'Departemen', department!.trim()),
      if (_has(level))
        _InfoData(LucideIcons.chartNoAxesColumn, 'Level', level!.trim()),
      if (_has(employeeNumber))
        _InfoData(LucideIcons.idCard, 'No. Pegawai', employeeNumber!.trim()),
      if (withContactInfo && _has(email))
        _InfoData(LucideIcons.mail, 'Email', email!.trim()),
      if (withContactInfo && _has(phone))
        _InfoData(LucideIcons.phone, 'Telepon', phone!.trim()),
    ];
    final hasNotes = _has(notes);

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
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md - 4),

          // ── Header: avatar + nama + jabatan ──────────────────────────
          Row(
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                name: name,
                initials: initials,
                size: 48,
                backgroundColor: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.accentTealLight,
                textColor: isDark
                    ? AppColors.darkOnPrimaryContainer
                    : AppColors.primary,
                fontSize: 17,
              ),
              const SizedBox(width: AppSpacing.md - 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_has(position)) ...[
                      const SizedBox(height: 2),
                      Text(
                        position!.trim(),
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Daftar info (vertikal, teks membungkus) ─────────────────
          if (infoRows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md - 2),
            Divider(height: 1, thickness: 1, color: borderCol),
            const SizedBox(height: AppSpacing.xs),
            for (final row in infoRows)
              _InfoRow(
                data: row,
                textCol: textCol,
                subtitleCol: subtitleCol,
              ),
          ],

          // ── Tombol kontak ───────────────────────────────────────────
          if (showContactActions && (_has(phone) || _has(email))) ...[
            const SizedBox(height: AppSpacing.md - 4),
            _ContactActions(name: name, phone: phone, email: email),
          ],

          // ── Catatan ─────────────────────────────────────────────────
          if (hasNotes) ...[
            const SizedBox(height: AppSpacing.md - 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md - 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: isRejected ? AppColors.errorRed : brandColor,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isRejected
                        ? LucideIcons.triangleAlert
                        : LucideIcons.messageSquare,
                    size: 15,
                    color: isRejected ? AppColors.errorRed : brandColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_has(notesLabel)) ...[
                          Text(
                            notesLabel!,
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          notes!.trim(),
                          style: AppTypography.bodySmall.copyWith(
                            color: textCol,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md - 4),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _InfoData {
  final IconData icon;
  final String label;
  final String value;
  const _InfoData(this.icon, this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final _InfoData data;
  final Color textCol;
  final Color subtitleCol;

  const _InfoRow({
    required this.data,
    required this.textCol,
    required this.subtitleCol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(data.icon, size: 16, color: subtitleCol),
          ),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  data.value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.35,
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

class _ContactActions extends StatelessWidget {
  final String name;
  final String? phone;
  final String? email;

  const _ContactActions({required this.name, this.phone, this.email});

  @override
  Widget build(BuildContext context) {
    final hasPhone = ContactLauncherUtil.normalizePhone(phone) != null;
    final hasEmail = email != null && email!.trim().isNotEmpty;

    final buttons = <Widget>[
      if (hasPhone)
        _ContactButton(
          icon: const Icon(LucideIcons.phone, size: 16),
          label: 'Telepon',
          onTap: () => ContactLauncherUtil.callPhone(context, phone: phone),
        ),
      if (hasPhone)
        _ContactButton(
          icon: const WhatsAppIcon(size: 16),
          label: 'WhatsApp',
          onTap: () => ContactLauncherUtil.openWhatsApp(context, phone: phone),
        ),
      if (hasEmail)
        _ContactButton(
          icon: const Icon(LucideIcons.mail, size: 16),
          label: 'Email',
          onTap: () => ContactLauncherUtil.composeEmail(
            context,
            name: name,
            email: email,
          ),
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final bg = isDark
        ? AppColors.brandTeal.withValues(alpha: 0.16)
        : AppColors.primaryContainer.withValues(alpha: 0.55);

    return Material(
      color: bg,
      borderRadius: AppRadius.borderInput,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderInput,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: brandColor),
                child: icon,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: brandColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
