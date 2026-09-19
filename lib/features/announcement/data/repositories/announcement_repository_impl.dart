import 'package:hris_flutter/features/announcement/data/datasources/announcement_remote_datasource.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementRemoteDataSource _remoteDataSource;

  AnnouncementRepositoryImpl({AnnouncementRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? AnnouncementRemoteDataSourceImpl();

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) {
    return _remoteDataSource.getAnnouncements(
      page: page,
      size: size,
      search: search,
      category: category,
      priority: priority,
    );
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) {
    return _remoteDataSource.getAnnouncementDetail(id);
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(String id) {
    return _remoteDataSource.acknowledgeAnnouncement(id);
  }
}
