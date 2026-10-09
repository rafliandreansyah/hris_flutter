import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_bloc.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_state.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_slip_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PayrollEmployeeSlipsScreen extends StatelessWidget {
  final PayrollEmployeeItemModel employee;
  final PayrollRepository? repository;
  final PayrollEmployeeSlipsBloc? bloc;

  const PayrollEmployeeSlipsScreen({
    super.key,
    required this.employee,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<PayrollEmployeeSlipsBloc>.value(
        value: bloc!,
        child: _PayrollEmployeeSlipsView(employee: employee),
      );
    }

    return BlocProvider<PayrollEmployeeSlipsBloc>(
      create: (context) {
        final repo = repository ?? context.read<PayrollRepository>();
        return PayrollEmployeeSlipsBloc(
          repository: repo,
          employeeId: employee.id,
        )..add(PayrollEmployeeSlipsStarted(employee.id));
      },
      child: _PayrollEmployeeSlipsView(employee: employee),
    );
  }
}

class _PayrollEmployeeSlipsView extends StatefulWidget {
  final PayrollEmployeeItemModel employee;

  const _PayrollEmployeeSlipsView({required this.employee});

  @override
  State<_PayrollEmployeeSlipsView> createState() =>
      _PayrollEmployeeSlipsViewState();
}

class _PayrollEmployeeSlipsViewState extends State<_PayrollEmployeeSlipsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context
          .read<PayrollEmployeeSlipsBloc>()
          .add(const PayrollEmployeeSlipsLoadMore());
    }
  }

  Future<void> _handleRefresh() async {
    context
        .read<PayrollEmployeeSlipsBloc>()
        .add(const PayrollEmployeeSlipsRefreshed());
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _handleTogglePrivacy(
    BuildContext context,
    bool isCurrentlyMasked,
  ) async {
    if (isCurrentlyMasked) {
      try {
        final authenticated = await BiometricService.instance.authenticate(
          localizedReason:
              'Konfirmasi identitas Anda untuk menampilkan nominal slip gaji',
          biometricOnly: false,
        );

        if (!authenticated) return;
        if (!context.mounted) return;

        context
            .read<PayrollEmployeeSlipsBloc>()
            .add(const PayrollEmployeeSlipsPrivacyToggled());
      } on BiometricException catch (e) {
        if (!context.mounted) return;
        if (e.code == 'NOT_ENROLLED' || e.code == 'NOT_AVAILABLE') {
          AppDialogUtil.showWarning(
            context,
            title: 'Keamanan Perangkat Belum Diatur',
            message:
                'Untuk membuka nominal slip gaji, silakan aktifkan kunci layar (PIN, Pola, Sandi, atau Biometrik) pada menu Pengaturan smartphone Anda terlebih dahulu.',
            confirmText: 'Mengerti',
          );
        } else {
          AppDialogUtil.showError(
            context,
            title: 'Autentikasi Gagal',
            message: e.message,
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Autentikasi Gagal',
          message: 'Gagal melakukan verifikasi keamanan perangkat.',
        );
      }
    } else {
      context
          .read<PayrollEmployeeSlipsBloc>()
          .add(const PayrollEmployeeSlipsPrivacyToggled());
    }
  }

  void _openFilter(PayrollEmployeeSlipsState state) {
    PayrollFilterBottomSheet.show(
      context,
      initialYear: state.selectedYear,
      initialMonth: state.selectedMonth,
      initialStatus: state.selectedStatus,
      isTeamTab: false,
      onApply: ({year, month, status, companyId, departmentId}) {
        context.read<PayrollEmployeeSlipsBloc>().add(
              PayrollEmployeeSlipsFilterApplied(
                year: year,
                month: month,
                status: status,
              ),
            );
      },
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

    final employee = widget.employee;
    final initials = _getInitials(employee.displayName);
    final photoUrl = employee.resolvedPhotoUrl;

    return BlocBuilder<PayrollEmployeeSlipsBloc, PayrollEmployeeSlipsState>(
      builder: (context, state) {
        final hasActiveFilter = state.selectedYear != DateTime.now().year ||
            state.selectedMonth != null ||
            (state.selectedStatus != null && state.selectedStatus != 'all') ||
            state.searchQuery.isNotEmpty;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slip Gaji Pegawai',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textCol,
                    fontSize: 17,
                  ),
                ),
                Text(
                  employee.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  state.isPrivacyMasked
                      ? LucideIcons.eyeOff
                      : LucideIcons.eye,
                  color: state.isPrivacyMasked ? subtitleCol : brandColor,
                  size: 20,
                ),
                onPressed: () =>
                    _handleTogglePrivacy(context, state.isPrivacyMasked),
              ),
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      color: hasActiveFilter ? brandColor : textCol,
                      size: 20,
                    ),
                    if (hasActiveFilter)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: brandColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _openFilter(state),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: brandColor,
            child: Column(
              children: [
                // 1. Employee Header Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceCol,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: brandColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        Center(
                                      child: Text(
                                        initials,
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          color: brandColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: brandColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.displayName,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: textCol,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${employee.positionName != "-" ? employee.positionName : employee.departmentName} • ${employee.company.name}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (employee.employeeNumber != null &&
                                  employee.employeeNumber!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'NIK: ${employee.employeeNumber}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Search Bar for Payslips
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Cari periode slip gaji...',
                  onChanged: (val) {
                    context
                        .read<PayrollEmployeeSlipsBloc>()
                        .add(PayrollEmployeeSlipsSearchChanged(val));
                  },
                ),

                // 3. Slips List
                Expanded(
                  child: _buildSlipsContent(context, state, isDark, brandColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlipsContent(
    BuildContext context,
    PayrollEmployeeSlipsState state,
    bool isDark,
    Color brandColor,
  ) {
    if (state.status == PayrollEmployeeSlipsStatus.loading &&
        state.slips.isEmpty) {
      return const RequestCardShimmerLoading(itemCount: 4);
    }

    if (state.slips.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.wallet,
          title: 'Tidak Ada Slip Gaji',
          message:
              'Belum ada slip gaji yang diterbitkan untuk pegawai ini sesuai filter yang dipilih.',
          hasActiveFilter: state.selectedYear != DateTime.now().year ||
              state.selectedMonth != null ||
              (state.selectedStatus != null && state.selectedStatus != 'all') ||
              state.searchQuery.isNotEmpty,
          onResetFilter: () {
            _searchController.clear();
            context.read<PayrollEmployeeSlipsBloc>().add(
                  PayrollEmployeeSlipsFilterApplied(
                    year: DateTime.now().year,
                    month: null,
                    status: null,
                  ),
                );
          },
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        4,
        AppSpacing.marginMobile,
        24,
      ),
      itemCount: state.slips.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.slips.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandTeal,
              ),
            ),
          );
        }

        final slip = state.slips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PayrollSlipCard(
            slip: slip,
            isPrivacyMasked: state.isPrivacyMasked,
            isTeamCard: false,
            onTap: () {
              context.push(Routes.PAYROLL_DETAIL, extra: slip.id);
            },
            onDownload:
                slip.payslipUrl != null && slip.payslipUrl!.isNotEmpty
                    ? () {
                        context.push(
                          Routes.PDF_VIEWER,
                          extra: {
                            'title': 'Slip Gaji - ${slip.period.label}',
                            'fileName': 'Slip_Gaji_${slip.period.label.replaceAll(" ", "_")}.pdf',
                            'fileUrl': slip.payslipUrl!,
                          },
                        );
                      }
                    : null,
          ),
        );
      },
    );
  }
}
