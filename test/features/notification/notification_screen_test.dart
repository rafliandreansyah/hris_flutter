import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/pages/notification_screen.dart';

class _MockNotificationRepository implements NotificationRepository {
  List<NotificationItemModel> items;
  bool shouldFail;

  _MockNotificationRepository({
    List<NotificationItemModel>? items,
    this.shouldFail = false,
  }) : items = items ?? [
          const NotificationItemModel(
            id: 'notif-1',
            title: 'Pengajuan Cuti Disetujui',
            body: 'Cuti tahunan Anda untuk tanggal 20 September telah disetujui.',
            type: 'leave_request',
            isRead: false,
            createdAt: '2026-09-12T10:00:00Z',
          ),
          const NotificationItemModel(
            id: 'notif-2',
            title: 'Lembur Dikonfirmasi',
            body: 'Pengajuan lembur Anda telah diverifikasi oleh atasan.',
            type: 'overtime_request',
            isRead: true,
            createdAt: '2026-09-11T16:00:00Z',
          ),
        ];

  @override
  Future<NotificationUnreadCountResponse> getUnreadCount() async {
    return const NotificationUnreadCountResponse(
      success: true,
      message: 'OK',
      unreadCount: 1,
    );
  }

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    if (shouldFail) {
      throw const ApiException(message: 'Server sedang sibuk');
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
    items = items.map((i) => i.copyWith(isRead: true)).toList();
    return const NotificationMarkReadAllResponse(
      success: true,
      message: 'OK',
      updatedCount: 1,
    );
  }

  @override
  Future<NotificationMarkReadResponse> markAsRead(String id) async {
    items = items
        .map((i) => i.id == id ? i.copyWith(isRead: true) : i)
        .toList();
    return NotificationMarkReadResponse(
      success: true,
      message: 'OK',
      id: id,
    );
  }
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('NotificationScreen Widget Tests', () {
    testWidgets('renders AppBar and notification items correctly', (tester) async {
      final repo = _MockNotificationRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Pemberitahuan aktivitas & pengumuman'), findsOneWidget);
      expect(find.text('Tandai Dibaca'), findsOneWidget);

      // Check Filter Chips
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Belum Dibaca'), findsOneWidget);

      // Check Notification Items
      expect(find.text('Pengajuan Cuti Disetujui'), findsOneWidget);
      expect(find.text('Cuti & Izin'), findsOneWidget);
      expect(find.text('Lembur Dikonfirmasi'), findsOneWidget);
      expect(find.text('Lembur'), findsOneWidget);
    });

    testWidgets('switching to Belum Dibaca filters items', (tester) async {
      final repo = _MockNotificationRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Both items visible initially
      expect(find.text('Pengajuan Cuti Disetujui'), findsOneWidget);
      expect(find.text('Lembur Dikonfirmasi'), findsOneWidget);

      // Tap 'Belum Dibaca' filter
      await tester.tap(find.text('Belum Dibaca'));
      await tester.pumpAndSettle();

      // Only unread item visible
      expect(find.text('Pengajuan Cuti Disetujui'), findsOneWidget);
      expect(find.text('Lembur Dikonfirmasi'), findsNothing);
    });

    testWidgets('tapping Tandai Dibaca marks all items as read', (tester) async {
      final repo = _MockNotificationRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final markAllBtn = find.byKey(const ValueKey('mark_all_read_btn'));
      expect(markAllBtn, findsOneWidget);

      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      // After marking all as read, 'Belum Dibaca' count is 0 and empty state displays when clicked
      await tester.tap(find.text('Belum Dibaca'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Notifikasi Baru'), findsOneWidget);
    });

    testWidgets('displays error view and retries on failure', (tester) async {
      final repo = _MockNotificationRepository(shouldFail: true);

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Notifikasi'), findsOneWidget);
      expect(find.text('Server sedang sibuk'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Fix failure and tap retry
      repo.shouldFail = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Cuti Disetujui'), findsOneWidget);
    });
  });
}
