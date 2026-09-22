import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';

abstract class ReimbursementRemoteDataSource {
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

  Future<List<ReimbursementCategoryModel>> getCategories();

  Future<ReimbursementDetailModel> getReimbursementDetail(String id);

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

  Future<void> approveReimbursement({
    required String id,
    required bool isApproved,
    String? approverNotes,
    String? rejectionReason,
  });

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

  Future<CashAdvanceDetailModel> getCashAdvanceDetail(String id);

  Future<String> createCashAdvance({
    required String title,
    required String purpose,
    required double requestedAmount,
    String? settlementDeadline,
  });

  Future<void> approveCashAdvance({
    required String id,
    required bool isApproved,
    double? approvedAmount,
    String? approverNotes,
  });

  Future<void> disburseCashAdvance({
    required String id,
    required String disbursementMethod,
    String? disbursementNotes,
    XFile? proofFile,
  });

  Future<void> refundCashAdvance({
    required String id,
    required double amount,
    required String method,
    String? refundDate,
    String? notes,
    XFile? proofFile,
  });
}

class ReimbursementRemoteDataSourceImpl
    implements ReimbursementRemoteDataSource {
  final ApiClient _apiClient;

  ReimbursementRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

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
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'size': size.toString(),
        'approver': approver.toString(),
      };

      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (companyId != null && companyId.isNotEmpty) {
        queryParams['companyId'] = companyId;
      }
      if (departmentId != null && departmentId.isNotEmpty) {
        queryParams['departmentId'] = departmentId;
      }
      if (positionId != null && positionId.isNotEmpty) {
        queryParams['positionId'] = positionId;
      }

      final response = await _apiClient.get(
        ApiEndpoints.expensesFeed,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ExpensesFeedResponseModel.fromJson(data);
      }
      throw const ApiException(
        message: 'Format data respons feed pengeluaran tidak valid',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<ReimbursementCategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reimbursementCategories,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final rawList = data['data'] as List<dynamic>;
        return rawList
            .whereType<Map<String, dynamic>>()
            .map(ReimbursementCategoryModel.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ReimbursementDetailModel> getReimbursementDetail(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reimbursementDetail(id),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return ReimbursementDetailModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(
        message: 'Format data detail reimbursement tidak valid',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
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
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('title', title),
        if (description != null && description.isNotEmpty)
          MapEntry('description', description),
        MapEntry('type', type),
        if (cashAdvanceId != null && cashAdvanceId.isNotEmpty)
          MapEntry('cashAdvanceId', cashAdvanceId),
        if (bankName != null && bankName.isNotEmpty)
          MapEntry('bankName', bankName),
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty)
          MapEntry('bankAccountNumber', bankAccountNumber),
        if (bankAccountHolder != null && bankAccountHolder.isNotEmpty)
          MapEntry('bankAccountHolder', bankAccountHolder),
        MapEntry('items', jsonEncode(items)),
      ]);

      if (file != null) {
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(
              file.path,
              filename: file.name,
            ),
          ),
        );
      }

      if (files != null && files.isNotEmpty) {
        for (final f in files) {
          formData.files.add(
            MapEntry(
              'files',
              await MultipartFile.fromFile(
                f.path,
                filename: f.name,
              ),
            ),
          );
        }
      }

      final response = await _apiClient.post(
        ApiEndpoints.reimbursements,
        data: formData,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return (data['data']['claimNumber'] ?? data['data']['id']).toString();
      }
      return 'Klaim Berhasil Diajukan';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> approveReimbursement({
    required String id,
    required bool isApproved,
    String? approverNotes,
    String? rejectionReason,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.reimbursementApprove(id),
        data: {
          'isApproved': isApproved,
          if (approverNotes != null && approverNotes.isNotEmpty)
            'approverNotes': approverNotes,
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'rejectionReason': rejectionReason,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
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
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('disbursementMethod', disbursementMethod),
        if (paymentReference != null && paymentReference.isNotEmpty)
          MapEntry('paymentReference', paymentReference),
        if (notes != null && notes.isNotEmpty) MapEntry('notes', notes),
        if (bankName != null && bankName.isNotEmpty)
          MapEntry('bankName', bankName),
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty)
          MapEntry('bankAccountNumber', bankAccountNumber),
        if (bankAccountHolder != null && bankAccountHolder.isNotEmpty)
          MapEntry('bankAccountHolder', bankAccountHolder),
        if (payrollPeriodId != null && payrollPeriodId.isNotEmpty)
          MapEntry('payrollPeriodId', payrollPeriodId),
      ]);

      if (proofFile != null) {
        formData.files.add(
          MapEntry(
            'proofFile',
            await MultipartFile.fromFile(
              proofFile.path,
              filename: proofFile.name,
            ),
          ),
        );
      }

      await _apiClient.patch(
        ApiEndpoints.reimbursementDisburse(id),
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<CashAdvanceDetailModel> getCashAdvanceDetail(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.cashAdvanceDetail(id),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return CashAdvanceDetailModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(
        message: 'Format data detail kasbon tidak valid',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> createCashAdvance({
    required String title,
    required String purpose,
    required double requestedAmount,
    String? settlementDeadline,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.cashAdvances,
        data: {
          'title': title,
          'purpose': purpose,
          'requestedAmount': requestedAmount,
          if (settlementDeadline != null && settlementDeadline.isNotEmpty)
            'settlementDeadline': settlementDeadline,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return (data['data']['advanceNumber'] ?? data['data']['id']).toString();
      }
      return 'Kasbon Berhasil Diajukan';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> approveCashAdvance({
    required String id,
    required bool isApproved,
    double? approvedAmount,
    String? approverNotes,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.cashAdvanceApprove(id),
        data: {
          'isApproved': isApproved,
          'approvedAmount': ?approvedAmount,
          if (approverNotes != null && approverNotes.isNotEmpty)
            'approverNotes': approverNotes,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> disburseCashAdvance({
    required String id,
    required String disbursementMethod,
    String? disbursementNotes,
    XFile? proofFile,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('disbursementMethod', disbursementMethod),
        if (disbursementNotes != null && disbursementNotes.isNotEmpty)
          MapEntry('disbursementNotes', disbursementNotes),
      ]);

      if (proofFile != null) {
        formData.files.add(
          MapEntry(
            'proofFile',
            await MultipartFile.fromFile(
              proofFile.path,
              filename: proofFile.name,
            ),
          ),
        );
      }

      await _apiClient.patch(
        ApiEndpoints.cashAdvanceDisburse(id),
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
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
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('amount', amount.toString()),
        MapEntry('method', method),
        if (refundDate != null && refundDate.isNotEmpty)
          MapEntry('refundDate', refundDate),
        if (notes != null && notes.isNotEmpty) MapEntry('notes', notes),
      ]);

      if (proofFile != null) {
        formData.files.add(
          MapEntry(
            'proofFile',
            await MultipartFile.fromFile(
              proofFile.path,
              filename: proofFile.name,
            ),
          ),
        );
      }

      await _apiClient.post(
        ApiEndpoints.cashAdvanceRefund(id),
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
