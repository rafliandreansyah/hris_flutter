import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_bloc.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_event.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_state.dart';
import 'package:hris_flutter/features/notification/presentation/widgets/notification_item_card.dart';
import 'package:hris_flutter/features/notification/presentation/widgets/notification_shimmer_loading.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Pusat Notifikasi (Notification Center) yang menampilkan daftar
/// riwayat pemberitahuan karyawan dengan dukungan pagination, pull-to-refresh,
/// filter belum dibaca, dan tandai semua sebagai telah dibaca.
class NotificationScreen extends StatelessWidget {
  final NotificationRepository? repository;
  final NotificationListBloc? bloc;

  const NotificationScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<NotificationListBloc>.value(
        value: bloc!,
        child: const _NotificationView(),
      );
    }

    return BlocProvider<NotificationListBloc>(
      create: (context) => NotificationListBloc(
        repository: repository,
      )..add(const NotificationListStarted()),
      child: const _NotificationView(),
    );
  }
}

class _NotificationView extends StatefulWidget {
  const _NotificationView();

  @override
  State<_NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<_NotificationView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll - 200)) {
      context.read<NotificationListBloc>().add(
            const NotificationListLoadMore(),
          );
    }
  }

  void _handleNotificationTap(NotificationItemModel item) {
    final type = item.type.toLowerCase();

    // Navigasi kontekstual berdasarkan tipe notifikasi
    if (type.contains('leave')) {
      context.push(Routes.LEAVE);
    } else if (type.contains('overtime')) {
      context.push(Routes.OVERTIME);
    } else if (type.contains('attendance')) {
      context.push(Routes.ATTENDANCE);
    } else if (type.contains('activity')) {
      context.push(Routes.ACTIVITY);
    } else {
      _showDetailBottomSheet(item);
    }
  }

  void _showDetailBottomSheet(NotificationItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Pemberitahuan',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.timeAgoLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.body,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Tutup',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          key: const ValueKey('notification_back_btn'),
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            Text(
              'Pemberitahuan aktivitas & pengumuman',
              style: AppTypography.bodySmall.copyWith(
                color: labelCol,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<NotificationListBloc, NotificationListState>(
            builder: (context, state) {
              final unreadCount = state is NotificationListLoaded
                  ? state.localUnreadCount
                  : 0;

              return TextButton.icon(
                key: const ValueKey('mark_all_read_btn'),
                onPressed: unreadCount > 0
                    ? () {
                        context.read<NotificationListBloc>().add(
                              const NotificationMarkAllAsReadRequested(),
                            );
                      }
                    : null,
                icon: Icon(
                  LucideIcons.checkCheck,
                  size: 16,
                  color: unreadCount > 0
                      ? AppColors.brandTeal
                      : labelCol.withValues(alpha: 0.4),
                ),
                label: Text(
                  'Tandai Dibaca',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: unreadCount > 0
                        ? AppColors.brandTeal
                        : labelCol.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<NotificationListBloc, NotificationListState>(
        listener: (context, state) {
          if (state is NotificationListLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.actionMessage!)),
                  ],
                ),
                backgroundColor: const Color(0xFF0F766E),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationListLoading ||
              state is NotificationListInitial) {
            return const NotificationShimmerLoading();
          }

          if (state is NotificationListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 48,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Notifikasi',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: labelCol,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Coba Lagi',
                      leadingIcon: LucideIcons.rotateCcw,
                      onPressed: () {
                        context.read<NotificationListBloc>().add(
                              const NotificationListStarted(),
                            );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final loadedState = state as NotificationListLoaded;
          final items = loadedState.displayedNotifications;

          return Column(
            children: [
              // Filter Tabs (Semua / Belum Dibaca)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLowest
                      : Colors.white,
                  border: Border(bottom: BorderSide(color: borderCol)),
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      count: loadedState.notifications.length,
                      isSelected: loadedState.activeFilter ==
                          NotificationFilterType.all,
                      onTap: () {
                        context.read<NotificationListBloc>().add(
                              const NotificationListFilterChanged(
                                NotificationFilterType.all,
                              ),
                            );
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Belum Dibaca',
                      count: loadedState.localUnreadCount,
                      isSelected: loadedState.activeFilter ==
                          NotificationFilterType.unread,
                      onTap: () {
                        context.read<NotificationListBloc>().add(
                              const NotificationListFilterChanged(
                                NotificationFilterType.unread,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),

              // Daftar Notifikasi / Empty State
              Expanded(
                child: items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () async {
                          context.read<NotificationListBloc>().add(
                                const NotificationListRefreshed(),
                              );
                        },
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: isDark
                                            ? AppColors.darkSurfaceContainer
                                            : const Color(0xFFF1F5F9),
                                        child: Icon(
                                          LucideIcons.bellOff,
                                          size: 36,
                                          color: labelCol,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        loadedState.activeFilter ==
                                                NotificationFilterType.unread
                                            ? 'Tidak Ada Notifikasi Baru'
                                            : 'Belum Ada Notifikasi',
                                        style: AppTypography.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: textCol,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        loadedState.activeFilter ==
                                                NotificationFilterType.unread
                                            ? 'Semua notifikasi telah Anda baca.'
                                            : 'Pemberitahuan aktivitas dan pengumuman akan muncul di sini.',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: labelCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<NotificationListBloc>().add(
                                const NotificationListRefreshed(),
                              );
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.marginMobile,
                            vertical: AppSpacing.md,
                          ),
                          itemCount: items.length +
                              (loadedState.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
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

                            final notification = items[index];
                            return NotificationItemCard(
                              notification: notification,
                              onMarkAsRead: () {
                                context.read<NotificationListBloc>().add(
                                      NotificationMarkAsReadRequested(
                                        notification.id,
                                      ),
                                    );
                              },
                              onTap: () => _handleNotificationTap(notification),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark
        ? AppColors.brandTeal.withValues(alpha: 0.2)
        : const Color(0xFFCCFBF1);
    final unselectedBg = isDark
        ? AppColors.darkSurfaceContainer
        : const Color(0xFFF1F5F9);
    final selectedText = AppColors.brandTeal;
    final unselectedText = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.brandTeal.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? selectedText : unselectedText,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandTeal
                      : unselectedText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : unselectedText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
