import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';

abstract class WarningLetterRemoteDataSource {
  Future<WarningLetterListResponse> getWarningLetters({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  });

  Future<List<WarningLetterTypeModel>> getWarningLetterTypes();

  /// Mengambil surat peringatan terakhir seorang pegawai.
  /// Mengembalikan null jika pegawai belum memiliki riwayat SP atau status 404 Not Found.
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId);

  /// Menerbitkan surat peringatan baru ke `POST /warning-letter`.
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  );

  /// Mengambil rincian surat peringatan berdasarkan ID.
  Future<WarningLetterDetail> getWarningLetterDetail(String id);
}

class WarningLetterRemoteDataSourceImpl
    implements WarningLetterRemoteDataSource {
  final ApiClient _apiClient;

  WarningLetterRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<WarningLetterListResponse> getWarningLetters({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'size': size,
      'approver': approver,
    };

    if (letterTypeId != null && letterTypeId.trim().isNotEmpty) {
      queryParams['letterTypeId'] = letterTypeId.trim();
    }

    if (status != null && status.trim().isNotEmpty && status != 'all') {
      queryParams['status'] = status.trim();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }

    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.warningLetter,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return WarningLetterListResponse.fromJson(data);
    }

    throw Exception('Format data response tidak valid.');
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async {
    final response = await _apiClient.get(ApiEndpoints.warningLetterType);
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final listData = data['data'];
      if (listData is List) {
        return listData
            .whereType<Map<String, dynamic>>()
            .map((e) => WarningLetterTypeModel.fromJson(e))
            .toList();
      }
    } else if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => WarningLetterTypeModel.fromJson(e))
          .toList();
    }

    return [];
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(
    String employeeId,
  ) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.lastWarningLetterByEmployee(employeeId),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final letterData = data['data'];
        if (letterData is Map<String, dynamic>) {
          return LastWarningLetterModel.fromJson(letterData);
        }
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    final formData = await request.toFormData();
    final response = await _apiClient.post(
      ApiEndpoints.warningLetter,
      data: formData,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CreateWarningLetterResponse.fromJson(data);
    }

    throw Exception('Format data response tidak valid.');
  }

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.warningLetterDetail(id),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final detailResponse = WarningLetterDetailResponse.fromJson(data);
      return detailResponse.data;
    }

    throw Exception('Format data detail surat peringatan tidak valid.');
  }
}
