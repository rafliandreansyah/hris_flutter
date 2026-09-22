import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';

/// Kontrak Repository Domain untuk Modul Reimbursement, Kasbon, dan Pencairan Dana.
abstract class ReimbursementRepository {
  /// Mengambil daftar transaksi pengeluaran (reimbursement dan kasbon)
  /// dari endpoint `GET /expenses`.
  ///
  /// [approver] `false` = Tab "Pengajuan Saya", `true` = Tab "Bawahan".
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
  });

  /// Mengambil master kategori biaya aktif dari `GET /reimbursements/categories`.
  Future<List<ReimbursementCategoryModel>> getCategories();

  /// Mengambil detail pengajuan reimbursement dari `GET /reimbursements/{id}`.
  Future<ReimbursementDetailModel> getReimbursementDetail(String id);

  /// Membuat permohonan klaim reimbursement baru ke `POST /reimbursements`.
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
  });

  /// Menyetujui atau menolak permohonan klaim reimbursement pada `PATCH /reimbursements/{id}/approve`.
  Future<void> approveReimbursement({
    required String id,
    required bool isApproved,
    String? approverNotes,
    String? rejectionReason,
  });

  /// Mencairkan dana reimbursement oleh kasir/finance pada `PATCH /reimbursements/{id}/disburse`
  /// atau `POST /finance/disbursements/{id}`.
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
  });

  /// Mengambil detail kasbon dari `GET /cash-advances/{id}`.
  Future<CashAdvanceDetailModel> getCashAdvanceDetail(String id);

  /// Membuat permohonan kasbon baru ke `POST /cash-advances`.
  Future<String> createCashAdvance({
    required String title,
    required String purpose,
    required double requestedAmount,
    String? settlementDeadline,
  });

  /// Menyetujui atau menolak permohonan kasbon pada `PATCH /cash-advances/{id}/approve`.
  Future<void> approveCashAdvance({
    required String id,
    required bool isApproved,
    double? approvedAmount,
    String? approverNotes,
  });

  /// Mencairkan dana kasbon pada `PATCH /cash-advances/{id}/disburse`.
  Future<void> disburseCashAdvance({
    required String id,
    required String disbursementMethod,
    String? disbursementNotes,
    XFile? proofFile,
  });

  /// Menyerahkan bukti refund/pengembalian sisa kasbon pada `POST /cash-advances/{id}/refund`.
  Future<void> refundCashAdvance({
    required String id,
    required double amount,
    required String method,
    String? refundDate,
    String? notes,
    XFile? proofFile,
  });
}
