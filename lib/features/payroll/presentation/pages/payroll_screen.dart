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
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_bloc.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_state.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_employee_card.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_hero_card.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_slip_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PayrollScreen extends StatelessWidget {
  final PayrollRepository? repository;
  final PayrollListBloc? bloc;

  const PayrollScreen({super.key, this.repository, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<PayrollListBloc>.value(
        value: bloc!,
        child: const _PayrollView(),
      );
    }

    return BlocProvider<PayrollListBloc>(
      create: (context) {
        final repo = repository ?? context.read<PayrollRepository>();
        return PayrollListBloc(repository: repo)
          ..add(const PayrollListStarted());
      },
      child: const _PayrollView(),
    );
  }
}

class _PayrollView extends StatefulWidget {
  const _PayrollView();

  @override
  State<_PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<_PayrollView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _myScrollController.addListener(_onMyScroll);
    _teamScrollController.addListener(_onTeamScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _myScrollController.removeListener(_onMyScroll);
    _myScrollController.dispose();
    _teamScrollController.removeListener(_onTeamScroll);
    _teamScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<PayrollListBloc>().add(
            PayrollListTabChanged(_tabController.index),
          );
    }
  }

  void _onMyScroll() {
    if (_myScrollController.position.pixels >=
        _myScrollController.position.maxScrollExtent - 200) {
      context.read<PayrollListBloc>().add(const PayrollListLoadMore());
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.position.pixels >=
        _teamScrollController.position.maxScrollExtent - 200) {
      context.read<PayrollListBloc>().add(const PayrollListLoadMore());
    }
  }

  Future<void> _handleRefresh() async {
    context.read<PayrollListBloc>().add(const PayrollListRefreshed());
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
            .read<PayrollListBloc>()
            .add(const PayrollListPrivacyToggled());
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
      context.read<PayrollListBloc>().add(const PayrollListPrivacyToggled());
    }
  }

  void _openFilter(PayrollListState state) {
    PayrollFilterBottomSheet.show(
      context,
      initialYear: state.selectedYear,
      initialMonth: state.selectedMonth,
      initialStatus: state.selectedStatus,
      initialCompanyId: state.selectedCompanyId,
      initialDepartmentId: state.selectedDepartmentId,
      isTeamTab: state.activeTab == 1,
      onApply: ({year, month, status, companyId, departmentId}) {
        context.read<PayrollListBloc>().add(
              PayrollListFilterApplied(
                year: year,
                month: month,
                status: status,
                companyId: companyId,
                departmentId: departmentId,
              ),
            );
      },
    );
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

    return BlocBuilder<PayrollListBloc, PayrollListState>(
      builder: (context, state) {
        final currentYear = DateTime.now().year;
        final hasActiveFilter = state.selectedYear != currentYear ||
            state.selectedMonth != null ||
            (state.selectedStatus != null && state.selectedStatus != 'all') ||
            state.selectedCompanyId != null ||
            state.selectedDepartmentId != null;

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
            title: Text(
              'Slip Gaji',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            actions: [
              if (state.activeTab == 0)
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
          body: Column(
            children: [
              // 1. TabBar Pill Container (Swipeable via TabBarView)
              if (state.canViewTeam)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLowest
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.06,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: brandColor,
                      unselectedLabelColor: subtitleCol,
                      labelStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.wallet, size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Slip Saya',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.users, size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Semua Pegawai',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. TabBarView Content (Supports Left/Right ViewPager Swipe)
              Expanded(
                child: state.canViewTeam
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMySlipsTab(context, state, isDark, brandColor),
                          _buildEmployeesTab(
                              context, state, isDark, brandColor),
                        ],
                      )
                    : _buildMySlipsTab(context, state, isDark, brandColor),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 0: Slip Saya
  Widget _buildMySlipsTab(
    BuildContext context,
    PayrollListState state,
    bool isDark,
    Color brandColor,
  ) {
    if (state.isMyLoading && state.mySlips.isEmpty) {
      return const RequestCardShimmerLoading(itemCount: 4);
    }

    if (state.mySlips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: AppEmptyState(
                icon: LucideIcons.wallet,
                title: 'Tidak Ada Slip Gaji',
                message:
                    'Belum ada slip gaji yang diterbitkan untuk periode ini.',
                hasActiveFilter:
                    state.selectedYear != DateTime.now().year ||
                        state.selectedMonth != null ||
                        (state.selectedStatus != null &&
                            state.selectedStatus != 'all') ||
                        state.selectedCompanyId != null ||
                        state.selectedDepartmentId != null,
                onResetFilter: () {
                  context.read<PayrollListBloc>().add(
                        PayrollListFilterApplied(
                          year: DateTime.now().year,
                          month: null,
                          status: null,
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.builder(
        controller: _myScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          4,
          AppSpacing.marginMobile,
          24,
        ),
        itemCount: 1 +
            (state.latestSlip != null ? 1 : 0) +
            state.mySlips.length +
            (state.isMyLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          int currentIndex = 0;

          // Hero Card
          if (state.latestSlip != null) {
            if (index == currentIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PayrollHeroCard(
                  slip: state.latestSlip!,
                  isPrivacyMasked: state.isPrivacyMasked,
                  onTogglePrivacy: () => _handleTogglePrivacy(
                    context,
                    state.isPrivacyMasked,
                  ),
                  onTapDetail: () {
                    context.push(
                      Routes.PAYROLL_DETAIL,
                      extra: state.latestSlip!.id,
                    );
                  },
                ),
              );
            }
            currentIndex++;
          }

          // Section Title
          if (index == currentIndex) {
            return Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                'Riwayat Slip Gaji',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
            );
          }
          currentIndex++;

          // Slips List Items
          final slipIndex = index - currentIndex;
          if (slipIndex < state.mySlips.length) {
            final slip = state.mySlips[slipIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PayrollSlipCard(
                slip: slip,
                isPrivacyMasked: state.isPrivacyMasked,
                isTeamCard: false,
                onTap: () {
                  context.push(Routes.PAYROLL_DETAIL, extra: slip.id);
                },
                onDownload: slip.payslipUrl != null &&
                        slip.payslipUrl!.isNotEmpty
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
          }

          // Loading More Indicator
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandTeal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tab 1: Semua Pegawai
  Widget _buildEmployeesTab(
    BuildContext context,
    PayrollListState state,
    bool isDark,
    Color brandColor,
  ) {
    return Column(
      children: [
        // Standard Search Bar
        AppSearchBar(
          controller: _searchController,
          hintText: 'Cari nama atau NIK pegawai...',
          onChanged: (val) {
            context
                .read<PayrollListBloc>()
                .add(PayrollListSearchChanged(val));
          },
        ),

        // Employees List / Shimmer / Empty State
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: brandColor,
            child: _buildEmployeesContent(
                context, state, isDark, brandColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesContent(
    BuildContext context,
    PayrollListState state,
    bool isDark,
    Color brandColor,
  ) {
    if (state.isEmployeesLoading && state.employees.isEmpty) {
      return const RequestCardShimmerLoading(itemCount: 5);
    }

    if (state.employees.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.users,
          title: 'Tidak Ada Pegawai',
          message:
              'Tidak ditemukan data pegawai sesuai kata kunci atau filter yang dipilih.',
          hasActiveFilter: state.searchQuery.isNotEmpty ||
              state.selectedCompanyId != null ||
              state.selectedDepartmentId != null,
          onResetFilter: () {
            _searchController.clear();
            context.read<PayrollListBloc>().add(
                  const PayrollListSearchChanged(''),
                );
          },
        ),
      );
    }

    return ListView.builder(
      controller: _teamScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        4,
        AppSpacing.marginMobile,
        24,
      ),
      itemCount: state.employees.length +
          (state.isEmployeesLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.employees.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandTeal,
              ),
            ),
          );
        }

        final employee = state.employees[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PayrollEmployeeCard(
            employee: employee,
            onTap: () {
              context.push(
                Routes.PAYROLL_EMPLOYEE_SLIPS,
                extra: employee,
              );
            },
          ),
        );
      },
    );
  }
}
