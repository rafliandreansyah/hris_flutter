import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_event.dart';

abstract class NotificationListState extends Equatable {
  const NotificationListState();

  @override
  List<Object?> get props => [];
}

class NotificationListInitial extends NotificationListState {
  const NotificationListInitial();
}

class NotificationListLoading extends NotificationListState {
  const NotificationListLoading();
}

class NotificationListLoaded extends NotificationListState {
  final List<NotificationItemModel> notifications;
  final int page;
  final int totalPages;
  final int total;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isMarkingAll;
  final NotificationFilterType activeFilter;
  final String? actionMessage;

  const NotificationListLoaded({
    required this.notifications,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isMarkingAll = false,
    this.activeFilter = NotificationFilterType.all,
    this.actionMessage,
  });

  /// Daftar notifikasi terfilter sesuai pilihan tab pengguna (Semua vs Belum Dibaca)
  List<NotificationItemModel> get displayedNotifications {
    if (activeFilter == NotificationFilterType.unread) {
      return notifications.where((item) => !item.isRead).toList();
    }
    return notifications;
  }

  /// Jumlah notifikasi yang belum dibaca dalam cache daftar saat ini
  int get localUnreadCount =>
      notifications.where((item) => !item.isRead).length;

  NotificationListLoaded copyWith({
    List<NotificationItemModel>? notifications,
    int? page,
    int? totalPages,
    int? total,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isMarkingAll,
    NotificationFilterType? activeFilter,
    String? actionMessage,
  }) {
    return NotificationListLoaded(
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      activeFilter: activeFilter ?? this.activeFilter,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        page,
        totalPages,
        total,
        hasReachedMax,
        isLoadingMore,
        isMarkingAll,
        activeFilter,
        actionMessage,
      ];
}

class NotificationListError extends NotificationListState {
  final String message;
  final int? statusCode;

  const NotificationListError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
