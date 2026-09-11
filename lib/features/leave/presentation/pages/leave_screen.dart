import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_bloc.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_event.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_request_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman "Leave & Time Off" — slice dari desain Stitch
/// (screen "Oasish Team Leave Requests - List View", project
/// "Oasish Flutter M3 HRIS").
///
/// Integrasi API `GET /leave-request` via [LeaveListBloc]:
///  - Tab "My Requests" -> `approver=false`.
///  - Tab "Team Requests" -> `approver=true`, lazy load, dengan penanganan
///    khusus HTTP 403 (state "Tidak Memiliki Hak Akses").
///  - Search bar dinamis di bawah TabBar: sembunyi saat scroll ke atas,
///    muncul saat scroll ke bawah / di puncak list (pola ActivityScreen).
///  - Tanpa chip filter horizontal — filter diakses lewat tombol di AppBar.
class LeaveScreen extends StatelessWidget {
  /// Opsional: repository kustom (untuk testing / DI).
  final LeaveRepository? leaveRepository;

  /// Opsional: bloc kustom (untuk testing / reuse).
  final LeaveListBloc? leaveListBloc;

  const LeaveScreen({super.key, this.leaveRepository, this.leaveListBloc});

  @override
  Widget build(BuildContext context) {
    if (leaveListBloc != null) {
      return BlocProvider<LeaveListBloc>.value(
        value: leaveListBloc!,
        child: const _LeaveScreenView(),
      );
    }
    return BlocProvider<LeaveListBloc>(
      create: (context) =>
          LeaveListBloc(repository: leaveRepository)
            ..add(const LeaveListStarted()),
      child: const _LeaveScreenView(),
    );
  }
}

class _LeaveScreenView extends StatefulWidget {
  const _LeaveScreenView();

  @override
  State<_LeaveScreenView> createState() => _LeaveScreenViewState();
}

class _LeaveScreenViewState extends State<_LeaveScreenView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearchVisible = true;

  /// Desain Stitch: tab aktif awal = "Team Requests" (index 1).
  static const int _initialTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _initialTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _myScrollController.addListener(_onMyScroll);
    _teamScrollController.addListener(_onTeamScroll);

    // Selaraskan tab awal dengan state BLoC + lazy load tab Team.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LeaveListBloc>().add(
        const LeaveListTabChanged(_initialTabIndex),
      );
    });
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
      setState(() {});
      context.read<LeaveListBloc>().add(
        LeaveListTabChanged(_tabController.index),
      );
    }
  }

  // ── Infinite scroll (pola ActivityScreen) ───────────────────────────
  void _onMyScroll() {
    if (_myScrollController.hasClients &&
        _myScrollController.position.pixels >=
            _myScrollController.position.maxScrollExtent - 250) {
      context.read<LeaveListBloc>().add(
        const LeaveListLoadMoreRequested(isTeam: false),
      );
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 250) {
      context.read<LeaveListBloc>().add(
        const LeaveListLoadMoreRequested(isTeam: true),
      );
    }
  }

  // ── Search dengan debounce 300ms ────────────────────────────────────
  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<LeaveListBloc>().add(LeaveListSearchChanged(val));
    });
  }

  Future<void> _handleRefresh() async {
    final isTeam = _tabController.index == 1;
    context.read<LeaveListBloc>().add(
      LeaveListFetchRequested(isRefresh: true, isTeam: isTeam),
    );
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _openFilterBottomSheet() async {
    final bloc = context.read<LeaveListBloc>();
    final result = await showLeaveFilterBottomSheet(
      context,
      initialCriteria: bloc.state.filterCriteria,
    );
    if (result != null && mounted) {
      bloc.add(LeaveListFilterApplied(result));
    }
  }

  Future<void> _handleCreateLeave() async {
    final result = await context.pushNamed<bool>(Routes.CREATE_LEAVE);
    if (result == true && mounted) {
      context.read<LeaveListBloc>().add(
            const LeaveListFetchRequested(isRefresh: true, isTeam: false),
          );
    }
  }

  Future<void> _navigateToDetail(
    LeaveRequestItem item, {
    required bool isApprover,
  }) async {
    final result = await context.pushNamed<bool>(
      Routes.LEAVE_DETAIL,
      extra: {
        'id': item.id,
        'isApprover': isApprover,
      },
    );
    if (result == true && mounted) {
      context.read<LeaveListBloc>().add(
            LeaveListFetchRequested(
              isRefresh: true,
              isTeam: isApprover,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LeaveListBloc>().state;
    final filterCriteria = state.filterCriteria;
    final searchQuery = state.searchQuery;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundSubtle;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Scaffold(
      backgroundColor: bgCol,
      // ── 1. Top App Bar (judul + tombol filter) ────────────────────────
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
              'Leave & Time Off',
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
              'Team approvals & time-off management',
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
                  color: filterCriteria.hasActiveFilter ? brandColor : textCol,
                  size: 20,
                ),
                if (filterCriteria.hasActiveFilter)
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
          ),
        ],
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
          key: const ValueKey('add_leave_fab'),
          onPressed: _handleCreateLeave,
          backgroundColor: brandColor,
          foregroundColor: isDark ? const Color(0xFF003732) : Colors.white,
          elevation: 3,
          shape: const StadiumBorder(),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(
            'Tambah Izin',
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
            // ── 2. Tab Bar (My Requests & Team Requests) ────────────────
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
                  tabs: const [
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.calendarClock, size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'My Requests',
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
                              'Team Requests',
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

            // ── 3. Dynamic Hide/Show Search Bar on Scroll ───────────────
            // (persis seperti ActivityScreen / Employee Directory)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isSearchVisible ? 58 : 0,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(color: bgCol),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isSearchVisible ? 1.0 : 0.0,
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
                      style: AppTypography.bodyMedium.copyWith(
                        color: textCol,
                        fontSize: 14,
                      ),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by employee name or keyword...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: subtitleCol,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          size: 18,
                          color: subtitleCol,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: subtitleCol,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── 4. TabBarView (My Requests / Team Requests) ─────────────
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.metrics.axis == Axis.vertical) {
                    final delta = notification.scrollDelta ?? 0;

                    // Di dekat batas atas -> selalu tampilkan search bar.
                    if (notification.metrics.pixels <= 10) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                    // Scroll ke atas -> sembunyikan search bar.
                    else if (delta > 3) {
                      if (_isSearchVisible) {
                        setState(() => _isSearchVisible = false);
                      }
                    }
                    // Scroll ke bawah -> tampilkan search bar.
                    else if (delta < -3) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                  }
                  return false;
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyRequestsTab(
                      isDark: isDark,
                      surfaceCol: surfaceCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      borderCol: borderCol,
                      brandColor: brandColor,
                    ),
                    _buildTeamRequestsTab(
                      isDark: isDark,
                      surfaceCol: surfaceCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      borderCol: borderCol,
                      brandColor: brandColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tampilan Tab 0: My Requests ───────────────────────────────────────
  Widget _buildMyRequestsTab({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    final state = context.watch<LeaveListBloc>().state;
    final requests = state.myRequests;
    final isLoading = state.isMyLoading;
    final isLoadingMore = state.isMyLoadingMore;
    final filterCriteria = state.filterCriteria;
    final searchQuery = state.searchQuery;

    // 1. Loading awal / refresh
    if (isLoading && requests.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(brandColor),
        ),
      );
    }

    // 2. Empty state
    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.calendarX,
        title: filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
            ? 'Tidak Ada Pengajuan Ditemukan'
            : 'Belum Ada Pengajuan Cuti',
        message: filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
            ? 'Tidak ada pengajuan cuti/izin yang cocok dengan kata kunci atau kriteria filter.'
            : 'Anda belum memiliki pengajuan cuti/izin. Nikmati keseimbangan kerja Anda!',
        hasActiveFilter:
            filterCriteria.hasActiveFilter || searchQuery.isNotEmpty,
        textCol: textCol,
        subtitleCol: subtitleCol,
        brandColor: brandColor,
      );
    }

    // 3. List + infinite scroll + pull to refresh
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.separated(
        controller: _myScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: requests.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i >= requests.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  ),
                ),
              ),
            );
          }
          return LeaveRequestCard(
            item: requests[i],
            onViewDetails: () =>
                _navigateToDetail(requests[i], isApprover: false),
          );
        },
      ),
    );
  }

  // ── Tampilan Tab 1: Team Requests (dengan penanganan 403 Forbidden) ───
  Widget _buildTeamRequestsTab({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    final state = context.watch<LeaveListBloc>().state;
    final requests = state.teamRequests;
    final isLoading = state.isTeamLoading;
    final isLoadingMore = state.isTeamLoadingMore;
    final isForbidden = state.isTeamForbidden;
    final filterCriteria = state.filterCriteria;
    final searchQuery = state.searchQuery;

    // 1. Penanganan khusus HTTP 403 Forbidden (bukan approver)
    if (isForbidden) {
      return _buildForbiddenState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        borderCol: borderCol,
        brandColor: brandColor,
      );
    }

    // 2. Loading awal / refresh
    if (isLoading && requests.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(brandColor),
        ),
      );
    }

    // 3. Empty state
    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.users,
        title: filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
            ? 'Tidak Ada Pengajuan Ditemukan'
            : 'Belum Ada Pengajuan Tim',
        message: filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
            ? 'Tidak ada pengajuan cuti/izin pegawai yang cocok dengan kata kunci atau kriteria filter.'
            : 'Saat ini belum ada pengajuan cuti/izin yang dikirimkan oleh rekan tim Anda.',
        hasActiveFilter:
            filterCriteria.hasActiveFilter || searchQuery.isNotEmpty,
        textCol: textCol,
        subtitleCol: subtitleCol,
        brandColor: brandColor,
      );
    }

    // 4. List + infinite scroll + pull to refresh
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.separated(
        controller: _teamScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: requests.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i >= requests.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  ),
                ),
              ),
            );
          }
          return LeaveRequestCard(
            item: requests[i],
            onViewDetails: () =>
                _navigateToDetail(requests[i], isApprover: true),
          );
        },
      ),
    );
  }

  // ── Empty state (dipakai kedua tab) ───────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required bool hasActiveFilter,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: brandColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<LeaveListBloc>().add(
                        const LeaveListSearchChanged(''),
                      );
                      context.read<LeaveListBloc>().add(
                        const LeaveListFilterReset(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandColor,
                      side: BorderSide(color: brandColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.rotateCcw,
                          size: 14,
                          color: brandColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reset Filter & Pencarian',
                          style: AppTypography.bodySmall.copyWith(
                            color: brandColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Forbidden state (403, khusus tab Team Requests) ───────────────────
  Widget _buildForbiddenState({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<LeaveListBloc>().add(
          const LeaveListFetchRequested(isRefresh: true, isTeam: true),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceCol,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.shieldAlert,
                      color: Color(0xFFD97706),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tidak Memiliki Hak Akses',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda tidak memiliki otoritas sebagai approver untuk melihat pengajuan cuti tim. Fitur ini khusus untuk akun dengan otoritas Approver atau Supervisor.',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          context.read<LeaveListBloc>().add(
                            const LeaveListFetchRequested(
                              isRefresh: true,
                              isTeam: true,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textCol,
                          side: BorderSide(color: borderCol),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          alignment: Alignment.center,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.rotateCcw,
                              size: 14,
                              color: textCol,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Coba Lagi',
                              style: AppTypography.bodySmall.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                leadingDistribution:
                                    TextLeadingDistribution.even,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          _tabController.animateTo(0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: isDark
                              ? const Color(0xFF003732)
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendarClock,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF003732)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ke Pengajuan Saya',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? const Color(0xFF003732)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                leadingDistribution:
                                    TextLeadingDistribution.even,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
