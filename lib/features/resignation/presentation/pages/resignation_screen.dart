import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_state.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_clearance_snapshot_card.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_countdown_card.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_empty_state_card.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_stepper_card.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/subordinate_resignation_card.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ResignationScreen extends StatelessWidget {
  final ResignationRepository? resignationRepository;
  final ResignationListBloc? resignationListBloc;

  const ResignationScreen({
    super.key,
    this.resignationRepository,
    this.resignationListBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (resignationListBloc != null) {
      return BlocProvider<ResignationListBloc>.value(
        value: resignationListBloc!,
        child: const _ResignationScreenView(),
      );
    }
    return BlocProvider<ResignationListBloc>(
      create: (context) => ResignationListBloc(
        repository: resignationRepository,
      )..add(const ResignationListStarted()),
      child: const _ResignationScreenView(),
    );
  }
}

class _ResignationScreenView extends StatefulWidget {
  const _ResignationScreenView();

  @override
  State<_ResignationScreenView> createState() => _ResignationScreenViewState();
}

class _ResignationScreenViewState extends State<_ResignationScreenView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _teamScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _teamScrollController.addListener(_onTeamScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _teamScrollController.removeListener(_onTeamScroll);
    _teamScrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
      context.read<ResignationListBloc>().add(
            ResignationListTabChanged(_tabController.index),
          );
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 200) {
      context.read<ResignationListBloc>().add(
            const ResignationListSubordinatesLoadMore(),
          );
    }
  }

  Future<void> _openFilterBottomSheet() async {
    final bloc = context.read<ResignationListBloc>();
    final result = await showAppRequestFilterBottomSheet(
      context,
      title: 'Filter Pengajuan Resign',
      initialData: bloc.state.filterData,
    );
    if (result != null && mounted) {
      bloc.add(ResignationListFilterApplied(result));
    }
  }

  Future<void> _handleCancelMyResignation() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await AppDialogUtil.showConfirmation(
      context,
      title: 'Batalkan Pengajuan Resign?',
      message:
          'Pengajuan pengunduran diri Anda akan ditarik dan dibatalkan dari sistem.',
      confirmText: 'Ya, Batalkan',
      cancelText: 'Kembali',
      isDestructive: true,
      confirmButtonColor: AppColors.errorRed,
      icon: LucideIcons.triangleAlert,
    );

    if (confirmed == true && mounted) {
      context.read<ResignationListBloc>().add(
            const ResignationListCancelRequested(),
          );
    }
  }

  void _handleCreateResignation() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await context.push(Routes.CREATE_RESIGNATION);
    if (result == true && mounted) {
      context.read<ResignationListBloc>().add(
            const ResignationListMyStatusRequested(isRefresh: true),
          );
    }
  }

  void _handleViewDetail() {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Halaman Detail Pengunduran Diri segera hadir.'),
      ),
    );
  }

  void _handleExitInterview() {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kuesioner Exit Interview segera hadir.'),
      ),
    );
  }

  void _handleReviewSubordinate(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review 1-on-1 Atasan segera hadir.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return BlocConsumer<ResignationListBloc, ResignationListState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }
        if (state.cancelSuccess) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Berhasil Dibatalkan',
            message: 'Pengajuan pengunduran diri Anda berhasil dibatalkan.',
          );
        }
      },
      builder: (context, state) {
        final isTeamTab = _tabController.index == 1;
        final hasActiveFilter = state.filterData.hasActiveFilter;

        // Floating Action Button Rule:
        // FAB HANYA ada di tab kiri ketika hasActiveResignation false.
        final showFab = _tabController.index == 0 &&
            (state.myStatus != null && !state.hasActiveResignation);

        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: bgCol.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 1.5,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Resign',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Status & Pengajuan Karyawan',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _openFilterBottomSheet,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      color: hasActiveFilter ? brandColor : subtitleCol,
                      size: 20,
                    ),
                    if (hasActiveFilter)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: brandColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerLowest
                                  : AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController.animation ?? _tabController,
            builder: (context, child) {
              if (!showFab) return const SizedBox.shrink();
              final animVal = _tabController.animation?.value ??
                  _tabController.index.toDouble();
              final progress = (1.0 - animVal).clamp(0.0, 1.0);
              if (progress <= 0.05) {
                return const SizedBox.shrink();
              }
              return Transform.scale(
                scale: progress,
                alignment: Alignment.bottomRight,
                child: Opacity(opacity: progress, child: child),
              );
            },
            child: FloatingActionButton.extended(
              key: const ValueKey('create_resignation_fab'),
              onPressed: _handleCreateResignation,
              backgroundColor: brandColor,
              foregroundColor:
                  isDark ? const Color(0xFF003732) : Colors.white,
              elevation: 3,
              shape: const StadiumBorder(),
              icon: const Icon(LucideIcons.plus, size: 20),
              label: Text(
                'Ajukan Resign',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF003732) : Colors.white,
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Pill TabBar Container (Context-Aware Rule 16)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
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
                      splashBorderRadius: BorderRadius.circular(12),
                      tabs: [
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.doorOpen, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n?.tabMyRequests ?? 'Pengajuan Saya',
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
                              const Icon(LucideIcons.users, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n?.tabTeamApprovals ?? 'Persetujuan Tim',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (state.subordinatesTotal > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brandColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${state.subordinatesTotal}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: brandColor,
                                    ),
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

                // 2. Dynamic Collapsible Search Bar
                // Muncul hanya di Tab Kanan (Persetujuan Tim) dan Collapse/Hilang di Tab Kiri (Pengajuan Saya)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: isTeamTab ? 58 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(color: bgCol),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isTeamTab ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !isTeamTab,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceCol,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.02,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            style: AppTypography.bodyMedium.copyWith(
                              color: textCol,
                              fontSize: 14,
                            ),
                            onChanged: (val) {
                              context.read<ResignationListBloc>().add(
                                    ResignationListSearchChanged(val),
                                  );
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Cari nama bawahan, NIK, atau posisi...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: subtitleCol,
                                fontSize: 13.5,
                              ),
                              prefixIcon: Icon(
                                LucideIcons.search,
                                size: 18,
                                color: subtitleCol,
                              ),
                              suffixIcon: state.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        LucideIcons.x,
                                        size: 16,
                                        color: subtitleCol,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        context
                                            .read<ResignationListBloc>()
                                            .add(
                                              const ResignationListSearchChanged(
                                                '',
                                              ),
                                            );
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 0: Pengajuan Saya (Karyawan Mandiri - ESS)
                      _buildMyResignationTab(
                        context: context,
                        state: state,
                        isDark: isDark,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandCol: brandColor,
                      ),

                      // Tab 1: Persetujuan Tim (Atasan Langsung - MSS)
                      _buildTeamApprovalsTab(
                        context: context,
                        state: state,
                        isDark: isDark,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        surfaceCol: surfaceCol,
                        borderCol: borderCol,
                        brandCol: brandColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyResignationTab({
    required BuildContext context,
    required ResignationListState state,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required Color brandCol,
  }) {
    if (state.isMyStatusLoading && state.myStatus == null) {
      return const RequestCardShimmerLoading(itemCount: 3);
    }

    final myStatus = state.myStatus;

    if (myStatus == null || !myStatus.hasActiveResignation) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ResignationListBloc>().add(
                const ResignationListMyStatusRequested(isRefresh: true),
              );
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ResignationEmptyStateCard(
              onCreatePressed: _handleCreateResignation,
            ),
          ],
        ),
      );
    }

    final resignation = myStatus.resignation;
    if (resignation == null) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ResignationListBloc>().add(
                const ResignationListMyStatusRequested(isRefresh: true),
              );
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ResignationEmptyStateCard(
              onCreatePressed: _handleCreateResignation,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ResignationListBloc>().add(
              const ResignationListMyStatusRequested(isRefresh: true),
            );
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        children: [
          // 1. Notice Period Countdown Card
          ResignationCountdownCard(
            resignation: resignation,
            daysRemaining: myStatus.daysRemaining,
          ),
          const SizedBox(height: 14),

          // 2. Tahapan Proses Resign (5-Stage Visual Stepper)
          ResignationStepperCard(resignation: resignation),
          const SizedBox(height: 14),

          // 3. Diagnosa Live Clearance 4 Pos
          ResignationClearanceSnapshotCard(resignation: resignation),
          const SizedBox(height: 20),

          // 4. Action Buttons
          if (myStatus.canSubmitExitInterview) ...[
            AppButton(
              text: 'Isi Kuesioner Exit Interview',
              leadingIcon: LucideIcons.fileSpreadsheet,
              variant: AppButtonVariant.primary,
              height: 48,
              onPressed: _handleExitInterview,
            ),
            const SizedBox(height: 10),
          ],

          AppButton(
            text: 'Lihat Detail Berkas & Timeline',
            leadingIcon: LucideIcons.folderOpen,
            variant: AppButtonVariant.outlined,
            height: 48,
            onPressed: _handleViewDetail,
          ),

          if (myStatus.canCancel) ...[
            const SizedBox(height: 10),
            AppButton(
              text: 'Batalkan Pengajuan',
              leadingIcon: LucideIcons.xCircle,
              variant: AppButtonVariant.danger,
              isLoading: state.isCancelling,
              height: 48,
              onPressed: _handleCancelMyResignation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamApprovalsTab({
    required BuildContext context,
    required ResignationListState state,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required Color surfaceCol,
    required Color borderCol,
    required Color brandCol,
  }) {
    return Column(
      children: [
        // Filter Chips Row: Menunggu (pending), Riwayat (history), Semua (all)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Menunggu',
                statusKey: 'pending',
                currentStatus: state.subordinatesStatusFilter,
                brandCol: brandCol,
                surfaceCol: surfaceCol,
                borderCol: borderCol,
                textCol: textCol,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Riwayat',
                statusKey: 'history',
                currentStatus: state.subordinatesStatusFilter,
                brandCol: brandCol,
                surfaceCol: surfaceCol,
                borderCol: borderCol,
                textCol: textCol,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Semua',
                statusKey: 'all',
                currentStatus: state.subordinatesStatusFilter,
                brandCol: brandCol,
                surfaceCol: surfaceCol,
                borderCol: borderCol,
                textCol: textCol,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ResignationListBloc>().add(
                    const ResignationListSubordinatesRequested(
                      isRefresh: true,
                    ),
                  );
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: _buildSubordinatesList(
              context: context,
              state: state,
              isDark: isDark,
              textCol: textCol,
              subtitleCol: subtitleCol,
              surfaceCol: surfaceCol,
              borderCol: borderCol,
              brandCol: brandCol,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String statusKey,
    required String currentStatus,
    required Color brandCol,
    required Color surfaceCol,
    required Color borderCol,
    required Color textCol,
    required bool isDark,
  }) {
    final isSelected = currentStatus == statusKey;

    return InkWell(
      onTap: () {
        context.read<ResignationListBloc>().add(
              ResignationListSubordinatesRequested(
                statusFilter: statusKey,
              ),
            );
      },
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1))
              : surfaceCol,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? brandCol : borderCol,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E))
                : textCol,
          ),
        ),
      ),
    );
  }

  Widget _buildSubordinatesList({
    required BuildContext context,
    required ResignationListState state,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required Color surfaceCol,
    required Color borderCol,
    required Color brandCol,
  }) {
    if (state.isSubordinatesLoading && state.subordinates.isEmpty) {
      return const RequestCardShimmerLoading(itemCount: 4);
    }

    if (state.subordinates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 28,
                  color: subtitleCol,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tidak Ada Pengajuan Bawahan',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Belum ada anggota tim yang mengajukan permohonan resign.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _teamScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount:
          state.subordinates.length + (state.isSubordinatesLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == state.subordinates.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final item = state.subordinates[index];
        return SubordinateResignationCard(
          item: item,
          onReviewPressed: () => _handleReviewSubordinate(item.id),
          onDetailPressed: _handleViewDetail,
        );
      },
    );
  }
}
