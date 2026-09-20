import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';

abstract class WarningLetterRepository {
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

  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId);

  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  );

  Future<WarningLetterDetail> getWarningLetterDetail(String id);
}
