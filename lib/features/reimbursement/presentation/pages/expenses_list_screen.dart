import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_state.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/expense_request_card.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/expenses_filter_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman utama daftar pengeluaran (Klaim Reimbursement & Kasbon).
///
/// Menyediakan:
/// - Tab 0: "Pengajuan Saya" (`approver=false`)
/// - Tab 1: "Bawahan" (`approver=true`) dengan proteksi hak akses 403.
/// - Filter cepat tipe pengeluaran: Semua, Reimbursement, Kasbon.
/// - Pencarian debounced & filter lanjutan (tanggal, status, organisasi).
/// - Quick Action FAB untuk membuat Reimbursement atau Kasbon baru.
class ExpensesListScreen extends StatelessWidget {
  final ReimbursementRepository? repository;
  final ExpensesListBloc? bloc;

  const ExpensesListScreen({super.key, this.repository, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<ExpensesListBloc>.value(
        value: bloc!,
        child: const _ExpensesListView(),
      );
    }
    return BlocProvider<ExpensesListBloc>(
      create: (context) =>
          ExpensesListBloc(repository: repository)
            ..add(const ExpensesListStarted()),
      child: const _ExpensesListView(),
    );
  }
}

class _ExpensesListView extends StatefulWidget {
  const _ExpensesListView();

  @override
  State<_ExpensesListView> createState() => _ExpensesListViewState();
}

class _ExpensesListViewState extends State<_ExpensesListView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _myScrollController.removeListener(_onMyScroll);
    _myScrollController.dispose();
    _teamScrollController.removeListener(_onTeamScroll);
    _teamScrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<ExpensesListBloc>().add(
        ExpensesListTabChanged(_tabController.index),
      );
    }
  }

  void _onMyScroll() {
    if (_myScrollController.position.pixels >=
        _myScrollController.position.maxScrollExtent - 200) {
      context.read<ExpensesListBloc>().add(
        const ExpensesListLoadMoreRequested(isTeam: false),
      );
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.position.pixels >=
        _teamScrollController.position.maxScrollExtent - 200) {
      context.read<ExpensesListBloc>().add(
        const ExpensesListLoadMoreRequested(isTeam: true),
      );
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<ExpensesListBloc>().add(
          ExpensesListSearchChanged(val.trim()),
        );
      }
    });
  }

  void _openFilter(ExpensesListState state) async {
    final result = await showExpensesFilterBottomSheet(
      context,
      title: 'Filter Klaim & Kasbon',
      initialData: state.filterCriteria,
    );

    if (result != null && mounted) {
      context.read<ExpensesListBloc>().add(ExpensesListFilterApplied(result));
    }
  }

  void _showCreateActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: surfaceCol,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Pengajuan Baru',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih jenis pengajuan pengeluaran yang ingin Anda buat',
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              _buildCreateOptionTile(
                icon: LucideIcons.receiptText,
                iconBg: const Color(0xFF0D9488).withValues(alpha: 0.12),
                iconColor: const Color(0xFF0D9488),
                title: 'Ajukan Reimbursement',
                subtitle:
                    'Klaim penggantian dana operasional pribadi atau penyelesaian nota kasbon',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final res = await context.push<bool>(
                    Routes.CREATE_REIMBURSEMENT,
                  );
                  if (res == true && mounted) {
                    context.read<ExpensesListBloc>().add(
                      const ExpensesListFetchRequested(
                        isRefresh: true,
                        isTeam: false,
                      ),
                    );
                  }
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildCreateOptionTile(
                icon: LucideIcons.handCoins,
                iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                iconColor: const Color(0xFF3B82F6),
                title: 'Ajukan Kasbon (Cash Advance)',
                subtitle:
                    'Permohonan dana di muka untuk keperluan perjalanan dinas atau operasional',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final res = await context.push<bool>(
                    Routes.CREATE_CASH_ADVANCE,
                  );
                  if (res == true && mounted) {
                    context.read<ExpensesListBloc>().add(
                      const ExpensesListFetchRequested(
                        isRefresh: true,
                        isTeam: false,
                      ),
                    );
                  }
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOptionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textCol,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: subtitleCol),
          ],
        ),
      ),
    );
  }

  void _onCardTap(ExpenseFeedItemModel item) async {
    final route = item.isReimbursement
        ? Routes.REIMBURSEMENT_DETAIL
        : Routes.CASH_ADVANCE_DETAIL;

    final res = await context.push<bool>(route, extra: item.id);
    if (res == true && mounted) {
      final isTeam = _tabController.index == 1;
      context.read<ExpensesListBloc>().add(
        ExpensesListFetchRequested(isRefresh: true, isTeam: isTeam),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.background;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Klaim & Kasbon',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: textCol,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: scaffoldBg,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<ExpensesListBloc, ExpensesListState>(
            buildWhen: (prev, curr) =>
                prev.filterCriteria != curr.filterCriteria,
            builder: (context, state) {
              final hasFilter = state.filterCriteria.hasActiveFilter;
              final filterCount = state.filterCriteria.activeFilterCount;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.slidersHorizontal,
                      color: hasFilter ? brandColor : textCol,
                    ),
                    onPressed: () => _openFilter(state),
                  ),
                  if (hasFilter)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: brandColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$filterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLowest
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
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
                unselectedLabelColor: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.receipt, size: 16),
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
                    height: 40,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // 2. Floating Action Button: Hanya tampil pada tab "My Activities" (Tab 0)
      floatingActionButton: AnimatedBuilder(
        animation: _tabController.animation ?? _tabController,
        builder: (context, child) {
          final animVal =
              _tabController.animation?.value ??
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
          key: const ValueKey('add_reimbursement_fab'),
          onPressed: _showCreateActionSheet,
          backgroundColor: brandColor,
          foregroundColor: isDark ? const Color(0xFF003732) : Colors.white,
          elevation: 3,
          shape: const StadiumBorder(),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(
            'Ajukan',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF003732) : Colors.white,
            ),
          ),
        ),
      ),
      body: BlocConsumer<ExpensesListBloc, ExpensesListState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search Bar & Filter Chips Header
              _buildTopHeader(state, isDark, brandColor),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Pengajuan Saya
                    _buildMyExpensesTab(state, isDark, brandColor),

                    // Tab 1: Bawahan
                    _buildTeamExpensesTab(state, isDark, brandColor),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(
    ExpensesListState state,
    bool isDark,
    Color brandColor,
  ) {
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final bgCol = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final hintCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: borderCol, width: 1)),
      ),
      child: Column(
        children: [
          // Search Input
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: TextStyle(color: textCol, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Cari nomor klaim, keperluan, atau staf...',
                hintStyle: TextStyle(color: hintCol, fontSize: 13),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: hintCol),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(LucideIcons.x, size: 16, color: hintCol),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Filter Chips (Tipe: Semua, Reimbursement, Kasbon)
          Row(
            children: [
              _buildTypeFilterChip(
                label: 'Semua',
                value: 'all',
                isSelected: state.currentTypeFilter == 'all',
                isDark: isDark,
                brandColor: brandColor,
              ),
              const SizedBox(width: 8),
              _buildTypeFilterChip(
                label: 'Reimbursement',
                value: 'reimbursement',
                isSelected: state.currentTypeFilter == 'reimbursement',
                isDark: isDark,
                brandColor: brandColor,
              ),
              const SizedBox(width: 8),
              _buildTypeFilterChip(
                label: 'Kasbon',
                value: 'cash_advance',
                isSelected: state.currentTypeFilter == 'cash_advance',
                isDark: isDark,
                brandColor: brandColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    required bool isDark,
    required Color brandColor,
  }) {
    final chipBg = isSelected
        ? (isDark
              ? brandColor.withValues(alpha: 0.18)
              : const Color(0xFFF0FDFA))
        : (isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.backgroundSubtle);
    final borderCol = isSelected
        ? brandColor
        : (isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted);
    final textCol = isSelected
        ? (isDark ? brandColor : const Color(0xFF0D9488))
        : (isDark
              ? AppColors.darkOnSurfaceVariant
              : AppColors.onSurfaceVariant);

    return InkWell(
      onTap: () {
        context.read<ExpensesListBloc>().add(
          ExpensesListTypeFilterChanged(value),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderCol, width: isSelected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textCol,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMyExpensesTab(
    ExpensesListState state,
    bool isDark,
    Color brandColor,
  ) {
    if (state.isMyLoading && state.myExpenses.isEmpty) {
      return const RequestCardShimmerLoading(itemCount: 4);
    }

    if (state.myExpenses.isEmpty) {
      return _buildEmptyState(
        title: 'Belum Ada Pengajuan',
        description:
            'Anda belum memiliki pengajuan klaim reimbursement atau kasbon.',
        actionLabel: 'Buat Pengajuan',
        onAction: _showCreateActionSheet,
        isDark: isDark,
        brandColor: brandColor,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ExpensesListBloc>().add(
          const ExpensesListFetchRequested(isRefresh: true, isTeam: false),
        );
      },
      color: brandColor,
      child: ListView.separated(
        controller: _myScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: state.myExpenses.length + (state.isMyLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == state.myExpenses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final item = state.myExpenses[index];
          return ExpenseRequestCard(
            item: item,
            isTeam: false,
            onTap: () => _onCardTap(item),
          );
        },
      ),
    );
  }

  Widget _buildTeamExpensesTab(
    ExpensesListState state,
    bool isDark,
    Color brandColor,
  ) {
    if (state.isTeamForbidden) {
      return _buildForbiddenState(isDark);
    }

    if (state.isTeamLoading && state.teamExpenses.isEmpty) {
      return const RequestCardShimmerLoading(itemCount: 4);
    }

    if (state.teamExpenses.isEmpty) {
      return _buildEmptyState(
        title: 'Belum Ada Pengajuan Tim',
        description:
            'Tidak ada pengajuan reimbursement atau kasbon dari bawahan yang perlu diproses.',
        isDark: isDark,
        brandColor: brandColor,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ExpensesListBloc>().add(
          const ExpensesListFetchRequested(isRefresh: true, isTeam: true),
        );
      },
      color: brandColor,
      child: ListView.separated(
        controller: _teamScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount:
            state.teamExpenses.length + (state.isTeamLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == state.teamExpenses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final item = state.teamExpenses[index];
          return ExpenseRequestCard(
            item: item,
            isTeam: true,
            onTap: () => _onCardTap(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
    required bool isDark,
    required Color brandColor,
  }) {
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.receiptText, size: 48, color: brandColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForbiddenState(bool isDark) {
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldAlert,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tidak Memiliki Hak Akses',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda bukan approver atau tidak memiliki bawahan langsung untuk melihat daftar pengajuan tim.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
