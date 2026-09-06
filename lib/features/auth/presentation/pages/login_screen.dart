import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_flutter/gen/assets.gen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Login Oasish HRIS menggunakan Global Widgets (AppTextField & AppButton)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: const _LoginFormView(),
    );
  }
}

class _LoginFormView extends StatefulWidget {
  const _LoginFormView();

  @override
  State<_LoginFormView> createState() => _LoginFormViewState();
}

class _LoginFormViewState extends State<_LoginFormView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignInPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginSubmitted(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Tekan sekali lagi untuk keluar',
                textAlign: TextAlign.center,
              ),
              behavior: SnackBarBehavior.floating,
              width: 250,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }

        // Keluar dari aplikasi jika ditekan 2 kali berturut-turut dalam 2 detik
        SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundSubtle,
      body: Stack(
        children: [
          // Background Gradient Subtle Teal
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    (isDark ? AppColors.brandTeal : AppColors.accentTealLight)
                        .withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Konten Utama
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // 1. Logo Oasish
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandTeal.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                Assets.icons.logo.path,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 2. Header Area
                            Text(
                              'Welcome Back',
                              style: AppTypography.headlineLargeMobile.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to continue',
                              style: AppTypography.bodyMedium.copyWith(
                                color: labelCol,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // 3. Card Container Form
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: borderCol, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.03,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Global Email Input
                                    AppTextField(
                                      label: 'Email Address',
                                      hintText: 'name@company.com',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: LucideIcons.mail,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Format email tidak valid';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Global Password Input dengan Forgot Password Link
                                    AppTextField(
                                      label: 'Password',
                                      labelTrailing: GestureDetector(
                                        onTap: () {
                                          context.push(Routes.RESET);
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                                color: AppColors.brandTeal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      hintText: '••••••••',
                                      controller: _passwordController,
                                      isPassword: true,
                                      prefixIcon: LucideIcons.lock,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          _onSignInPressed(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (value.length < 6) {
                                          return 'Password minimal 6 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    // 4. Global AppButton with BLoC
                                    BlocConsumer<AuthBloc, AuthState>(
                                      listener: (context, state) {
                                        if (state is AuthSuccess) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(state.message),
                                              backgroundColor:
                                                  AppColors.brandTeal,
                                            ),
                                          );
                                          context.go(Routes.DASHBOARD);
                                        } else if (state is AuthFailure) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(state.message),
                                              backgroundColor:
                                                  AppColors.errorRed,
                                            ),
                                          );
                                        }
                                      },
                                      builder: (context, state) {
                                        return AppButton(
                                          text: 'Login',
                                          trailingIcon: LucideIcons.arrowRight,
                                          isLoading: state is AuthLoading,
                                          onPressed: _onSignInPressed,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // 5. Contact HR Link
                                    Center(
                                      child: Text.rich(
                                        TextSpan(
                                          text: "Don't have an account? ",
                                          style: AppTypography.bodyMedium
                                              .copyWith(color: labelCol),
                                          children: [
                                            TextSpan(
                                              text: 'Contact HR',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.brandTeal,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Pendorong ke bawah (Spacer) & Jarak minimal jika layar kecil (SizedBox)
                            const Spacer(),
                            const SizedBox(height: 24),

                            // 6. Bottom Brand & Version Text
                            const AppNameVersionText(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
