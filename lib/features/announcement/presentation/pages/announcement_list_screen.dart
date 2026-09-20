import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_bloc.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_event.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_state.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_card.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_shimmer_loading.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Layar utama daftar pengumuman (Announcement List Screen).
/// Menggunakan BLoC state management, Google Stitch M3 "Teal Oasis" design tokens,
/// dan integrasi REST API backend Muratech HRIS.
class AnnouncementListScreen extends StatelessWidget {
  final AnnouncementRepository? repository;
  final AnnouncementListBloc? bloc;

  const AnnouncementListScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<AnnouncementListBloc>.value(
        value: bloc!,
        child: const _AnnouncementListView(),
      );
    }

    return BlocProvider<AnnouncementListBloc>(
      create: (context) => AnnouncementListBloc(
        repository: repository,
      )..add(const AnnouncementListStarted()),
      child: const _AnnouncementListView(),
    );
  }
}

class _AnnouncementListView extends StatefulWidget {
  const _AnnouncementListView();

  @override
  State<_AnnouncementListView> createState() => _AnnouncementListViewState();
}

class _AnnouncementListViewState extends State<_AnnouncementListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 200)) {
      context.read<AnnouncementListBloc>().add(const AnnouncementListLoadMore());
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<AnnouncementListBloc>().add(
              AnnouncementSearchChanged(query),
            );
      }
    });
  }

  Future<void> _openFilterBottomSheet(AnnouncementListState state) async {
    final result = await showAnnouncementFilterBottomSheet(
      context,
      initialCriteria: AnnouncementFilterCriteria(
        category: state.selectedCategory,
        priority: state.selectedPriority,
      ),
    );

    if (result != null && mounted) {
      context.read<AnnouncementListBloc>().add(
            AnnouncementFilterApplied(
              category: result.category,
              priority: result.priority,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.textSecondary;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final searchBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return BlocConsumer<AnnouncementListBloc, AnnouncementListState>(
      listener: (context, state) {
        if (state.status == AnnouncementStatus.failure &&
            state.errorMessage != null &&
            state.announcements.isNotEmpty) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final hasActiveFilter = state.hasActiveFilter;
        final activeFilterCount = state.activeFilterCount;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: textCol,
                size: 22,
              ),
              onPressed: () => context.pop(),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengumuman',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Berita perusahaan, surat edaran & update resmi',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            actions: [
              // Tombol Filter dengan Badge Jumlah Filter Aktif
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.slidersHorizontal,
                      color: hasActiveFilter ? brandColor : textCol,
                      size: 20,
                    ),
                    tooltip: 'Filter Pengumuman',
                    onPressed: () => _openFilterBottomSheet(state),
                  ),
                  if (hasActiveFilter)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: bgColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search Bar Section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  8,
                  AppSpacing.marginMobile,
                  10,
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: searchBg,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(
                      color: borderCol,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textCol,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari pengumuman berdasarkan judul atau kata kunci...',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12.5,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: subtitleCol,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: subtitleCol,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<AnnouncementListBloc>().add(
                                      const AnnouncementSearchChanged(''),
                                    );
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

              // Active Filters Bar (Muncul jika ada filter kategori/prioritas aktif)
              if (hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    0,
                    AppSpacing.marginMobile,
                    10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.filter,
                        size: 13,
                        color: brandColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filter Aktif: ',
                        style: AppTypography.labelSmall.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          [
                            if (state.selectedCategory != null)
                              'Kategori: ${state.selectedCategory}',
                            if (state.selectedPriority != null)
                              'Prioritas: ${state.selectedPriority}',
                          ].join(', '),
                          style: AppTypography.labelSmall.copyWith(
                            color: brandColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.read<AnnouncementListBloc>().add(
                                const AnnouncementFilterReset(),
                              );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            'Reset',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Feed List
              Expanded(
                child: _buildBody(context, state, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnnouncementListState state,
    bool isDark,
  ) {
    // 1. Initial Loading State
    if (state.status == AnnouncementStatus.loading &&
        state.announcements.isEmpty) {
      return const AnnouncementShimmerLoading();
    }

    // 2. Full-Screen Error State
    if (state.status == AnnouncementStatus.failure &&
        state.announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.alertCircle,
                  color: AppColors.errorRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Pengumuman',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Terjadi kesalahan sistem saat mengambil data pengumuman.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Coba Lagi',
                variant: AppButtonVariant.primary,
                width: 160,
                height: 44,
                leadingIcon: LucideIcons.refreshCw,
                onPressed: () {
                  context.read<AnnouncementListBloc>().add(
                        const AnnouncementListStarted(),
                      );
                },
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State
    if (state.announcements.isEmpty) {
      return RefreshIndicator(
        color: AppColors.brandTeal,
        onRefresh: () async {
          context.read<AnnouncementListBloc>().add(
                const AnnouncementListRefreshed(),
              );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.newspaper,
                      size: 30,
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Pengumuman',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.hasActiveFilter ||
                            (state.searchQuery != null &&
                                state.searchQuery!.isNotEmpty)
                        ? 'Tidak ada pengumuman yang sesuai dengan kriteria filter atau pencarian Anda.'
                        : 'Belum ada pengumuman resmi terbaru saat ini.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.hasActiveFilter) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Reset Filter',
                      variant: AppButtonVariant.outlined,
                      width: 140,
                      height: 40,
                      leadingIcon: LucideIcons.rotateCcw,
                      onPressed: () {
                        context.read<AnnouncementListBloc>().add(
                              const AnnouncementFilterReset(),
                            );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4. Success State with List
    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        context.read<AnnouncementListBloc>().add(
              const AnnouncementListRefreshed(),
            );
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: 12,
        ),
        itemCount: state.announcements.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == state.announcements.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.brandTeal,
                  ),
                ),
              ),
            );
          }

          final announcement = state.announcements[index];
          return AnnouncementCard(
            announcement: announcement,
            onTap: () async {
              final updated = await context.push<bool>(
                Routes.ANNOUNCEMENT_DETAIL,
                extra: announcement.id,
              );
              if (updated == true && context.mounted) {
                context.read<AnnouncementListBloc>().add(
                      const AnnouncementListRefreshed(),
                    );
              }
            },
          );
        },
      ),
    );
  }
}
