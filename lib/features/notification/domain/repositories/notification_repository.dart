import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';

abstract class NotificationRepository {
  /// Mengambil jumlah notifikasi yang belum dibaca dari backend.
  Future<NotificationUnreadCountResponse> getUnreadCount();

  /// Mengambil daftar notifikasi pengguna terpaginasi.
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  });

  /// Menandai seluruh notifikasi pengguna saat ini sebagai telah dibaca.
  Future<NotificationMarkReadAllResponse> markAllAsRead();

  /// Menandai satu notifikasi spesifik sebagai telah dibaca.
  Future<NotificationMarkReadResponse> markAsRead(String id);
}
