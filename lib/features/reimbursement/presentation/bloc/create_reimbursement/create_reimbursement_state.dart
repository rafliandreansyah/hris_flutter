import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';

class CreateReimbursementState extends Equatable {
  final List<ReimbursementCategoryModel> categories;
  final bool isCategoriesLoading;
  final String type; // 'out_of_pocket', 'cash_advance_settlement'
  final String? cashAdvanceId;
  final ExpenseFeedItemModel? selectedCashAdvance;
  final double? cashAdvanceNominal;
  final String? cashAdvanceNumber;
  final String? cashAdvanceTitle;
  final EmployeeDetailData? employeeDetail;
  final bool isEmployeeLoading;
  final List<Map<String, dynamic>> items;
  final XFile? file;
  final bool isSubmitting;
  final bool isSuccess;
  final String? createdClaimNumber;
  final String? errorMessage;

  const CreateReimbursementState({
    this.categories = const [],
    this.isCategoriesLoading = false,
    this.type = 'out_of_pocket',
    this.cashAdvanceId,
    this.selectedCashAdvance,
    this.cashAdvanceNominal,
    this.cashAdvanceNumber,
    this.cashAdvanceTitle,
    this.employeeDetail,
    this.isEmployeeLoading = false,
    this.items = const [],
    this.file,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.createdClaimNumber,
    this.errorMessage,
  });

  double get totalRequestedAmount {
    double total = 0.0;
    for (final item in items) {
      final amt = item['requestedAmount'];
      if (amt is num) {
        total += amt.toDouble();
      }
    }
    return total;
  }

  /// Perhitungan selisih kasbon (Settlement).
  /// diff = totalRequestedAmount - cashAdvanceNominal
  /// diff == 0 -> balanced (pas/impas)
  /// diff > 0 -> company_owes_employee (kurang bayar, kantor transfer ke karyawan)
  /// diff < 0 -> employee_owes_company (lebih bayar, karyawan kembalikan sisa)
  double? get settlementDifference {
    if (cashAdvanceNominal == null) return null;
    return totalRequestedAmount - cashAdvanceNominal!;
  }

  CreateReimbursementState copyWith({
    List<ReimbursementCategoryModel>? categories,
    bool? isCategoriesLoading,
    String? type,
    String? cashAdvanceId,
    bool clearCashAdvanceId = false,
    ExpenseFeedItemModel? selectedCashAdvance,
    bool clearSelectedCashAdvance = false,
    double? cashAdvanceNominal,
    String? cashAdvanceNumber,
    String? cashAdvanceTitle,
    EmployeeDetailData? employeeDetail,
    bool? isEmployeeLoading,
    List<Map<String, dynamic>>? items,
    XFile? file,
    bool clearFile = false,
    bool? isSubmitting,
    bool? isSuccess,
    String? createdClaimNumber,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CreateReimbursementState(
      categories: categories ?? this.categories,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      type: type ?? this.type,
      cashAdvanceId: clearCashAdvanceId ? null : (cashAdvanceId ?? this.cashAdvanceId),
      selectedCashAdvance: clearSelectedCashAdvance
          ? null
          : (selectedCashAdvance ?? this.selectedCashAdvance),
      cashAdvanceNominal: clearCashAdvanceId ? null : (cashAdvanceNominal ?? this.cashAdvanceNominal),
      cashAdvanceNumber: clearCashAdvanceId ? null : (cashAdvanceNumber ?? this.cashAdvanceNumber),
      cashAdvanceTitle: clearCashAdvanceId ? null : (cashAdvanceTitle ?? this.cashAdvanceTitle),
      employeeDetail: employeeDetail ?? this.employeeDetail,
      isEmployeeLoading: isEmployeeLoading ?? this.isEmployeeLoading,
      items: items ?? this.items,
      file: clearFile ? null : (file ?? this.file),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      createdClaimNumber: createdClaimNumber ?? this.createdClaimNumber,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        categories,
        isCategoriesLoading,
        type,
        cashAdvanceId,
        selectedCashAdvance,
        cashAdvanceNominal,
        cashAdvanceNumber,
        cashAdvanceTitle,
        employeeDetail,
        isEmployeeLoading,
        items,
        file,
        isSubmitting,
        isSuccess,
        createdClaimNumber,
        errorMessage,
      ];
}
