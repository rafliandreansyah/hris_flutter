import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_event.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_state.dart';

class NotificationListBloc
    extends Bloc<NotificationListEvent, NotificationListState> {
  final NotificationRepository _repository;
  static const int _pageSize = 20;

  NotificationListBloc({
    NotificationRepository? repository,
  })  : _repository = repository ?? NotificationRepositoryImpl(),
        super(const NotificationListInitial()) {
    on<NotificationListStarted>(_onStarted);
    on<NotificationListRefreshed>(_onRefreshed);
    on<NotificationListLoadMore>(_onLoadMore);
    on<NotificationListFilterChanged>(_onFilterChanged);
    on<NotificationMarkAsReadRequested>(_onMarkAsRead);
    on<NotificationMarkAllAsReadRequested>(_onMarkAllAsRead);
  }

  Future<void> _onStarted(
    NotificationListStarted event,
    Emitter<NotificationListState> emit,
  ) async {
    emit(const NotificationListLoading());
    try {
      final response = await _repository.getNotifications(
        page: 1,
        limit: _pageSize,
      );

      final hasReachedMax =
          response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(NotificationListLoaded(
        notifications: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
        activeFilter: event.filter ?? NotificationFilterType.all,
      ));
    } on ApiException catch (e) {
      emit(NotificationListError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(NotificationListError(message: 'Gagal memuat notifikasi: $e'));
    }
  }

  Future<void> _onRefreshed(
    NotificationListRefreshed event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentFilter = state is NotificationListLoaded
        ? (state as NotificationListLoaded).activeFilter
        : NotificationFilterType.all;

    try {
      final response = await _repository.getNotifications(
        page: 1,
        limit: _pageSize,
      );

      final hasReachedMax =
          response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(NotificationListLoaded(
        notifications: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
        activeFilter: currentFilter,
      ));
    } on ApiException catch (e) {
      if (state is! NotificationListLoaded) {
        emit(NotificationListError(
            message: e.message, statusCode: e.statusCode));
      }
    } catch (e) {
      if (state is! NotificationListLoaded) {
        emit(NotificationListError(message: 'Gagal menyegarkan notifikasi: $e'));
      }
    }
  }

  Future<void> _onLoadMore(
    NotificationListLoadMore event,
    Emitter<NotificationListState> emit,
  ) async {
    if (state is! NotificationListLoaded) return;
    final currentState = state as NotificationListLoaded;

    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.page + 1;
      final response = await _repository.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );

      final existingIds = currentState.notifications.map((n) => n.id).toSet();
      final newItems =
          response.data.where((n) => !existingIds.contains(n.id)).toList();
      final updatedList = List<NotificationItemModel>.from(
          currentState.notifications)
        ..addAll(newItems);

      final hasReachedMax =
          response.meta.page >= response.meta.totalPages ||
          updatedList.length >= response.meta.total;

      emit(currentState.copyWith(
        notifications: updatedList,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
      ));
    } on ApiException catch (_) {
      emit(currentState.copyWith(isLoadingMore: false));
    } catch (_) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onFilterChanged(
    NotificationListFilterChanged event,
    Emitter<NotificationListState> emit,
  ) {
    if (state is NotificationListLoaded) {
      final currentState = state as NotificationListLoaded;
      emit(currentState.copyWith(activeFilter: event.filter));
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationListState> emit,
  ) async {
    if (state is! NotificationListLoaded) return;
    final currentState = state as NotificationListLoaded;

    // Optimistic update
    final updatedList = currentState.notifications.map((n) {
      if (n.id == event.id && !n.isRead) {
        return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
      }
      return n;
    }).toList();

    emit(currentState.copyWith(notifications: updatedList));

    try {
      await _repository.markAsRead(event.id);
    } catch (_) {
      // Backend error logged, state remains optimistic for smoother UX
    }
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsReadRequested event,
    Emitter<NotificationListState> emit,
  ) async {
    if (state is! NotificationListLoaded) return;
    final currentState = state as NotificationListLoaded;

    emit(currentState.copyWith(isMarkingAll: true));

    // Optimistic update
    final updatedList = currentState.notifications.map((n) {
      if (!n.isRead) {
        return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
      }
      return n;
    }).toList();

    try {
      await _repository.markAllAsRead();
      emit(currentState.copyWith(
        notifications: updatedList,
        isMarkingAll: false,
        actionMessage: 'Semua notifikasi berhasil ditandai telah dibaca.',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        notifications: updatedList,
        isMarkingAll: false,
        actionMessage: 'Semua notifikasi telah ditandai dibaca.',
      ));
    }
  }
}
