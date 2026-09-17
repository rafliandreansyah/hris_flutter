import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Ganti Password profil pegawai Oasish HRIS sesuai Stitch M3 "Teal Oasis".
class ChangePasswordScreen extends StatelessWidget {
  final EmployeeRepository? repository;
  final ChangePasswordBloc? bloc;

  const ChangePasswordScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<ChangePasswordBloc>.value(
        value: bloc!,
        child: const _ChangePasswordView(),
      );
    }

    return BlocProvider<ChangePasswordBloc>(
      create: (ctx) => ChangePasswordBloc(repository: repository),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _newPassword = '';

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() {
    setState(() {
      _newPassword = _newPasswordController.text;
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newPassword.length >= 8;
  bool get _hasUpperLower =>
      RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(_newPassword);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPassword);
  bool get _hasSymbol =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_newPassword);

  void _handleSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasMinLength || !_hasUpperLower || !_hasNumber || !_hasSymbol) {
      AppDialogUtil.showWarning(
        context,
        title: 'Kriteria Belum Terpenuhi',
        message:
            'Pastikan password baru telah memenuhi seluruh 4 kriteria kelayakan keamanan.',
      );
      return;
    }

    context.read<ChangePasswordBloc>().add(
          ChangePasswordSubmitted(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtextCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state.isFailure && state.errorMessage != null) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Ganti Password',
            message: state.errorMessage!,
          );
        } else if (state.isSuccess) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Berhasil',
            message: state.successMessage ?? 'Password berhasil diperbarui.',
            onOk: () {
              if (context.mounted) {
                context.pop();
              }
            },
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: _buildAppBar(context, isDark, textCol, subtextCol, borderCol),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Tips Keamanan Akun Card
                    _buildSecurityTipsCard(isDark),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Form Input Card
                    _buildFormCard(cardBg, borderCol, isDark),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Kriteria Kelayakan Password Card
                    _buildCriteriaCard(cardBg, borderCol, isDark, subtextCol),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Submit Button
                    AppButton(
                      text: 'Simpan & Perbarui Password',
                      leadingIcon: LucideIcons.save,
                      height: 52,
                      variant: AppButtonVariant.primary,
                      isLoading: state.isLoading,
                      onPressed: () => _handleSubmit(context),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textCol,
    Color subtextCol,
    Color borderCol,
  ) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.sm,
      title: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(LucideIcons.arrowLeft, color: textCol),
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ganti Password',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perbarui kata sandi akun keamanan Anda',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtextCol,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.md),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Icon(
            LucideIcons.shieldCheck,
            size: 20,
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTipsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.brandTeal.withValues(alpha: 0.12)
            : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.brandTeal.withValues(alpha: 0.3)
              : const Color(0xFFCCFBF1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.shield,
            size: 22,
            color: Color(0xFF0D9488),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Keamanan Akun',
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFF0D9488),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gunakan kombinasi minimal 8 karakter dengan huruf besar, huruf kecil, angka, dan simbol unik agar akun Anda tetap aman.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : const Color(0xFF115E59),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Color cardBg, Color borderCol, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Password Saat Ini
          AppTextField(
            label: 'Password Saat Ini *',
            hintText: 'Masukkan password saat ini',
            controller: _oldPasswordController,
            isPassword: true,
            prefixWidget: const Icon(
              LucideIcons.lock,
              size: 20,
              color: Color(0xFF0D9488),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password saat ini wajib diisi';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(Routes.RESET),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lupa Password?',
                style: AppTypography.labelMedium.copyWith(
                  color: const Color(0xFF0D9488),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Password Baru
          AppTextField(
            label: 'Password Baru *',
            hintText: 'Masukkan password baru',
            controller: _newPasswordController,
            isPassword: true,
            prefixWidget: const Icon(
              LucideIcons.lockKeyhole,
              size: 20,
              color: Color(0xFF0D9488),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password baru wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Konfirmasi Password Baru
          AppTextField(
            label: 'Konfirmasi Password Baru *',
            hintText: 'Konfirmasi password baru',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixWidget: const Icon(
              LucideIcons.circleCheck,
              size: 20,
              color: Color(0xFF0D9488),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Konfirmasi password baru wajib diisi';
              }
              if (value != _newPasswordController.text) {
                return 'Konfirmasi password tidak cocok';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaCard(
    Color cardBg,
    Color borderCol,
    bool isDark,
    Color subtextCol,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KRITERIA KELAYAKAN PASSWORD',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: subtextCol,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCriteriaItem(
            isMet: _hasMinLength,
            text: 'Minimal 8 karakter',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildCriteriaItem(
            isMet: _hasUpperLower,
            text: 'Mengandung huruf besar & kecil',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildCriteriaItem(
            isMet: _hasNumber,
            text: 'Mengandung angka (0-9)',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildCriteriaItem(
            isMet: _hasSymbol,
            text: 'Mengandung simbol (contoh: !@#\$%)',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem({
    required bool isMet,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          isMet ? LucideIcons.circleCheck : LucideIcons.circle,
          size: 18,
          color: isMet
              ? const Color(0xFF10B981)
              : (isDark
                  ? AppColors.darkOutlineVariant
                  : const Color(0xFF94A3B8)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: isMet
                  ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  : (isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
