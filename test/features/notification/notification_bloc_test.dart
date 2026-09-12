import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_bloc.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_event.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_state.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_bloc.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_event.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_list/notification_list_state.dart';

class _FakeNotificationRepository implements NotificationRepository {
  int unreadCount;
  List<NotificationItemModel> items;
  bool shouldThrow;

  _FakeNotificationRepository({
    this.unreadCount = 2,
    List<NotificationItemModel>? items,
    this.shouldThrow = false,
  }) : items = items ?? [
          const NotificationItemModel(
            id: 'notif-1',
            title: 'Cuti Sakit Disetujui',
            body: 'Pengajuan cuti sakit Anda telah disetujui.',
            type: 'leave_request',
            isRead: false,
          ),
          const NotificationItemModel(
            id: 'notif-2',
            title: 'Pengumuman Libur Nasional',
            body: 'Kantor libur tanggal 17 Agustus.',
            type: 'announcement',
            isRead: true,
          ),
        ];

  @override
  Future<NotificationUnreadCountResponse> getUnreadCount() async {
    if (shouldThrow) {
      throw const ApiException(message: 'Gagal memuat jumlah');
    }
    return NotificationUnreadCountResponse(
      success: true,
      message: 'OK',
      unreadCount: unreadCount,
    );
  }

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    if (shouldThrow) {
      throw const ApiException(message: 'Gagal memuat daftar');
    }
    return NotificationListResponse(
      success: true,
      message: 'OK',
      data: items,
      meta: NotificationPaginationMeta(
        page: page,
        limit: limit,
        total: items.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<NotificationMarkReadAllResponse> markAllAsRead() async {
    if (shouldThrow) {
      throw const ApiException(message: 'Gagal menandai semua');
    }
    unreadCount = 0;
    return const NotificationMarkReadAllResponse(
      success: true,
      message: 'OK',
      updatedCount: 2,
    );
  }

  @override
  Future<NotificationMarkReadResponse> markAsRead(String id) async {
    if (shouldThrow) {
      throw const ApiException(message: 'Gagal menandai dibaca');
    }
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    return NotificationMarkReadResponse(
      success: true,
      message: 'OK',
      id: id,
    );
  }
}

void main() {
  group('NotificationCountBloc Tests', () {
    test('emits updated count on NotificationCountFetchRequested success', () async {
      final repository = _FakeNotificationRepository(unreadCount: 5);
      final bloc = NotificationCountBloc(repository: repository);
      final states = <NotificationCountState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationCountFetchRequested());
      await pumpEventQueue();

      expect(states, [
        const NotificationCountState(count: 0, isLoading: true),
        const NotificationCountState(count: 5, isLoading: false),
      ]);
      await bloc.close();
    });

    test('emits decremented count on NotificationCountDecremented', () async {
      final repository = _FakeNotificationRepository();
      final bloc = NotificationCountBloc(repository: repository);
      bloc.add(const NotificationCountUpdated(3));
      await pumpEventQueue();

      final states = <NotificationCountState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationCountDecremented());
      await pumpEventQueue();

      expect(states, [
        const NotificationCountState(count: 2),
      ]);
      await bloc.close();
    });

    test('emits 0 on NotificationCountReset', () async {
      final repository = _FakeNotificationRepository();
      final bloc = NotificationCountBloc(repository: repository);
      bloc.add(const NotificationCountUpdated(5));
      await pumpEventQueue();

      final states = <NotificationCountState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationCountReset());
      await pumpEventQueue();

      expect(states, [
        const NotificationCountState(count: 0),
      ]);
      await bloc.close();
    });
  });

  group('NotificationListBloc Tests', () {
    test('emits [Loading, Loaded] when NotificationListStarted succeeds', () async {
      final repository = _FakeNotificationRepository();
      final bloc = NotificationListBloc(repository: repository);
      final states = <NotificationListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationListStarted());
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0], isA<NotificationListLoading>());
      final loaded = states[1] as NotificationListLoaded;
      expect(loaded.notifications.length, 2);
      expect(loaded.localUnreadCount, 1);
      expect(loaded.hasReachedMax, true);
      await bloc.close();
    });

    test('emits [Loading, Error] when NotificationListStarted fails', () async {
      final repository = _FakeNotificationRepository(shouldThrow: true);
      final bloc = NotificationListBloc(repository: repository);
      final states = <NotificationListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationListStarted());
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0], isA<NotificationListLoading>());
      final errorState = states[1] as NotificationListError;
      expect(errorState.message, 'Gagal memuat daftar');
      await bloc.close();
    });

    test('updates activeFilter on NotificationListFilterChanged', () async {
      final repository = _FakeNotificationRepository();
      final bloc = NotificationListBloc(repository: repository);
      bloc.add(const NotificationListStarted());
      await pumpEventQueue();

      final states = <NotificationListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationListFilterChanged(NotificationFilterType.unread));
      await pumpEventQueue();

      expect(states.length, 1);
      final filtered = states[0] as NotificationListLoaded;
      expect(filtered.activeFilter, NotificationFilterType.unread);
      expect(filtered.displayedNotifications.length, 1);
      await bloc.close();
    });

    test('optimistically marks specific item as read on NotificationMarkAsReadRequested', () async {
      final repository = _FakeNotificationRepository();
      final bloc = NotificationListBloc(repository: repository);
      bloc.add(const NotificationListStarted());
      await pumpEventQueue();

      final states = <NotificationListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationMarkAsReadRequested('notif-1'));
      await pumpEventQueue();

      expect(states.length, 1);
      final loaded = states[0] as NotificationListLoaded;
      expect(loaded.notifications.firstWhere((n) => n.id == 'notif-1').isRead, true);
      await bloc.close();
    });

    test('optimistically marks all as read on NotificationMarkAllAsReadRequested', () async {
      final repository = _FakeNotificationRepository();
      final bloc = NotificationListBloc(repository: repository);
      bloc.add(const NotificationListStarted());
      await pumpEventQueue();

      final states = <NotificationListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const NotificationMarkAllAsReadRequested());
      await pumpEventQueue();

      expect(states.length, 2);
      final markingAll = states[0] as NotificationListLoaded;
      expect(markingAll.isMarkingAll, true);
      final finished = states[1] as NotificationListLoaded;
      expect(finished.isMarkingAll, false);
      expect(finished.localUnreadCount, 0);
      await bloc.close();
    });
  });
}
