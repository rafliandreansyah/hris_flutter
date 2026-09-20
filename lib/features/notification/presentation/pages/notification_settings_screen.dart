import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_settings/notification_settings_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class NotificationSettingsScreen extends StatelessWidget {
  final NotificationRepository? repository;
  final NotificationSettingsBloc? bloc;

  const NotificationSettingsScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<NotificationSettingsBloc>.value(
        value: bloc!,
        child: const _NotificationSettingsView(),
      );
    }

    return BlocProvider<NotificationSettingsBloc>(
      create: (context) {
        final effectiveRepo =
            repository ?? context.read<NotificationRepository?>();
        return NotificationSettingsBloc(
          repository: effectiveRepo,
        )..add(const NotificationSettingsStarted());
      },
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.surfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Berhasil',
            message: state.successMessage!,
          );
        } else if (state.errorMessage != null &&
            !state.isLoading &&
            state.currentSettings != null) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Menyimpan',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: bgCol,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: textCol),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengaturan Notifikasi',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelola preferensi pemberitahuan & alarm push',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.rotateCcw, size: 19, color: textCol),
                tooltip: 'Reset',
                onPressed: state.isLoading || state.currentSettings == null
                    ? null
                    : () {
                        context
                            .read<NotificationSettingsBloc>()
                            .add(const NotificationSettingsReset());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pengaturan dikembalikan ke awal'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
              ),
            ],
          ),
          body: _buildBody(
            context,
            state,
            isDark,
            textCol,
            subtitleCol,
            borderCol,
            cardBg,
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            state,
            isDark,
            borderCol,
            cardBg,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationSettingsState state,
    bool isDark,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    if (state.isLoading) {
      return const _NotificationSettingsShimmer();
    }

    if (state.currentSettings == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.bellOff,
                size: 48,
                color: subtitleCol,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Gagal memuat pengaturan notifikasi',
                style: AppTypography.bodyMedium.copyWith(color: textCol),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Coba Lagi',
                width: 160,
                height: 42,
                leadingIcon: LucideIcons.refreshCw,
                onPressed: () {
                  context
                      .read<NotificationSettingsBloc>()
                      .add(const NotificationSettingsStarted());
                },
              ),
            ],
          ),
        ),
      );
    }

    final settings = state.currentSettings!;

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        context
            .read<NotificationSettingsBloc>()
            .add(const NotificationSettingsRefreshed());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildMasterCard(
            context,
            state,
            isDark,
            textCol,
            subtitleCol,
            borderCol,
            cardBg,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('KEHADIRAN & JAM KERJA', subtitleCol),
          const SizedBox(height: 8),
          _buildGroupCard(
            borderCol: borderCol,
            cardBg: cardBg,
            children: [
              _NotificationSwitchTile(
                switchKey: const Key('switch_attendance_request'),
                icon: LucideIcons.fingerprint,
                iconColor: subtitleCol,
                title: 'Persetujuan Presensi',
                value: settings.pushAttendanceRequest,
                onChanged: (val) {
                  context.read<NotificationSettingsBloc>().add(
                        NotificationSettingsToggled(
                          key: NotificationSettingKey.attendanceRequest,
                          value: val,
                        ),
                      );
                },
              ),
              Divider(height: 1, color: borderCol),
              _NotificationSwitchTile(
                switchKey: const Key('switch_overtime'),
                icon: LucideIcons.timer,
                iconColor: subtitleCol,
                title: 'Lembur & Ekstra Shift',
                value: settings.pushOvertime,
                onChanged: (val) {
                  context.read<NotificationSettingsBloc>().add(
                        NotificationSettingsToggled(
                          key: NotificationSettingKey.overtime,
                          value: val,
                        ),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('IZIN, CUTI & PAYROLL', subtitleCol),
          const SizedBox(height: 8),
          _buildGroupCard(
            borderCol: borderCol,
            cardBg: cardBg,
            children: [
              _NotificationSwitchTile(
                switchKey: const Key('switch_leave'),
                icon: LucideIcons.palmtree,
                iconColor: subtitleCol,
                title: 'Cuti & Izin Kerja',
                value: settings.pushLeave,
                onChanged: (val) {
                  context.read<NotificationSettingsBloc>().add(
                        NotificationSettingsToggled(
                          key: NotificationSettingKey.leave,
                          value: val,
                        ),
                      );
                },
              ),
              Divider(height: 1, color: borderCol),
              _NotificationSwitchTile(
                switchKey: const Key('switch_payroll'),
                icon: LucideIcons.receipt,
                iconColor: subtitleCol,
                title: 'Slip Gaji & Pembayaran',
                value: settings.pushPayroll,
                onChanged: (val) {
                  context.read<NotificationSettingsBloc>().add(
                        NotificationSettingsToggled(
                          key: NotificationSettingKey.payroll,
                          value: val,
                        ),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('INFORMASI RESMI & KEPATUHAN', subtitleCol),
          const SizedBox(height: 8),
          _buildGroupCard(
            borderCol: borderCol,
            cardBg: cardBg,
            children: [
              _NotificationSwitchTile(
                switchKey: const Key('switch_announcement'),
                icon: LucideIcons.megaphone,
                iconColor: subtitleCol,
                title: 'Pengumuman Kantor',
                value: settings.pushAnnouncement,
                onChanged: (val) {
                  context.read<NotificationSettingsBloc>().add(
                        NotificationSettingsToggled(
                          key: NotificationSettingKey.announcement,
                          value: val,
                        ),
                      );
                },
              ),
              Divider(height: 1, color: borderCol),
              _NotificationSwitchTile(
                switchKey: const Key('switch_warning_letter'),
                icon: LucideIcons.triangleAlert,
                iconColor: AppColors.errorRed,
                iconBgColor: AppColors.errorRed.withValues(alpha: 0.12),
                title: 'Surat Peringatan & Teguran',
                value: settings.pushWarningLetter,
                onChanged: (val) {
                  context.read<NotificationSettingsBloc>().add(
                        NotificationSettingsToggled(
                          key: NotificationSettingKey.warningLetter,
                          value: val,
                        ),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasterCard(
    BuildContext context,
    NotificationSettingsState state,
    bool isDark,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    final isMasterOn = state.isMasterEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.12),
            ),
            child: const Icon(
              LucideIcons.bell,
              size: 20,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semua Notifikasi Push',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktifkan atau matikan seluruh notifikasi sekaligus',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            key: const Key('master_notification_switch'),
            value: isMasterOn,
            activeTrackColor: AppColors.brandTeal,
            onChanged: (val) {
              context
                  .read<NotificationSettingsBloc>()
                  .add(NotificationSettingsMasterToggled(val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subtitleCol) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: subtitleCol,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required Color borderCol,
    required Color cardBg,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: borderCol),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    NotificationSettingsState state,
    bool isDark,
    Color borderCol,
    Color cardBg,
  ) {
    if (state.currentSettings == null) return null;

    final updatedAt = state.currentSettings?.updatedAt;
    final updatedText = updatedAt != null
        ? 'Terakhir diperbarui: ${AppDateUtil.formatDateShort(updatedAt)}, ${AppDateUtil.formatTimeHHmm(updatedAt.toIso8601String())} WIB'
        : 'Terakhir diperbarui: Baru saja';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderCol, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              updatedText,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.surfaceVariant,
                fontSize: 11.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AppButton(
              text: 'Simpan Preferensi Notifikasi',
              leadingIcon: LucideIcons.save,
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      context
                          .read<NotificationSettingsBloc>()
                          .add(const NotificationSettingsSubmitted());
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;

  const _NotificationSwitchTile({
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.title,
    required this.value,
    required this.onChanged,
    this.switchKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (iconBgColor != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            )
          else
            Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            key: switchKey,
            value: value,
            activeTrackColor: AppColors.brandTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsShimmer extends StatelessWidget {
  const _NotificationSettingsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceContainer
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF8FAFC);

    Widget shimmerBox({
      required double height,
      double width = double.infinity,
      double radius = 12,
    }) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          shimmerBox(height: 72, radius: 16),
          const SizedBox(height: 24),
          shimmerBox(height: 18, width: 140, radius: 6),
          const SizedBox(height: 10),
          shimmerBox(height: 110, radius: 16),
          const SizedBox(height: 24),
          shimmerBox(height: 18, width: 160, radius: 6),
          const SizedBox(height: 10),
          shimmerBox(height: 110, radius: 16),
          const SizedBox(height: 24),
          shimmerBox(height: 18, width: 180, radius: 6),
          const SizedBox(height: 10),
          shimmerBox(height: 110, radius: 16),
        ],
      ),
    );
  }
}
