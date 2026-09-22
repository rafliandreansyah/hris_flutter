import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:image_picker/image_picker.dart';

class MockReimbursementRepository implements ReimbursementRepository {
  ExpensesFeedResponseModel? mockMyFeed;
  ExpensesFeedResponseModel? mockTeamFeed;
  List<ReimbursementCategoryModel> mockCategories = [];
  ReimbursementDetailModel? mockReimbursementDetail;
  CashAdvanceDetailModel? mockCashAdvanceDetail;
  String mockCreatedClaimNumber = 'CLM-TEST-001';
  String mockCreatedAdvanceNumber = 'ADV-TEST-001';

  ApiException? errorToThrow;
  bool teamForbidden = false;

  int lastFeedPage = 0;
  bool lastFeedApprover = false;
  String? lastFeedSearch;
  String? lastFeedType;
  String? lastFeedStatus;

  bool lastApproveAction = false;
  String? lastApproverNotes;
  String? lastDisbursementMethod;
  double? lastRefundAmount;

  @override
  Future<ExpensesFeedResponseModel> getExpensesFeed({
    required int page,
    required int size,
    bool approver = false,
    String? type,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
    String? companyId,
    String? departmentId,
    String? positionId,
  }) async {
    lastFeedPage = page;
    lastFeedApprover = approver;
    lastFeedSearch = search;
    lastFeedType = type;
    lastFeedStatus = status;

    if (errorToThrow != null) throw errorToThrow!;
    if (approver && teamForbidden) {
      throw const ApiException(
        message: 'Akses ditolak untuk pengajuan bawahan',
        statusCode: 403,
      );
    }

    if (approver) {
      return mockTeamFeed ??
          const ExpensesFeedResponseModel(
            items: [],
            meta: ExpensesPaginationMeta(
              page: 1,
              limit: 10,
              total: 0,
              totalPages: 1,
            ),
          );
    }

    return mockMyFeed ??
        const ExpensesFeedResponseModel(
          items: [],
          meta: ExpensesPaginationMeta(
            page: 1,
            limit: 10,
            total: 0,
            totalPages: 1,
          ),
        );
  }

  @override
  Future<List<ReimbursementCategoryModel>> getCategories() async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockCategories;
  }

  @override
  Future<ReimbursementDetailModel> getReimbursementDetail(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    if (mockReimbursementDetail != null) return mockReimbursementDetail!;
    throw const ApiException(message: 'Reimbursement not found', statusCode: 404);
  }

  @override
  Future<String> createReimbursement({
    required String title,
    String? description,
    required String type,
    String? cashAdvanceId,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    required List<Map<String, dynamic>> items,
    XFile? file,
    List<XFile>? files,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockCreatedClaimNumber;
  }

  @override
  Future<void> approveReimbursement({
    required String id,
    required bool isApproved,
    String? approverNotes,
    String? rejectionReason,
  }) async {
    lastApproveAction = isApproved;
    lastApproverNotes = approverNotes ?? rejectionReason;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> disburseReimbursement({
    required String id,
    required String disbursementMethod,
    String? paymentReference,
    String? notes,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    String? payrollPeriodId,
    XFile? proofFile,
  }) async {
    lastDisbursementMethod = disbursementMethod;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<CashAdvanceDetailModel> getCashAdvanceDetail(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    if (mockCashAdvanceDetail != null) return mockCashAdvanceDetail!;
    throw const ApiException(message: 'Cash advance not found', statusCode: 404);
  }

  @override
  Future<String> createCashAdvance({
    required String title,
    required String purpose,
    required double requestedAmount,
    String? settlementDeadline,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockCreatedAdvanceNumber;
  }

  @override
  Future<void> approveCashAdvance({
    required String id,
    required bool isApproved,
    double? approvedAmount,
    String? approverNotes,
  }) async {
    lastApproveAction = isApproved;
    lastApproverNotes = approverNotes;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> disburseCashAdvance({
    required String id,
    required String disbursementMethod,
    String? disbursementNotes,
    XFile? proofFile,
  }) async {
    lastDisbursementMethod = disbursementMethod;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> refundCashAdvance({
    required String id,
    required double amount,
    required String method,
    String? refundDate,
    String? notes,
    XFile? proofFile,
  }) async {
    lastRefundAmount = amount;
    if (errorToThrow != null) throw errorToThrow!;
  }
}
