import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Daftar Aktivitas (Activity Reports / Team Activity Feed) sesuai Google Stitch.
class ActivityScreen extends StatefulWidget {
  final List<ActivityItem>? customActivities;

  const ActivityScreen({super.key, this.customActivities});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityFilterCriteria _filterCriteria = const ActivityFilterCriteria();
  bool _isLoading = false;
  bool _isSearchVisible = true;

  late List<ActivityItem> _activities;

  @override
  void initState() {
    super.initState();
    _activities = List.from(
      widget.customActivities ?? ActivityItem.sampleActivities,
    );
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _activities = List.from(
          widget.customActivities ?? ActivityItem.sampleActivities,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateActivity() async {
    if (GoRouter.maybeOf(context) != null) {
      final newActivity =
          await context.push<ActivityItem>(Routes.CREATE_ACTIVITY);
      if (!mounted) return;
      if (newActivity != null) {
        setState(() {
          _activities.insert(0, newActivity);
        });
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
    final result = await showActivityFilterBottomSheet(
      context,
      initialCriteria: _filterCriteria,
    );
    if (result != null && mounted) {
      setState(() {
        _filterCriteria = result;
      });
    }
  }

  List<ActivityItem> _getFilteredActivities({required bool myActivitiesOnly}) {
    return _activities.where((item) {
      // 1. Tab filter (left: My Activities, right: Team Activities)
      if (myActivitiesOnly && !item.isMyActivity) {
        return false;
      }

      // 2. Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchUser = item.userName.toLowerCase().contains(q);
        final matchRole = item.userRole.toLowerCase().contains(q);
        final matchDept = item.department.toLowerCase().contains(q);
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        final matchLoc = item.location.toLowerCase().contains(q);

        if (!matchUser &&
            !matchRole &&
            !matchDept &&
            !matchTitle &&
            !matchDesc &&
            !matchLoc) {
          return false;
        }
      }

      // 3. Company filter
      if (_filterCriteria.company != null &&
          _filterCriteria.company != 'Semua Perusahaan') {
        if (!item.company.toLowerCase().contains(
          _filterCriteria.company!.toLowerCase(),
        )) {
          return false;
        }
      }

      // 4. Department filter
      if (_filterCriteria.department != null &&
          _filterCriteria.department != 'Semua Departemen') {
        if (!item.department.toLowerCase().contains(
          _filterCriteria.department!.toLowerCase(),
        )) {
          return false;
        }
      }

      // 5. Position filter
      if (_filterCriteria.position != null &&
          _filterCriteria.position != 'Semua Jabatan') {
        if (!item.userRole.toLowerCase().contains(
          _filterCriteria.position!.toLowerCase(),
        )) {
          return false;
        }
      }

      // 6. Date range filter
      if (_filterCriteria.dateRange != null) {
        final start = DateTime(
          _filterCriteria.dateRange!.start.year,
          _filterCriteria.dateRange!.start.month,
          _filterCriteria.dateRange!.start.day,
        );
        final end = DateTime(
          _filterCriteria.dateRange!.end.year,
          _filterCriteria.dateRange!.end.month,
          _filterCriteria.dateRange!.end.day,
          23,
          59,
          59,
        );
        if (item.date.isBefore(start) || item.date.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: _filterCriteria.hasActiveFilter ? brandColor : textCol,
                  size: 20,
                ),
                if (_filterCriteria.hasActiveFilter)
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
                    setState(() {});
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

            // 4. Dynamic Hide/Show Search Bar on Scroll (persis seperti employee directory)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isSearchVisible ? 58 : 0,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: bgCol,
              ),
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
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
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
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: subtitleCol,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
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

            // 5. TabBarView for Content (Left: My Activities, Right: Team Activities) with Scroll Notification Listener
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.metrics.axis == Axis.vertical) {
                    final delta = notification.scrollDelta ?? 0;

                    // Jika berada di dekat batas atas, selalu tampilkan search bar
                    if (notification.metrics.pixels <= 10) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                    // Saat scroll ke atas (content bergerak ke atas / offset membesar) -> sembunyikan search bar
                    else if (delta > 3) {
                      if (_isSearchVisible) {
                        setState(() => _isSearchVisible = false);
                      }
                    }
                    // Saat scroll ke bawah (content bergerak ke bawah / offset mengecil) -> tampilkan search bar
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
                    _buildActivityListView(
                      myActivitiesOnly: true,
                      isDark: isDark,
                      surfaceCol: surfaceCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      borderCol: borderCol,
                      brandColor: brandColor,
                    ),
                    _buildActivityListView(
                      myActivitiesOnly: false,
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

  Widget _buildActivityListView({
    required bool myActivitiesOnly,
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    final filteredList = _getFilteredActivities(
      myActivitiesOnly: myActivitiesOnly,
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                    myActivitiesOnly
                        ? 'Belum Ada Aktivitas Saya'
                        : 'Tidak Ada Aktivitas Ditemukan',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    myActivitiesOnly &&
                            !_filterCriteria.hasActiveFilter &&
                            _searchQuery.isEmpty
                        ? 'Catat progres atau laporan pekerjaan harian Anda menggunakan tombol di bawah.'
                        : 'Coba ubah kata kunci pencarian atau sesuaikan filter Anda.',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_filterCriteria.hasActiveFilter ||
                      _searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _filterCriteria = const ActivityFilterCriteria();
                        });
                      },
                      icon: const Icon(LucideIcons.rotateCcw, size: 14),
                      label: const Text('Reset Pencarian & Filter'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: filteredList.length + 1,
        itemBuilder: (context, index) {
          if (index < filteredList.length) {
            final item = filteredList[index];
            return ActivityCard(
              activity: item,
              onTap: () {
                context.push(Routes.ACTIVITY_DETAIL, extra: item);
              },
            );
          }
          return const SizedBox(height: 16);
        },
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

                                    setState(() {
                                      _activities.insert(0, newActivity);
                                    });

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
