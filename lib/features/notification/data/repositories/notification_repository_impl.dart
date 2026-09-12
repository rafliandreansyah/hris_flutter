import 'package:hris_flutter/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({
    NotificationRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? NotificationRemoteDataSourceImpl();

  @override
  Future<NotificationUnreadCountResponse> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.getNotifications(page: page, limit: limit);
  }

  @override
  Future<NotificationMarkReadAllResponse> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }

  @override
  Future<NotificationMarkReadResponse> markAsRead(String id) {
    return _remoteDataSource.markAsRead(id);
  }
}
