import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_forbidden_state.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_event.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/create_activity_option_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';

/// Halaman Daftar Aktivitas (Activity Reports / Team Activity Feed) sesuai Clean Architecture & BLoC.
/// State bisnis (pemuatan data, filtering, tabs, infinite scroll, 403 error) dikelola oleh [ActivityListBloc].
class ActivityScreen extends StatelessWidget {
  final List<ActivityItem>? customActivities;
  final ActivityRepository? activityRepository;
  final ActivityListBloc? activityListBloc;

  const ActivityScreen({
    super.key,
    this.customActivities,
    this.activityRepository,
    this.activityListBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (activityListBloc != null) {
      return BlocProvider<ActivityListBloc>.value(
        value: activityListBloc!,
        child: _ActivityScreenView(customActivities: customActivities),
      );
    }
    return BlocProvider<ActivityListBloc>(
      create: (context) =>
          ActivityListBloc(repository: activityRepository)
            ..add(ActivityListStarted(customActivities: customActivities)),
      child: _ActivityScreenView(customActivities: customActivities),
    );
  }
}

class _ActivityScreenView extends StatefulWidget {
  final List<ActivityItem>? customActivities;

  const _ActivityScreenView({this.customActivities});

  @override
  State<_ActivityScreenView> createState() => _ActivityScreenViewState();
}

class _ActivityScreenViewState extends State<_ActivityScreenView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  /// Tab tim disembunyikan bila user tidak berwenang (tanpa memuat data tim).
  late final bool _canViewTeam = SecureStorageService.instance
      .hasAnyPermissionInMemory(AppPermissions.teamActivity);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _canViewTeam ? 2 : 1, vsync: this, initialIndex: 0);
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
      setState(() {
        _isSearchVisible = true;
      });
      context.read<ActivityListBloc>().add(
        ActivityListTabChanged(_tabController.index),
      );
    }
  }

  void _onMyScroll() {
    if (_myScrollController.hasClients &&
        _myScrollController.position.pixels >=
            _myScrollController.position.maxScrollExtent - 250) {
      context.read<ActivityListBloc>().add(
        const ActivityListLoadMoreRequested(isTeam: false),
      );
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 250) {
      context.read<ActivityListBloc>().add(
        const ActivityListLoadMoreRequested(isTeam: true),
      );
    }
  }

  void _onSearchChanged(String val) {
    if (widget.customActivities != null) {
      context.read<ActivityListBloc>().add(ActivityListSearchChanged(val));
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        context.read<ActivityListBloc>().add(ActivityListSearchChanged(val));
      });
    }
  }

  Future<void> _handleRefresh() async {
    final isTeam = _tabController.index == 1;
    context.read<ActivityListBloc>().add(
      ActivityListFetchRequested(isRefresh: true, isTeam: isTeam),
    );
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _loadMyActivities({required int page, bool isRefresh = false}) {
    context.read<ActivityListBloc>().add(
      ActivityListFetchRequested(isRefresh: isRefresh, isTeam: false),
    );
  }

  void _loadTeamActivities({required int page, bool isRefresh = false}) {
    context.read<ActivityListBloc>().add(
      ActivityListFetchRequested(isRefresh: isRefresh, isTeam: true),
    );
  }

  Future<void> _handleCreateActivity() async {
    final listState = context.read<ActivityListBloc>().state;
    final hasManageAuth = listState.hasManagePermission;

    if (GoRouter.maybeOf(context) != null) {
      String routeToPush = Routes.CREATE_ACTIVITY;

      // Jika memiliki hak otorisasi activity.manage, tampilkan Bottom Sheet pilihan target
      if (hasManageAuth) {
        final target = await showCreateActivityOptionBottomSheet(context);
        if (target == null || !mounted) return;
        if (target == CreateActivityTarget.subordinate) {
          routeToPush = Routes.CREATE_ACTIVITY_PLAN;
        } else {
          routeToPush = Routes.CREATE_ACTIVITY;
        }
      }

      final newActivity = await context.push<ActivityItem>(routeToPush);
      if (!mounted) return;
      if (newActivity != null) {
        _loadMyActivities(page: 1, isRefresh: true);
        _loadTeamActivities(page: 1, isRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aktivitas "${newActivity.title}" berhasil dibuat!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.brandTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openFilterBottomSheet() async {
    final bloc = context.read<ActivityListBloc>();
    final result = await showActivityFilterBottomSheet(
      context,
      initialCriteria: bloc.state.filterCriteria,
    );
    if (result != null && mounted) {
      bloc.add(ActivityListFilterApplied(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ActivityListBloc>().state;
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
      // 1. TopAppBar (Transactional - Only Filter Icon on trailing action)
      appBar: AppBar(
        backgroundColor: bgCol.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
              AppLocalizations.of(context)?.titleActivityReports ?? 'Laporan Aktivitas',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                height: 1.15,
              ),
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
          key: const ValueKey('add_activity_fab'),
          onPressed: _handleCreateActivity,
          backgroundColor: brandColor,
          foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
          elevation: 3,
          shape: const StadiumBorder(),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(
            'Tambah Aktivitas',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkOnPrimary : Colors.white,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 3. TabBar (My Activities & Team Activities)
            if (_canViewTeam)
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
                  onTap: (index) {
                    setState(() {
                      _isSearchVisible = true;
                    });
                  },
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
                          const Icon(LucideIcons.clipboardList, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.tabSelf ?? 'Saya',
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
                              l10n?.tabMyTeam ?? 'Tim Saya',
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

            // 4. Dynamic Hide/Show Search Bar on Scroll (hanya aktif pada tab Team / index 1)
            Builder(
              builder: (context) {
                final isTeamTab = _tabController.index == 1;
                final showSearchBar = isTeamTab && _isSearchVisible;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: showSearchBar ? 58 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(color: bgCol),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showSearchBar ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !showSearchBar,
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
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Cari nama pegawai atau kata kunci...',
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
                );
              },
            ),

            // 5. TabBarView for Content (Left: My Activities, Right: Team Activities)
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_tabController.index == 1 &&
                      notification is ScrollUpdateNotification &&
                      notification.metrics.axis == Axis.vertical) {
                    final delta = notification.scrollDelta ?? 0;

                    // Jika berada di dekat batas atas, selalu tampilkan search bar
                    if (notification.metrics.pixels <= 10) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                    // Saat scroll ke atas -> sembunyikan search bar
                    else if (delta > 3) {
                      if (_isSearchVisible) {
                        setState(() => _isSearchVisible = false);
                      }
                    }
                    // Saat scroll ke bawah -> tampilkan search bar
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
                    _buildMyActivitiesTab(
                      isDark: isDark,
                      surfaceCol: surfaceCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      borderCol: borderCol,
                      brandColor: brandColor,
                    ),
                    if (_canViewTeam)
                    _buildTeamActivitiesTab(
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

  /// Tampilan Tab 0: Aktivitasku
  Widget _buildMyActivitiesTab({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    final state = context.watch<ActivityListBloc>().state;
    final filteredList = state.myActivities;
    final isMyLoading = state.isMyLoading;
    final isMyLoadingMore = state.isMyLoadingMore;
    final myActivities = state.myActivities;
    final filterCriteria = state.filterCriteria;
    final searchQuery = state.searchQuery;

    if (isMyLoading && myActivities.isEmpty) {
      return const RequestCardShimmerLoading();
    }

    if (filteredList.isEmpty) {
      final isFiltered =
          filterCriteria.hasActiveFilter || searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: brandColor,
        child: AppEmptyState(
          icon: LucideIcons.clipboardList,
          title: isFiltered
              ? 'Tidak Ada Aktivitas Ditemukan'
              : 'Belum Ada Aktivitas Saya',
          message: isFiltered
              ? 'Tidak ada aktivitas Anda yang sesuai dengan kata kunci pencarian atau filter yang dipilih.'
              : 'Catat progres atau laporan pekerjaan harian Anda menggunakan tombol di bawah.',
          onResetFilter: isFiltered
              ? () {
                  _searchController.clear();
                  context.read<ActivityListBloc>().add(
                    const ActivityListSearchChanged(''),
                  );
                  context.read<ActivityListBloc>().add(
                    const ActivityListFilterApplied(
                      ActivityFilterCriteria(),
                    ),
                  );
                }
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.builder(
        controller: _myScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: filteredList.length + (isMyLoadingMore ? 2 : 1),
        itemBuilder: (context, index) {
          if (index < filteredList.length) {
            final item = filteredList[index];
            return ActivityCard(
              activity: item,
              onTap: () async {
                final result = await context.push(
                  Routes.ACTIVITY_DETAIL,
                  extra: item,
                );
                if (result == true && mounted) {
                  _loadMyActivities(page: 1, isRefresh: true);
                }
              },
            );
          }
          if (isMyLoadingMore && index == filteredList.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: AppLoadingIndicator.small(color: brandColor),
              ),
            );
          }
          return const SizedBox(height: 16);
        },
      ),
    );
  }

  /// Tampilan Tab 1: Aktivitas Pegawai Lain (dengan penanganan error 403 Forbidden)
  Widget _buildTeamActivitiesTab({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    final state = context.watch<ActivityListBloc>().state;
    final filteredList = state.teamActivities;
    final isTeamLoading = state.isTeamLoading;
    final isTeamLoadingMore = state.isTeamLoadingMore;
    final isTeamForbidden = state.isTeamForbidden;
    final teamActivities = state.teamActivities;
    final filterCriteria = state.filterCriteria;
    final searchQuery = state.searchQuery;

    // 1. Penanganan Khusus HTTP 403 Forbidden
    if (isTeamForbidden) {
      return RefreshIndicator(
        onRefresh: () async => _loadTeamActivities(page: 1, isRefresh: true),
        color: brandColor,
        child: AppForbiddenState(
          message:
              'Anda tidak memiliki hak akses pada pegawai! Fitur ini khusus untuk akun dengan otoritas Approver atau Supervisor.',
          onRetry: () => _loadTeamActivities(page: 1, isRefresh: true),
          actionText: 'Aktivitasku',
          onAction: () => _tabController.animateTo(0),
        ),
      );
    }

    // 2. Loading Awal / Refresh
    if (isTeamLoading && teamActivities.isEmpty) {
      return const RequestCardShimmerLoading();
    }

    // 3. Status Kosong (Empty State)
    if (filteredList.isEmpty) {
      final isFiltered =
          filterCriteria.hasActiveFilter || searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: brandColor,
        child: AppEmptyState(
          icon: LucideIcons.usersRound,
          title: isFiltered
              ? 'Tidak Ada Aktivitas Ditemukan'
              : 'Belum Ada Aktivitas Pegawai Lain',
          message: isFiltered
              ? 'Tidak ada aktivitas pegawai lain yang cocok dengan kata kunci atau kriteria filter.'
              : 'Saat ini belum ada log aktivitas yang dikirimkan oleh rekan kerja Anda.',
          onResetFilter: isFiltered
              ? () {
                  _searchController.clear();
                  context.read<ActivityListBloc>().add(
                    const ActivityListSearchChanged(''),
                  );
                  context.read<ActivityListBloc>().add(
                    const ActivityListFilterApplied(
                      ActivityFilterCriteria(),
                    ),
                  );
                }
              : null,
        ),
      );
    }

    // 4. Daftar Kartu Aktivitas Tim dengan Infinite Scroll
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.builder(
        controller: _teamScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: filteredList.length + (isTeamLoadingMore ? 2 : 1),
        itemBuilder: (context, index) {
          if (index < filteredList.length) {
            final item = filteredList[index];
            return ActivityCard(
              activity: item,
              onTap: () async {
                final result = await context.push(
                  Routes.ACTIVITY_DETAIL,
                  extra: item,
                );
                if (result == true && mounted) {
                  _loadTeamActivities(page: 1, isRefresh: true);
                }
              },
            );
          }
          if (isTeamLoadingMore && index == filteredList.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: AppLoadingIndicator.small(color: brandColor),
              ),
            );
          }
          return const SizedBox(height: 16);
        },
      ),
    );
  }
}
