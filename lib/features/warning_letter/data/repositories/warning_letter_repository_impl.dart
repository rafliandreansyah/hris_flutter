import 'package:hris_flutter/features/warning_letter/data/datasources/warning_letter_remote_datasource.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';

class WarningLetterRepositoryImpl implements WarningLetterRepository {
  final WarningLetterRemoteDataSource _remoteDataSource;

  WarningLetterRepositoryImpl({
    WarningLetterRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? WarningLetterRemoteDataSourceImpl();

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
  }) {
    return _remoteDataSource.getWarningLetters(
      page: page,
      size: size,
      letterTypeId: letterTypeId,
      status: status,
      search: search,
      approver: approver,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() {
    return _remoteDataSource.getWarningLetterTypes();
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) {
    return _remoteDataSource.getLastWarningLetter(employeeId);
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) {
    return _remoteDataSource.createWarningLetter(request);
  }

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) {
    return _remoteDataSource.getWarningLetterDetail(id);
  }
}
