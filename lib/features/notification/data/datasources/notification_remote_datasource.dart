import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';

abstract class NotificationRemoteDataSource {
  /// Mengambil jumlah notifikasi yang belum dibaca dari `GET /notifications/unread-count`.
  Future<NotificationUnreadCountResponse> getUnreadCount();

  /// Mengambil daftar notifikasi pengguna saat ini dari `GET /notifications`.
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  });

  /// Menandai semua notifikasi pengguna saat ini sebagai sudah dibaca via `PATCH /notifications/read-all`.
  Future<NotificationMarkReadAllResponse> markAllAsRead();

  /// Menandai satu notifikasi spesifik sebagai sudah dibaca via `PATCH /notifications/{id}/read`.
  Future<NotificationMarkReadResponse> markAsRead(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<NotificationUnreadCountResponse> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notificationsUnreadCount,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NotificationUnreadCountResponse.fromJson(data);
      }
      throw const ApiException(
        message: 'Format data jumlah notifikasi tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat jumlah notifikasi: $e');
    }
  }

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NotificationListResponse.fromJson(data);
      }
      throw const ApiException(
        message: 'Format data daftar notifikasi tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat daftar notifikasi: $e');
    }
  }

  @override
  Future<NotificationMarkReadAllResponse> markAllAsRead() async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.notificationsReadAll,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NotificationMarkReadAllResponse.fromJson(data);
      }
      throw const ApiException(
        message: 'Format respon pembacaan notifikasi tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menandai semua notifikasi dibaca: $e');
    }
  }

  @override
  Future<NotificationMarkReadResponse> markAsRead(String id) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.notificationRead(id),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NotificationMarkReadResponse.fromJson(data);
      }
      throw const ApiException(
        message: 'Format respon pembacaan notifikasi tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menandai notifikasi dibaca: $e');
    }
  }
}
