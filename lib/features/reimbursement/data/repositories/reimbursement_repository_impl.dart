import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/reimbursement/data/datasources/reimbursement_remote_datasource.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';

class ReimbursementRepositoryImpl implements ReimbursementRepository {
  final ReimbursementRemoteDataSource _remoteDataSource;

  ReimbursementRepositoryImpl({
    ReimbursementRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? ReimbursementRemoteDataSourceImpl();

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
  }) {
    return _remoteDataSource.getExpensesFeed(
      page: page,
      size: size,
      approver: approver,
      type: type,
      status: status,
      search: search,
      startDate: startDate,
      endDate: endDate,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
    );
  }

  @override
  Future<List<ReimbursementCategoryModel>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<ReimbursementDetailModel> getReimbursementDetail(String id) {
    return _remoteDataSource.getReimbursementDetail(id);
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
  }) {
    return _remoteDataSource.createReimbursement(
      title: title,
      description: description,
      type: type,
      cashAdvanceId: cashAdvanceId,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      bankAccountHolder: bankAccountHolder,
      items: items,
      file: file,
      files: files,
    );
  }

  @override
  Future<void> approveReimbursement({
    required String id,
    required bool isApproved,
    String? approverNotes,
    String? rejectionReason,
  }) {
    return _remoteDataSource.approveReimbursement(
      id: id,
      isApproved: isApproved,
      approverNotes: approverNotes,
      rejectionReason: rejectionReason,
    );
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
  }) {
    return _remoteDataSource.disburseReimbursement(
      id: id,
      disbursementMethod: disbursementMethod,
      paymentReference: paymentReference,
      notes: notes,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      bankAccountHolder: bankAccountHolder,
      payrollPeriodId: payrollPeriodId,
      proofFile: proofFile,
    );
  }

  @override
  Future<CashAdvanceDetailModel> getCashAdvanceDetail(String id) {
    return _remoteDataSource.getCashAdvanceDetail(id);
  }

  @override
  Future<String> createCashAdvance({
    required String title,
    required String purpose,
    required double requestedAmount,
    String? settlementDeadline,
  }) {
    return _remoteDataSource.createCashAdvance(
      title: title,
      purpose: purpose,
      requestedAmount: requestedAmount,
      settlementDeadline: settlementDeadline,
    );
  }

  @override
  Future<void> approveCashAdvance({
    required String id,
    required bool isApproved,
    double? approvedAmount,
    String? approverNotes,
  }) {
    return _remoteDataSource.approveCashAdvance(
      id: id,
      isApproved: isApproved,
      approvedAmount: approvedAmount,
      approverNotes: approverNotes,
    );
  }

  @override
  Future<void> disburseCashAdvance({
    required String id,
    required String disbursementMethod,
    String? disbursementNotes,
    XFile? proofFile,
  }) {
    return _remoteDataSource.disburseCashAdvance(
      id: id,
      disbursementMethod: disbursementMethod,
      disbursementNotes: disbursementNotes,
      proofFile: proofFile,
    );
  }

  @override
  Future<void> refundCashAdvance({
    required String id,
    required double amount,
    required String method,
    String? refundDate,
    String? notes,
    XFile? proofFile,
  }) {
    return _remoteDataSource.refundCashAdvance(
      id: id,
      amount: amount,
      method: method,
      refundDate: refundDate,
      notes: notes,
      proofFile: proofFile,
    );
  }
}
