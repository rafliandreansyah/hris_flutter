import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';

abstract class AnnouncementRemoteDataSource {
  /// Mengambil daftar pengumuman dari `GET /announcement`.
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  });

  /// Mengambil detail pengumuman dari `GET /announcement/{id}`.
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id);

  /// Mengonfirmasi pembacaan pengumuman dari `POST /announcement/{id}/acknowledge`.
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(String id);
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  final ApiClient _apiClient;

  AnnouncementRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      if (category != null &&
          category.trim().isNotEmpty &&
          category.trim().toLowerCase() != 'all' &&
          category.trim().toLowerCase() != 'semua') {
        queryParams['category'] = category.trim();
      }

      if (priority != null &&
          priority.trim().isNotEmpty &&
          priority.trim().toLowerCase() != 'all' &&
          priority.trim().toLowerCase() != 'semua') {
        queryParams['priority'] = priority.trim();
      }

      final response = await _apiClient.get(
        ApiEndpoints.announcement,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AnnouncementListResponse.fromJson(data);
      }

      throw const ApiException(
        message: 'Format data pengumuman tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat pengumuman: $e');
    }
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.announcementDetail(id),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AnnouncementDetailResponse.fromJson(data);
      }

      throw const ApiException(
        message: 'Format detail pengumuman tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat detail pengumuman: $e');
    }
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(
    String id,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.announcementAcknowledge(id),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AnnouncementAcknowledgeResponse.fromJson(data);
      }

      throw const ApiException(
        message: 'Format respon konfirmasi pengumuman tidak valid.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal mengonfirmasi pengumuman: $e');
    }
  }
}
