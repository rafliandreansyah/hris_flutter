import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_event.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      create: (context) => ActivityListBloc(
        repository: activityRepository,
      )..add(ActivityListStarted(customActivities: customActivities)),
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
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
      context
          .read<ActivityListBloc>()
          .add(ActivityListTabChanged(_tabController.index));
    }
  }

  void _onMyScroll() {
    if (_myScrollController.hasClients &&
        _myScrollController.position.pixels >=
            _myScrollController.position.maxScrollExtent - 250) {
      context
          .read<ActivityListBloc>()
          .add(const ActivityListLoadMoreRequested(isTeam: false));
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 250) {
      context
          .read<ActivityListBloc>()
          .add(const ActivityListLoadMoreRequested(isTeam: true));
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
    if (GoRouter.maybeOf(context) != null) {
      final newActivity =
          await context.push<ActivityItem>(Routes.CREATE_ACTIVITY);
      if (!mounted) return;
      if (newActivity != null) {
        context
            .read<ActivityListBloc>()
            .add(ActivityListActivityAdded(newActivity));
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
    } else {
      _showAddActivityBottomSheet();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Reports',
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
              'Track work logs & operational tasks',
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
          key: const ValueKey('add_activity_fab'),
          onPressed: _handleCreateActivity,
          backgroundColor: brandColor,
          foregroundColor: isDark ? const Color(0xFF003732) : Colors.white,
          elevation: 3,
          shape: const StadiumBorder(),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(
            'Tambah Aktivitas',
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
            // 3. TabBar (My Activities & Team Activities)
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
                  tabs: const [
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clipboardList, size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'My Activities',
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
                              'Team Activities',
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
                  decoration: BoxDecoration(
                    color: bgCol,
                  ),
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
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(brandColor),
        ),
      );
    }

    if (filteredList.isEmpty) {
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
                    child: Icon(
                      LucideIcons.clipboardX,
                      color: brandColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
                        ? 'Tidak Ada Aktivitas Ditemukan'
                        : 'Belum Ada Aktivitas Saya',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
                        ? 'Tidak ada aktivitas Anda yang sesuai dengan kata kunci pencarian atau filter yang dipilih.'
                        : 'Catat progres atau laporan pekerjaan harian Anda menggunakan tombol di bawah.',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (filterCriteria.hasActiveFilter ||
                      searchQuery.isNotEmpty)
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<ActivityListBloc>()
                            .add(const ActivityListSearchChanged(''));
                        context
                            .read<ActivityListBloc>()
                            .add(const ActivityListFilterApplied(
                                ActivityFilterCriteria()));
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.rotateCcw, size: 14, color: brandColor),
                          const SizedBox(width: 8),
                          Text(
                            'Reset Pencarian & Filter',
                            style: AppTypography.bodySmall.copyWith(
                              color: brandColor,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                          ),
                        ],
                      ),
                    )
                  else

                    ElevatedButton(
                      onPressed: _handleCreateActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor:
                            isDark ? const Color(0xFF003732) : Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color:
                                isDark ? const Color(0xFF003732) : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tambah Aktivitas',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? const Color(0xFF003732)
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              height: 1.0,
                              leadingDistribution: TextLeadingDistribution.even,
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
                final result =
                    await context.push(Routes.ACTIVITY_DETAIL, extra: item);
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
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  ),
                ),
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
      return _buildForbiddenState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        borderCol: borderCol,
        brandColor: brandColor,
      );
    }

    // 2. Loading Awal / Refresh
    if (isTeamLoading && teamActivities.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(brandColor),
        ),
      );
    }

    // 3. Status Kosong (Empty State)
    if (filteredList.isEmpty) {
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
                    child: Icon(
                      LucideIcons.users,
                      color: brandColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
                        ? 'Tidak Ada Aktivitas Ditemukan'
                        : 'Belum Ada Aktivitas Pegawai Lain',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filterCriteria.hasActiveFilter || searchQuery.isNotEmpty
                        ? 'Tidak ada aktivitas pegawai lain yang cocok dengan kata kunci atau kriteria filter.'
                        : 'Saat ini belum ada log aktivitas yang dikirimkan oleh rekan kerja Anda.',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (filterCriteria.hasActiveFilter ||
                      searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<ActivityListBloc>()
                            .add(const ActivityListSearchChanged(''));
                        context
                            .read<ActivityListBloc>()
                            .add(const ActivityListFilterApplied(
                                ActivityFilterCriteria()));
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.rotateCcw, size: 14, color: brandColor),
                          const SizedBox(width: 8),
                          Text(
                            'Reset Pencarian & Filter',
                            style: AppTypography.bodySmall.copyWith(
                              color: brandColor,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              leadingDistribution: TextLeadingDistribution.even,
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
                final result =
                    await context.push(Routes.ACTIVITY_DETAIL, extra: item);
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
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  ),
                ),
              ),
            );
          }
          return const SizedBox(height: 16);
        },
      ),
    );
  }

  /// Tampilan Khusus jika terjadi Error 403 (Tidak Memiliki Hak Akses Pegawai)
  Widget _buildForbiddenState({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    return RefreshIndicator(
      onRefresh: () async => _loadTeamActivities(page: 1, isRefresh: true),
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
                    'Anda tidak memiliki hak akses pada pegawai! Fitur ini khusus untuk akun dengan otoritas Approver atau Supervisor.',
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
                        onPressed: () =>
                            _loadTeamActivities(page: 1, isRefresh: true),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.rotateCcw, size: 14, color: textCol),
                            const SizedBox(width: 8),
                            Text(
                              'Coba Lagi',
                              style: AppTypography.bodySmall.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                leadingDistribution: TextLeadingDistribution.even,
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
                          foregroundColor:
                              isDark ? const Color(0xFF003732) : Colors.white,
                          elevation: 0,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.arrowLeft,
                              size: 14,
                              color: isDark ? const Color(0xFF003732) : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Aktivitasku',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? const Color(0xFF003732) : Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                leadingDistribution: TextLeadingDistribution.even,
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

  void _showAddActivityBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
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
    final fieldBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    ActivityStatus selectedStatus = ActivityStatus.completed;
    final bloc = context.read<ActivityListBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Material(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkOutlineMuted
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Close
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tambah Aktivitas Kerja',
                              style: AppTypography.titleMedium.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: subtitleCol,
                              ),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catat log aktivitas harian ke feed aktivitas Anda',
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleCol,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Field 1: Judul Aktivitas
                        Text(
                          'Judul Aktivitas',
                          style: AppTypography.labelMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleController,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textCol,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Misal: Review PR #142 & Sprint Planning',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: subtitleCol,
                            ),
                            filled: true,
                            fillColor: fieldBg,
                            prefixIcon: Icon(
                              LucideIcons.fileText,
                              size: 18,
                              color: brandColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: brandColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Field 2: Deskripsi / Catatan Kerja
                        Text(
                          'Deskripsi / Catatan Kerja',
                          style: AppTypography.labelMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descController,
                          maxLines: 3,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textCol,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Rincian tugas yang diselesaikan atau catatan progres...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: subtitleCol,
                            ),
                            filled: true,
                            fillColor: fieldBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: brandColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Field 3: Lokasi Kerja
                        Text(
                          'Lokasi Kerja',
                          style: AppTypography.labelMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: locationController,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textCol,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Misal: Kantor Pusat, Remote / WFH',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: subtitleCol,
                            ),
                            filled: true,
                            fillColor: fieldBg,
                            prefixIcon: Icon(
                              LucideIcons.mapPin,
                              size: 18,
                              color: brandColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: brandColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Field 4: Status Aktivitas
                        Text(
                          'Status Aktivitas',
                          style: AppTypography.labelMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('In Progress'),
                                selected:
                                    selectedStatus == ActivityStatus.inProgress,
                                onSelected: (sel) {
                                  if (sel) {
                                    setSheetState(
                                      () => selectedStatus =
                                          ActivityStatus.inProgress,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Completed'),
                                selected:
                                    selectedStatus == ActivityStatus.completed,
                                onSelected: (sel) {
                                  if (sel) {
                                    setSheetState(
                                      () => selectedStatus =
                                          ActivityStatus.completed,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons: Batal & Simpan Aktivitas
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: borderCol),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: subtitleCol,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final title = titleController.text.trim();
                                    if (title.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Judul aktivitas tidak boleh kosong!',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    final now = DateTime.now();
                                    final newActivity = ActivityItem(
                                      id: 'ACT-${now.millisecondsSinceEpoch}',
                                      title: title,
                                      description:
                                          descController.text.trim().isEmpty
                                          ? 'Aktivitas operasional harian'
                                          : descController.text.trim(),
                                      userName: 'Sarah Jenkins',
                                      userRole: 'Senior HR Specialist',
                                      department: 'Human Resources',
                                      company: 'PT Oasish Tech Nusantara',
                                      initials: 'SJ',
                                      status: selectedStatus,
                                      location:
                                          locationController.text.trim().isEmpty
                                          ? 'Kantor Pusat'
                                          : locationController.text.trim(),
                                      time:
                                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                                      date: now,
                                      isMyActivity: true,
                                    );

                                    bloc.add(ActivityListActivityAdded(newActivity));

                                    Navigator.of(sheetContext).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Aktivitas "$title" berhasil ditambahkan!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: const Color(
                                          0xFF0F766E,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandColor,
                                    foregroundColor: isDark
                                        ? const Color(0xFF003732)
                                        : Colors.white,
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Simpan Aktivitas',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? const Color(0xFF003732)
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
