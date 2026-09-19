import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';

abstract class AnnouncementRepository {
  /// Mengambil daftar pengumuman berpaginasi dengan filter opsional.
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  });

  /// Mengambil detail pengumuman spesifik berdasarkan ID.
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id);

  /// Mengonfirmasi pembacaan pengumuman yang mewajibkan konfirmasi.
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(String id);
}
