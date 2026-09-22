import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_type_selection_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Presensi Luar Kantor / Pengajuan Kehadiran Luar Kantor.
/// Sesuai desain Stitch:
/// - Screen 1: Oasish Team Attendance Approvals (ID: 2175015883474c6db43079587a17dccb)
/// - Screen 2: Oasish Attendance Type Selection Modal Bottom Sheet (ID: b54d937212ed497e80f33efb8670a8e2)
class AttendanceRequestsScreen extends StatelessWidget {
  final AttendanceRequestRepository? repository;
  final AttendanceRequestListBloc? bloc;

  const AttendanceRequestsScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<AttendanceRequestListBloc>.value(
        value: bloc!,
        child: const _AttendanceRequestsScreenView(),
      );
    }
    return BlocProvider<AttendanceRequestListBloc>(
      create: (context) =>
          AttendanceRequestListBloc(repository: repository)
            ..add(const AttendanceRequestListStarted()),
      child: const _AttendanceRequestsScreenView(),
    );
  }
}

class _AttendanceRequestsScreenView extends StatefulWidget {
  const _AttendanceRequestsScreenView();

  @override
  State<_AttendanceRequestsScreenView> createState() =>
      _AttendanceRequestsScreenViewState();
}

class _AttendanceRequestsScreenViewState
    extends State<_AttendanceRequestsScreenView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearchVisible = true;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AttendanceRequestListBloc>().add(
            const AttendanceRequestListTabChanged(_initialTabIndex),
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
      setState(() {
        _isSearchVisible = true;
      });
      context.read<AttendanceRequestListBloc>().add(
            AttendanceRequestListTabChanged(_tabController.index),
          );
    }
  }

  // ── Infinite scroll ────────────────────────────────────────────────
  void _onMyScroll() {
    if (_myScrollController.hasClients &&
        _myScrollController.position.pixels >=
            _myScrollController.position.maxScrollExtent - 250) {
      context.read<AttendanceRequestListBloc>().add(
            const AttendanceRequestListLoadMoreRequested(isTeam: false),
          );
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 250) {
      context.read<AttendanceRequestListBloc>().add(
            const AttendanceRequestListLoadMoreRequested(isTeam: true),
          );
    }
  }

  // ── Search dengan debounce 300ms ───────────────────────────────────
  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<AttendanceRequestListBloc>().add(
            AttendanceRequestListSearchChanged(val),
          );
    });
  }

  Future<void> _handleRefresh() async {
    final isTeam = _tabController.index == 1;
    context.read<AttendanceRequestListBloc>().add(
          AttendanceRequestListFetchRequested(isRefresh: true, isTeam: isTeam),
        );
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _openFilterBottomSheet() async {
    final bloc = context.read<AttendanceRequestListBloc>();
    final result = await showAttendanceRequestFilterBottomSheet(
      context,
      initialCriteria: bloc.state.filterCriteria,
    );
    if (result != null && mounted) {
      bloc.add(AttendanceRequestListFilterApplied(result));
    }
  }

  Future<void> _openAttendanceTypeSelection() async {
    final selectedMethod =
        await showAttendanceTypeSelectionBottomSheet(context);
    if (selectedMethod != null && mounted) {
      if (selectedMethod == AttendanceOutsideMethod.live) {
        final refresh = await context.push<bool>(Routes.LIVE_ATTENDANCE);
        if (refresh == true && mounted) {
          context.read<AttendanceRequestListBloc>().add(
                const AttendanceRequestListFetchRequested(
                  isRefresh: true,
                  isTeam: false,
                ),
              );
        }
      } else if (selectedMethod == AttendanceOutsideMethod.schedule) {
        final refresh = await context.push<bool>(Routes.SCHEDULE_ATTENDANCE);
        if (refresh == true && mounted) {
          context.read<AttendanceRequestListBloc>().add(
                const AttendanceRequestListFetchRequested(
                  isRefresh: true,
                  isTeam: false,
                ),
              );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AttendanceRequestListBloc>().state;
    final filterCriteria = state.filterCriteria;
    final searchQuery = state.searchQuery;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundSubtle;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final brandColor =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: bgCol,
      // ── 1. Top App Bar ──────────────────────────────────────────────
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
              'Presensi Luar Kantor',
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
              'Verifikasi & persetujuan presensi tim luar kantor',
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

      // ── 2. Floating Action Button (Hanya tampil di Tab 0: Pengajuan Saya) ──
      floatingActionButton: AnimatedBuilder(
        animation: _tabController.animation ?? _tabController,
        builder: (context, child) {
          final animVal =
              _tabController.animation?.value ?? _tabController.index.toDouble();
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
          key: const ValueKey('add_attendance_request_fab'),
          onPressed: _openAttendanceTypeSelection,
          backgroundColor: brandColor,
          foregroundColor: isDark ? const Color(0xFF003732) : Colors.white,
          elevation: 3,
          shape: const StadiumBorder(),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(
            'Ajukan Presensi',
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
            // ── 3. Tab Bar (Pengajuan Saya & Persetujuan Tim) ──────────
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
                          const Icon(LucideIcons.mapPin, size: 16),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. Dynamic Hide/Show Search Bar on Scroll ─────────────
            // (Hanya muncul pada Tab Persetujuan Tim / index 1)
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
                              hintText:
                                  'Cari nama pegawai, divisi, atau perihal...',
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

            // ── 5. TabBarView (Pengajuan Saya / Persetujuan Tim) ───────
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_tabController.index == 1 &&
                      notification is ScrollUpdateNotification &&
                      notification.metrics.axis == Axis.vertical) {
                    final delta = notification.scrollDelta ?? 0;

                    if (notification.metrics.pixels <= 10) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    } else if (delta > 3) {
                      if (_isSearchVisible) {
                        setState(() => _isSearchVisible = false);
                      }
                    } else if (delta < -3) {
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
                    // Tab 0: Pengajuan Saya
                    _buildMyRequestsTab(
                      state: state,
                      isDark: isDark,
                      surfaceCol: surfaceCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      borderCol: borderCol,
                      brandColor: brandColor,
                    ),

                    // Tab 1: Persetujuan Tim (Pegawai Lain)
                    _buildTeamRequestsTab(
                      state: state,
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

  // ── Tab 0: Pengajuan Saya List ──────────────────────────────────────
  Widget _buildMyRequestsTab({
    required AttendanceRequestListState state,
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    if (state.isMyLoading) {
      return _buildLoadingList();
    }

    if (state.myRequests.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        brandColor: brandColor,
        title: 'Belum Ada Pengajuan Presensi',
        subtitle:
            'Anda belum memiliki riwayat pengajuan presensi luar kantor.',
        isTeam: false,
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.separated(
        controller: _myScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: state.myRequests.length + (state.isMyLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.myRequests.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final item = state.myRequests[index];
          return AttendanceRequestCard(
            item: item,
            onTap: () async {
              final updated = await context.push<bool>(
                Routes.ATTENDANCE_REQUEST_DETAIL,
                extra: {
                  'id': item.id,
                  'isApprover': false,
                },
              );
              if (updated == true && context.mounted) {
                context.read<AttendanceRequestListBloc>().add(
                      const AttendanceRequestListFetchRequested(
                        isRefresh: true,
                        isTeam: false,
                      ),
                    );
              }
            },
          );
        },
      ),
    );
  }

  // ── Tab 1: Persetujuan Tim List ────────────────────────────────────
  Widget _buildTeamRequestsTab({
    required AttendanceRequestListState state,
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    // 1. Error 403 Forbidden: Tampilkan "Tidak Memiliki Hak Akses"
    if (state.isTeamForbidden) {
      return _buildForbiddenState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        borderCol: borderCol,
        brandColor: brandColor,
      );
    }

    if (state.isTeamLoading) {
      return _buildLoadingList();
    }

    if (state.teamRequests.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        brandColor: brandColor,
        title: 'Tidak Ada Pengajuan Tim',
        subtitle: state.searchQuery.isNotEmpty
            ? 'Tidak ditemukan pengajuan presensi dengan kata kunci "${state.searchQuery}".'
            : 'Saat ini belum ada pengajuan presensi luar kantor dari anggota tim.',
        isTeam: true,
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.separated(
        controller: _teamScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: state.teamRequests.length + (state.isTeamLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.teamRequests.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final item = state.teamRequests[index];
          return AttendanceRequestCard(
            item: item,
            onTap: () async {
              final updated = await context.push<bool>(
                Routes.ATTENDANCE_REQUEST_DETAIL,
                extra: {
                  'id': item.id,
                  'isApprover': true,
                },
              );
              if (updated == true && context.mounted) {
                context.read<AttendanceRequestListBloc>().add(
                      const AttendanceRequestListFetchRequested(
                        isRefresh: true,
                        isTeam: true,
                      ),
                    );
              }
            },
          );
        },
      ),
    );
  }

  // ── Forbidden state (HTTP 403, khusus tab Persetujuan Tim) ──────────
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
        context.read<AttendanceRequestListBloc>().add(
              const AttendanceRequestListFetchRequested(
                isRefresh: true,
                isTeam: true,
              ),
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
                    'Anda tidak memiliki otoritas sebagai approver untuk melihat pengajuan presensi tim luar kantor. Fitur ini khusus untuk akun dengan otoritas Approver atau Supervisor.',
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
                          context.read<AttendanceRequestListBloc>().add(
                                const AttendanceRequestListFetchRequested(
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
                        ),
                        child: Text(
                          'Ke Pengajuan Saya',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isDark ? const Color(0xFF003732) : Colors.white,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
    required String title,
    required String subtitle,
    required bool isTeam,
  }) {
    final state = context.watch<AttendanceRequestListBloc>().state;
    final hasActiveFilter = state.filterCriteria.hasActiveFilter;
    final hasSearch = state.searchQuery.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.calendarCheck2,
                    color: brandColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 13,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasActiveFilter || hasSearch) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<AttendanceRequestListBloc>().add(
                            const AttendanceRequestListFilterReset(),
                          );
                    },
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

  // ── Shimmer / Loading State ─────────────────────────────────────────
  Widget _buildLoadingList() {
    return const RequestCardShimmerLoading();
  }
}
