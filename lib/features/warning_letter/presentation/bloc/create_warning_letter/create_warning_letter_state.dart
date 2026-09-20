import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum CreateWarningLetterStatus {
  initial,
  loadingData,
  dataLoaded,
  submitting,
  success,
  failure,
}

class CreateWarningLetterState extends Equatable {
  final CreateWarningLetterStatus status;
  final List<EmployeeDirectoryItem> employees;
  final List<WarningLetterTypeModel> warningLetterTypes;

  final EmployeeDirectoryItem? selectedEmployee;
  final bool isLoadingLastLetter;
  final LastWarningLetterModel? lastWarningLetter;
  final bool hasLoadedLastLetter;

  final WarningLetterTypeModel? selectedType;
  final DateTime issuedDate;
  final String reason;
  final String sanction;

  final XFile? attachmentFile;
  final ImageCompressResult? compressResult;

  final CreateWarningLetterResponse? createdResponse;
  final String? errorMessage;

  CreateWarningLetterState({
    this.status = CreateWarningLetterStatus.initial,
    this.employees = const [],
    this.warningLetterTypes = const [],
    this.selectedEmployee,
    this.isLoadingLastLetter = false,
    this.lastWarningLetter,
    this.hasLoadedLastLetter = false,
    this.selectedType,
    DateTime? issuedDate,
    this.reason = '',
    this.sanction = '',
    this.attachmentFile,
    this.compressResult,
    this.createdResponse,
    this.errorMessage,
  }) : issuedDate = issuedDate ?? DateTime.now();

  /// Tanggal kedaluwarsa yang otomatis dihitung berdasarkan `issuedDate` + `validityPeriodMonths`.
  DateTime? get calculatedExpiredDate {
    if (selectedType == null || selectedType!.validityPeriodMonths <= 0) {
      return null;
    }
    final months = selectedType!.validityPeriodMonths;
    // Tambah bulan
    final newYear = issuedDate.year + ((issuedDate.month + months - 1) ~/ 12);
    final newMonth = ((issuedDate.month + months - 1) % 12) + 1;
    // Handle hari bulan seperti 31 ke 28/30
    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = issuedDate.day > lastDayOfNewMonth ? lastDayOfNewMonth : issuedDate.day;
    return DateTime(newYear, newMonth, newDay);
  }

  /// Format tanggal kedaluwarsa, contoh: "28 Februari 2027"
  String get formattedCalculatedExpiredDate {
    final exp = calculatedExpiredDate;
    if (exp == null) return '-';
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(exp);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy').format(exp);
      } catch (_) {
        return exp.toString();
      }
    }
  }

  /// Format 'yyyy-MM-dd' untuk query/form parameter API
  String get formattedIssuedDateParam {
    return '${issuedDate.year.toString().padLeft(4, '0')}-'
        '${issuedDate.month.toString().padLeft(2, '0')}-'
        '${issuedDate.day.toString().padLeft(2, '0')}';
  }

  /// Format tanggal terbit saat ini untuk tampilan form, contoh: "29 Agustus 2026"
  String get formattedIssuedDateDisplay {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(issuedDate);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy').format(issuedDate);
      } catch (_) {
        return issuedDate.toString();
      }
    }
  }

  bool get canSubmit =>
      selectedEmployee != null &&
      selectedType != null &&
      reason.trim().isNotEmpty &&
      status != CreateWarningLetterStatus.submitting;

  CreateWarningLetterState copyWith({
    CreateWarningLetterStatus? status,
    List<EmployeeDirectoryItem>? employees,
    List<WarningLetterTypeModel>? warningLetterTypes,
    EmployeeDirectoryItem? selectedEmployee,
    bool clearSelectedEmployee = false,
    bool? isLoadingLastLetter,
    LastWarningLetterModel? lastWarningLetter,
    bool clearLastWarningLetter = false,
    bool? hasLoadedLastLetter,
    WarningLetterTypeModel? selectedType,
    bool clearSelectedType = false,
    DateTime? issuedDate,
    String? reason,
    String? sanction,
    XFile? attachmentFile,
    bool clearAttachmentFile = false,
    ImageCompressResult? compressResult,
    bool clearCompressResult = false,
    CreateWarningLetterResponse? createdResponse,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CreateWarningLetterState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      warningLetterTypes: warningLetterTypes ?? this.warningLetterTypes,
      selectedEmployee: clearSelectedEmployee
          ? null
          : (selectedEmployee ?? this.selectedEmployee),
      isLoadingLastLetter: isLoadingLastLetter ?? this.isLoadingLastLetter,
      lastWarningLetter: clearLastWarningLetter
          ? null
          : (lastWarningLetter ?? this.lastWarningLetter),
      hasLoadedLastLetter: hasLoadedLastLetter ?? this.hasLoadedLastLetter,
      selectedType:
          clearSelectedType ? null : (selectedType ?? this.selectedType),
      issuedDate: issuedDate ?? this.issuedDate,
      reason: reason ?? this.reason,
      sanction: sanction ?? this.sanction,
      attachmentFile: clearAttachmentFile
          ? null
          : (attachmentFile ?? this.attachmentFile),
      compressResult: clearCompressResult
          ? null
          : (compressResult ?? this.compressResult),
      createdResponse: createdResponse ?? this.createdResponse,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        employees,
        warningLetterTypes,
        selectedEmployee,
        isLoadingLastLetter,
        lastWarningLetter,
        hasLoadedLastLetter,
        selectedType,
        issuedDate,
        reason,
        sanction,
        attachmentFile?.path,
        compressResult?.compressedSizeBytes,
        createdResponse,
        errorMessage,
      ];
}
