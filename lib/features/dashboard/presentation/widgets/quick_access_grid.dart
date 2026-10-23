import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kelompok menu pada sheet "Lainnya".
enum MenuGroup { attendance, requests, finance, employee }

class _MenuDef {
  final String code;

  /// Judul Indonesia yang stabil, hanya untuk pencocokan nama menu dari API.
  final String matchTitle;
  final IconData icon;
  final MenuGroup group;
  final String Function(AppLocalizations? l10n) title;

  const _MenuDef({
    required this.code,
    required this.matchTitle,
    required this.icon,
    required this.group,
    required this.title,
  });
}

/// Menu Akses Cepat Dashboard (Teal Oasis).
///
/// Menampilkan maksimal 7 menu utama + tile "Lainnya" (bottom sheet berisi semua
/// menu per kelompok). Menu yang tidak ada di respon API `/auth/menus`
/// disembunyikan. Judul mengikuti bahasa aplikasi lewat [AppLocalizations].
class QuickAccessGrid extends StatelessWidget {
  final List<MenuItemModel>? menus;

  const QuickAccessGrid({super.key, this.menus});

  /// Jumlah menu yang tampil langsung sebelum sisanya masuk ke "Lainnya".
  static const int _maxPrimary = 7;

  /// Bila total menu tersedia tidak lebih dari ini, semua ditampilkan langsung.
  static const int _showAllThreshold = 8;

  /// Urutan prioritas menu utama (paling sering dipakai).
  static const List<String> _primaryOrder = [
    'mobile_attendance',
    'mobile_leave',
    'mobile_overtime',
    'mobile_attendance_request_live',
    'mobile_activity',
    'mobile_payroll',
    'mobile_reimbursement',
  ];

  /// Daftar menu standar; kode disinkronkan dengan entitas Menu di backend.
  static final List<_MenuDef> _defaultMenus = [
    _MenuDef(
      code: 'mobile_attendance',
      matchTitle: 'Presensi',
      icon: LucideIcons.fingerprint,
      group: MenuGroup.attendance,
      title: (l) => l?.menuAttendance ?? 'Presensi',
    ),
    _MenuDef(
      code: 'mobile_attendance_request_live',
      matchTitle: 'Absen Luar',
      icon: LucideIcons.mapPin,
      group: MenuGroup.attendance,
      title: (l) => l?.menuOutsideAttendance ?? 'Absen Luar',
    ),
    _MenuDef(
      code: 'mobile_schedule',
      matchTitle: 'Jadwal Kerja',
      icon: LucideIcons.calendarClock,
      group: MenuGroup.attendance,
      title: (l) => l?.menuSchedule ?? 'Jadwal Kerja',
    ),
    _MenuDef(
      code: 'mobile_live_tracking',
      matchTitle: 'Live Tracking',
      icon: LucideIcons.radar,
      group: MenuGroup.attendance,
      title: (l) => l?.menuLiveTracking ?? 'Live Tracking',
    ),
    _MenuDef(
      code: 'mobile_leave',
      matchTitle: 'Izin & Cuti',
      icon: LucideIcons.calendarOff,
      group: MenuGroup.requests,
      title: (l) => l?.menuLeave ?? 'Izin & Cuti',
    ),
    _MenuDef(
      code: 'mobile_overtime',
      matchTitle: 'Lembur',
      icon: LucideIcons.clockAlert,
      group: MenuGroup.requests,
      title: (l) => l?.menuOvertime ?? 'Lembur',
    ),
    _MenuDef(
      code: 'mobile_activity',
      matchTitle: 'Aktivitas',
      icon: LucideIcons.clipboardList,
      group: MenuGroup.requests,
      title: (l) => l?.menuActivity ?? 'Aktivitas',
    ),
    _MenuDef(
      code: 'mobile_payroll',
      matchTitle: 'Slip Gaji',
      icon: LucideIcons.wallet,
      group: MenuGroup.finance,
      title: (l) => l?.menuPayroll ?? 'Slip Gaji',
    ),
    _MenuDef(
      code: 'mobile_reimbursement',
      matchTitle: 'Klaim & Kasbon',
      icon: LucideIcons.receiptText,
      group: MenuGroup.finance,
      title: (l) => l?.menuClaims ?? 'Klaim & Kasbon',
    ),
    _MenuDef(
      code: 'mobile_employee',
      matchTitle: 'Pegawai',
      icon: LucideIcons.users,
      group: MenuGroup.employee,
      title: (l) => l?.menuEmployee ?? 'Pegawai',
    ),
    _MenuDef(
      code: 'mobile_warning_letter',
      matchTitle: 'Surat Peringatan',
      icon: LucideIcons.triangleAlert,
      group: MenuGroup.employee,
      title: (l) => l?.menuWarningLetter ?? 'Surat Peringatan',
    ),
    _MenuDef(
      code: 'mobile_asset',
      matchTitle: 'Asset',
      icon: LucideIcons.packageCheck,
      group: MenuGroup.employee,
      title: (l) => l?.menuAsset ?? 'Aset',
    ),
    _MenuDef(
      code: 'mobile_resignation',
      matchTitle: 'Resign',
      icon: LucideIcons.doorOpen,
      group: MenuGroup.employee,
      title: (l) => l?.menuResignation ?? 'Pengunduran Diri',
    ),
  ];

  static Color _groupColor(MenuGroup group) => switch (group) {
    MenuGroup.attendance => AppColors.brandTeal,
    MenuGroup.requests => AppColors.warning,
    MenuGroup.finance => AppColors.success,
    MenuGroup.employee => AppColors.tertiary,
  };

  static String _groupTitle(MenuGroup group, AppLocalizations? l) =>
      switch (group) {
        MenuGroup.attendance => l?.menuGroupAttendance ?? 'Kehadiran',
        MenuGroup.requests => l?.menuGroupRequests ?? 'Pengajuan',
        MenuGroup.finance => l?.menuGroupFinance ?? 'Keuangan',
        MenuGroup.employee => l?.menuGroupEmployee ?? 'Karyawan',
      };

  /// Memeriksa apakah menu tertentu ada di dalam daftar menu API `/auth/menus`
  static bool isMenuAvailable(
    String code,
    String title,
    List<MenuItemModel>? apiMenus,
  ) {
    if (apiMenus == null) return true; // Default aktif jika belum load/offline
    final targetCode = code.toLowerCase().trim();
    final targetTitle = title.toLowerCase().trim();

    // 🌟 Khusus "Absen Luar Kantor":
    // Cek minimal memiliki 1 menu antara `mobile_attendance_request_live` ATAU `mobile_attendance_request_schedule`
    if (targetCode == 'mobile_attendance_request_live' ||
        targetCode == 'mobile_attendance_request_schedule' ||
        targetTitle.contains('absen luar') ||
        targetTitle.contains('luar kantor')) {
      final hasLive = apiMenus.any((m) {
        final c = m.code.toLowerCase().trim();
        final n = m.name.toLowerCase().trim();
        return c == 'mobile_attendance_request_live' ||
            n.contains('absen luar kantor (live)');
      });

      final hasSchedule = apiMenus.any((m) {
        final c = m.code.toLowerCase().trim();
        final n = m.name.toLowerCase().trim();
        return c == 'mobile_attendance_request_schedule' ||
            n.contains('absen luar kantor (schedule)');
      });

      return hasLive || hasSchedule;
    }

    return apiMenus.any((m) {
      final mCode = m.code.toLowerCase().trim();
      final mName = m.name.toLowerCase().trim();

      // 1. Prioritaskan kecocokan persis pada code (case-insensitive)
      if (mCode == targetCode) return true;

      // 2. Kecocokan pada nama menu
      if (mName == targetTitle) return true;
      if (mName.contains(targetTitle) || targetTitle.contains(mName)) {
        return true;
      }

      // 3. Kecocokan nama umum bahasa Inggris/Indonesia
      if (targetCode == 'mobile_activity' &&
          (mName.contains('aktifitas') || mName.contains('activity'))) {
        return true;
      }
      if (targetCode == 'mobile_overtime' &&
          (mName.contains('lembur') || mName.contains('overtime'))) {
        return true;
      }
      if (targetCode == 'mobile_leave' &&
          (mName.contains('cuti') ||
              mName.contains('izin') ||
              mName.contains('leave'))) {
        return true;
      }
      if (targetCode == 'mobile_attendance' &&
          (mName == 'presensi' ||
              mName == 'attendance' ||
              mName == 'presensi / absensi' ||
              mName == 'absensi')) {
        return true;
      }
      if (targetCode == 'mobile_employee' &&
          (mName.contains('pegawai') ||
              mName.contains('employee') ||
              mName.contains('karyawan'))) {
        return true;
      }
      if (targetCode == 'mobile_warning_letter' &&
          (mName.contains('peringatan') ||
              mName.contains('warning') ||
              RegExp(r'\bsp\b').hasMatch(mName))) {
        return true;
      }
      if (targetCode == 'mobile_payroll' &&
          (mName.contains('gaji') ||
              mName.contains('payroll') ||
              mName.contains('slip'))) {
        return true;
      }
      if (targetCode == 'mobile_schedule' &&
          (mName.contains('jadwal') || mName.contains('schedule'))) {
        return true;
      }
      if (targetCode == 'mobile_reimbursement' &&
          (mName.contains('reimburse') ||
              mName.contains('klaim') ||
              mName.contains('kasbon') ||
              mName.contains('expense') ||
              mName.contains('biaya'))) {
        return true;
      }
      if (targetCode == 'mobile_asset' &&
          (mName.contains('fasilitas') ||
              mName.contains('aset') ||
              mName.contains('asset'))) {
        return true;
      }

      if (targetCode == 'mobile_resignation' &&
          (mCode == 'mobile_resignation' ||
              mCode == 'approval_resignation' ||
              mCode == 'employee_resignation' ||
              mName.contains('resign') ||
              mName.contains('pengunduran') ||
              mName.contains('offboarding'))) {
        return true;
      }

      if (targetCode == 'mobile_live_tracking' &&
          (mCode == 'mobile_live_tracking' ||
              mCode == 'report_live_tracking' ||
              mCode == 'live_tracking' ||
              mName.contains('tracking') ||
              mName.contains('pelacakan'))) {
        return true;
      }

      return false;
    });
  }

  static void handleMenuTap(BuildContext context, String code, String title) {
    final c = code.toLowerCase();

    if (c == 'mobile_employee') {
      context.push(Routes.EMPLOYEE_DIRECTORY);
    } else if (c == 'mobile_activity') {
      context.push(Routes.ACTIVITY);
    } else if (c == 'mobile_attendance') {
      context.push(Routes.ATTENDANCE_LOGS);
    } else if (c == 'mobile_leave') {
      context.push(Routes.LEAVE);
    } else if (c == 'mobile_overtime') {
      context.push(Routes.OVERTIME);
    } else if (c == 'mobile_attendance_request_live' ||
        c == 'mobile_attendance_request_schedule') {
      context.push(Routes.ATTENDANCE_REQUESTS);
    } else if (c == 'mobile_warning_letter') {
      context.push(Routes.WARNING_LETTER);
    } else if (c == 'mobile_schedule' || c == 'mobile_employee_schedule') {
      context.push(Routes.WORK_SCHEDULE);
    } else if (c == 'mobile_reimbursement') {
      context.push(Routes.EXPENSES);
    } else if (c == 'mobile_asset' || c == 'mobile_assets') {
      context.push(Routes.ASSETS);
    } else if (c == 'mobile_resignation') {
      context.push(Routes.RESIGNATION);
    } else if (c == 'mobile_live_tracking') {
      context.push(Routes.LIVE_TRACKING);
    } else if (c == 'mobile_payroll') {
      context.push(Routes.PAYROLL);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Menu $title segera hadir')));
    }
  }

  /// Menu yang tersedia (sesuai API) dalam urutan: utama dulu, lalu sisanya.
  List<_MenuDef> _available() {
    final list = menus == null
        ? _defaultMenus
        : _defaultMenus
              .where((m) => isMenuAvailable(m.code, m.matchTitle, menus))
              .toList();
    int rank(_MenuDef m) {
      final i = _primaryOrder.indexOf(m.code);
      return i == -1 ? _primaryOrder.length : i;
    }

    // sort stabil: kelompokkan prioritas, pertahankan urutan default untuk sisanya
    final indexed = list.asMap().entries.toList()
      ..sort((a, b) {
        final r = rank(a.value).compareTo(rank(b.value));
        return r != 0 ? r : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  void _openMoreSheet(BuildContext context, List<_MenuDef> all) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in MenuGroup.values)
                  if (all.any((m) => m.group == group)) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        _groupTitle(group, l10n).toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    _MenuGrid(
                      tiles: [
                        for (final m in all.where((m) => m.group == group))
                          _MenuTile(
                            key: ValueKey('menu_${m.code}'),
                            icon: m.icon,
                            label: m.title(l10n),
                            color: _groupColor(m.group),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              handleMenuTap(context, m.code, m.matchTitle);
                            },
                          ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = _available();

    // `menus == null` = belum dimuat/offline (tampilkan default). List kosong dari
    // API berarti semua menu dicabut, sehingga tidak boleh menampilkan default.
    if (available.isEmpty) return const SizedBox.shrink();

    final showAll = available.length <= _showAllThreshold;
    final primary = showAll ? available : available.take(_maxPrimary).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.quickAccess ?? 'Akses Cepat',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        _MenuGrid(
          tiles: [
            for (final m in primary)
              _MenuTile(
                key: ValueKey('menu_${m.code}'),
                icon: m.icon,
                label: m.title(l10n),
                color: _groupColor(m.group),
                onTap: () => handleMenuTap(context, m.code, m.matchTitle),
              ),
            if (!showAll)
              _MenuTile(
                key: const ValueKey('quick_access_more'),
                icon: LucideIcons.layoutGrid,
                label: l10n?.menuMore ?? 'Lainnya',
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
                onTap: () => _openMoreSheet(context, available),
              ),
          ],
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final List<Widget> tiles;
  const _MenuGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm + AppSpacing.xs,
      childAspectRatio: 0.82,
      children: tiles,
    );
  }
}

/// Tile menu bersih: ikon di squircle berwarna lembut + label di bawahnya.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: AppRadius.borderLg,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
