import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_bloc.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_state.dart';
import 'package:hris_flutter/features/warning_letter/presentation/widgets/warning_letter_card.dart';
import 'package:hris_flutter/features/warning_letter/presentation/widgets/warning_letter_filter_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Daftar Surat Peringatan (Warning Letter).
/// Sesuai Google Stitch M3: "Oasish Issued Warning Letters - Manager View"
/// (ID: 61002e2c2eaf4c8a9531d42e1d439c37).
class WarningLetterScreen extends StatelessWidget {
  final WarningLetterRepository? repository;
  final WarningLetterListBloc? bloc;

  const WarningLetterScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<WarningLetterListBloc>.value(
        value: bloc!,
        child: const _WarningLetterScreenView(),
      );
    }

    return BlocProvider<WarningLetterListBloc>(
      create: (context) => WarningLetterListBloc(repository: repository)
        ..add(const WarningLetterListStarted()),
      child: const _WarningLetterScreenView(),
    );
  }
}

class _WarningLetterScreenView extends StatefulWidget {
  const _WarningLetterScreenView();

  @override
  State<_WarningLetterScreenView> createState() =>
      _WarningLetterScreenViewState();
}

class _WarningLetterScreenViewState extends State<_WarningLetterScreenView>
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
      context.read<WarningLetterListBloc>().add(
            const WarningLetterListTabChanged(_initialTabIndex),
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
      context.read<WarningLetterListBloc>().add(
            WarningLetterListTabChanged(_tabController.index),
          );
    }
  }

  // ── Infinite scroll ────────────────────────────────────────────────
  void _onMyScroll() {
    if (_myScrollController.hasClients &&
        _myScrollController.position.pixels >=
            _myScrollController.position.maxScrollExtent - 250) {
      context.read<WarningLetterListBloc>().add(
            const WarningLetterListLoadMoreRequested(isTeam: false),
          );
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 250) {
      context.read<WarningLetterListBloc>().add(
            const WarningLetterListLoadMoreRequested(isTeam: true),
          );
    }
  }

  // ── Search dengan debounce 300ms ───────────────────────────────────
  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<WarningLetterListBloc>().add(
            WarningLetterListSearchChanged(val),
          );
    });
  }

  Future<void> _handleRefresh() async {
    final isTeam = _tabController.index == 1;
    context.read<WarningLetterListBloc>().add(
          WarningLetterListFetchRequested(isRefresh: true, isTeam: isTeam),
        );
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _openFilterBottomSheet() async {
    final bloc = context.read<WarningLetterListBloc>();
    final result = await showWarningLetterFilterBottomSheet(
      context,
      initialCriteria: bloc.state.filterCriteria,
      letterTypes: bloc.state.letterTypes,
    );
    if (result != null && mounted) {
      bloc.add(WarningLetterListFilterApplied(result));
    }
  }

  Future<void> _handleCreateWarningLetter() async {
    final created = await context.pushNamed<bool>(Routes.CREATE_WARNING_LETTER);
    if (created == true && mounted) {
      context.read<WarningLetterListBloc>().add(
            const WarningLetterListFetchRequested(isRefresh: true, isTeam: true),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<WarningLetterListBloc>().state;
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
              'Surat Peringatan',
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
              'Manajemen sanksi, teguran & disiplin tim',
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

      // ── 2. Floating Action Button (Hanya tampil di Tab 1 jika berhak) ──
      floatingActionButton: AnimatedBuilder(
        animation: _tabController.animation ?? _tabController,
        builder: (context, child) {
          final animVal = _tabController.animation?.value ??
              _tabController.index.toDouble();
          // Progress: 0.0 di tab 0, 1.0 di tab 1
          final progress = animVal.clamp(0.0, 1.0);

          // Jika Tab 1 mengalami error 403 Forbidden atau progress kecil, sembunyikan FAB
          if (state.isTeamForbidden || progress <= 0.05) {
            return const SizedBox.shrink();
          }

          return Transform.scale(
            scale: progress,
            alignment: Alignment.bottomRight,
            child: Opacity(opacity: progress, child: child),
          );
        },
        child: FloatingActionButton.extended(
          key: const ValueKey('add_warning_letter_fab'),
          onPressed: _handleCreateWarningLetter,
          backgroundColor: brandColor,
          foregroundColor: isDark ? const Color(0xFF003732) : Colors.white,
          elevation: 4,
          shape: const StadiumBorder(),
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(
            'Buat Surat Peringatan',
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
            // ── 3. Tab Bar (Surat Diterima & Diterbitkan) ──────────────
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
                          const Icon(LucideIcons.triangleAlert, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.tabWarningReceived ?? 'Surat Diterima',
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
                          const Icon(LucideIcons.clipboardList, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.tabWarningIssued ?? 'Diterbitkan',
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
            // (Hanya muncul pada Tab Diterbitkan / index 1)
            Builder(
              builder: (context) {
                final isTeamTab = _tabController.index == 1;
                final showSearchBar =
                    isTeamTab && _isSearchVisible && !state.isTeamForbidden;

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
                                  'Cari nama pegawai, divisi, atau nomor SP...',
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

            // ── 5. TabBarView (Surat Diterima / Diterbitkan) ───────────
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
                    // Tab 0: Surat Diterima
                    _buildMyLettersTab(
                      state: state,
                      isDark: isDark,
                      surfaceCol: surfaceCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      borderCol: borderCol,
                      brandColor: brandColor,
                    ),

                    // Tab 1: Diterbitkan (Pegawai Lain)
                    _buildTeamLettersTab(
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

  // ── Tab 0: Surat Diterima List ──────────────────────────────────────
  Widget _buildMyLettersTab({
    required WarningLetterListState state,
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
  }) {
    if (state.isMyLoading) {
      return const RequestCardShimmerLoading();
    }

    if (state.myError != null && state.myLetters.isEmpty) {
      return _buildErrorState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        borderCol: borderCol,
        brandColor: brandColor,
        errorMessage: state.myError!,
        onRetry: () {
          context.read<WarningLetterListBloc>().add(
                const WarningLetterListFetchRequested(
                  isRefresh: true,
                  isTeam: false,
                ),
              );
        },
      );
    }

    if (state.myLetters.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        brandColor: brandColor,
        title: 'Belum Ada Surat Peringatan',
        subtitle:
            'Anda tidak memiliki riwayat surat peringatan atau sanksi indisipliner.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.separated(
        controller: _myScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: state.myLetters.length + (state.isMyLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.myLetters.length) {
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
          final item = state.myLetters[index];
          return WarningLetterCard(
            item: item,
            onTap: () {
              context.push(
                Routes.WARNING_LETTER_DETAIL,
                extra: {'id': item.id},
              );
            },
          );
        },
      ),
    );
  }

  // ── Tab 1: Diterbitkan List ─────────────────────────────────────────
  Widget _buildTeamLettersTab({
    required WarningLetterListState state,
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
      return const RequestCardShimmerLoading();
    }

    if (state.teamError != null && state.teamLetters.isEmpty) {
      return _buildErrorState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        borderCol: borderCol,
        brandColor: brandColor,
        errorMessage: state.teamError!,
        onRetry: () {
          context.read<WarningLetterListBloc>().add(
                const WarningLetterListFetchRequested(
                  isRefresh: true,
                  isTeam: true,
                ),
              );
        },
      );
    }

    if (state.teamLetters.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        surfaceCol: surfaceCol,
        textCol: textCol,
        subtitleCol: subtitleCol,
        brandColor: brandColor,
        title: 'Tidak Ada Surat Peringatan Diterbitkan',
        subtitle: state.searchQuery.isNotEmpty
            ? 'Tidak ditemukan surat peringatan dengan kata kunci "${state.searchQuery}".'
            : 'Saat ini belum ada surat peringatan yang diterbitkan untuk pegawai lain.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: brandColor,
      child: ListView.separated(
        controller: _teamScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: state.teamLetters.length + (state.isTeamLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.teamLetters.length) {
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
          final item = state.teamLetters[index];
          return WarningLetterCard(
            item: item,
            onTap: () {
              context.push(
                Routes.WARNING_LETTER_DETAIL,
                extra: {'id': item.id},
              );
            },
          );
        },
      ),
    );
  }

  // ── Forbidden state (HTTP 403, khusus tab Diterbitkan) ───────────────
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
        context.read<WarningLetterListBloc>().add(
              const WarningLetterListFetchRequested(
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
                    'Anda tidak memiliki otoritas untuk melihat atau menerbitkan surat peringatan bagi pegawai lain. Fitur ini khusus untuk akun Supervisor, Manajer, atau HR.',
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
                          context.read<WarningLetterListBloc>().add(
                                const WarningLetterListFetchRequested(
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
                          'Surat Diterima',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isDark ? const Color(0xFF003732) : Colors.white,
                            fontWeight: FontWeight.w600,
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

  // ── Error State Card ────────────────────────────────────────────────
  Widget _buildErrorState({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color brandColor,
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceCol,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 40,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal Memuat Data',
                style: AppTypography.titleSmall.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor:
                      isDark ? const Color(0xFF003732) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required bool isDark,
    required Color surfaceCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: isDark ? 0.2 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.fileCheck2,
                size: 34,
                color: brandColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
