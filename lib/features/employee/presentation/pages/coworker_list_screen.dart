import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/coworker_list/coworker_list_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Parameter argument saat navigasi ke halaman daftar coworker
class CoworkerListArgs {
  final List<EmployeeDirectoryItem>? initialCoworkers;
  final String? employeeName;
  final String? departmentName;

  const CoworkerListArgs({
    this.initialCoworkers,
    this.employeeName,
    this.departmentName,
  });
}

/// Halaman Daftar Rekan Kerja (Coworker List) Oasish HRIS sesuai Google Stitch M3.
/// Menggunakan Clean Architecture + Flutter BLoC (CoworkerListBloc).
/// Item ditampilkan menggunakan EmployeeCard yang identik dengan direktori pegawai.
class CoworkerListScreen extends StatelessWidget {
  final CoworkerListArgs? args;
  final EmployeeRepository? repository;
  final CoworkerListBloc? coworkerListBloc;

  const CoworkerListScreen({
    super.key,
    this.args,
    this.repository,
    this.coworkerListBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (coworkerListBloc != null) {
      return BlocProvider<CoworkerListBloc>.value(
        value: coworkerListBloc!,
        child: _CoworkerListView(args: args),
      );
    }

    return BlocProvider<CoworkerListBloc>(
      create: (ctx) => CoworkerListBloc(
        repository: repository,
        initialCoworkers: args?.initialCoworkers,
      )..add(CoworkerListStarted(initialCoworkers: args?.initialCoworkers)),
      child: _CoworkerListView(args: args),
    );
  }
}

class _CoworkerListView extends StatefulWidget {
  final CoworkerListArgs? args;

  const _CoworkerListView({this.args});

  @override
  State<_CoworkerListView> createState() => _CoworkerListViewState();
}

class _CoworkerListViewState extends State<_CoworkerListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    context.read<CoworkerListBloc>().add(CoworkerListSearchChanged(query));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundSubtle;
    final surfaceCol = isDark ? AppColors.darkSurface : AppColors.surface;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.surfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final subtitle = () {
      final parts = [
        if (widget.args?.employeeName != null &&
            widget.args!.employeeName!.isNotEmpty)
          widget.args!.employeeName!,
        if (widget.args?.departmentName != null &&
            widget.args!.departmentName!.isNotEmpty)
          widget.args!.departmentName!,
      ];
      if (parts.isNotEmpty) return parts.join(' • ');
      return 'Rekan kerja satu tim dan divisi';
    }();

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
              'Daftar Rekan Kerja',
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
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar Container
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceCol,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: borderCol, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textCol,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari rekan kerja (nama, posisi, email)...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: subtitleCol,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: subtitleCol,
                      size: 18,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: subtitleCol,
                              size: 16,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Main Content
            Expanded(
              child: BlocBuilder<CoworkerListBloc, CoworkerListState>(
                builder: (context, state) {
                  // Loading State
                  if (state.isLoading && state.coworkers.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                      ),
                    );
                  }

                  // Failure State
                  if (state.status == CoworkerListStatus.failure &&
                      state.coworkers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.circleAlert,
                                size: 30,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal Memuat Rekan Kerja',
                              style: AppTypography.titleMedium.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.errorMessage ??
                                  'Terjadi kesalahan saat memuat data rekan kerja.',
                              style: AppTypography.bodySmall.copyWith(
                                color: subtitleCol,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () {
                                context.read<CoworkerListBloc>().add(
                                  const CoworkerListRefreshed(),
                                );
                              },
                              icon: const Icon(LucideIcons.rotateCcw, size: 16),
                              label: const Text('Coba Lagi'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: brandColor,
                                side: BorderSide(
                                  color: brandColor.withValues(alpha: 0.5),
                                ),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Empty State
                  if (state.filteredCoworkers.isEmpty) {
                    final isSearching = state.searchQuery.trim().isNotEmpty;
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<CoworkerListBloc>().add(
                          const CoworkerListRefreshed(),
                        );
                      },
                      color: brandColor,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 48,
                        ),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceContainer
                                        : AppColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.users,
                                    size: 32,
                                    color: subtitleCol,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isSearching
                                      ? 'Rekan Kerja Tidak Ditemukan'
                                      : 'Belum Ada Rekan Kerja',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: textCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isSearching
                                      ? 'Tidak ada rekan kerja yang cocok dengan kata kunci "${state.searchQuery}".'
                                      : 'Belum ada rekan kerja yang terdaftar dalam tim atau divisi ini.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isSearching) ...[
                                  const SizedBox(height: 18),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    icon: const Icon(
                                      LucideIcons.rotateCcw,
                                      size: 15,
                                    ),
                                    label: const Text('Reset Pencarian'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: brandColor,
                                      side: BorderSide(
                                        color: brandColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Success List with EmployeeCard Items
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CoworkerListBloc>().add(
                        const CoworkerListRefreshed(),
                      );
                    },
                    color: brandColor,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: state.filteredCoworkers.length,
                      itemBuilder: (context, index) {
                        final coworker = state.filteredCoworkers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EmployeeCard(
                            employee: coworker,
                            onTap: () {
                              context.push(
                                Routes.EMPLOYEE_DETAIL,
                                extra: coworker,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
