import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/datasources/reimbursement_remote_datasource.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:image_picker/image_picker.dart';

class _MockReimbursementRemoteDataSource implements ReimbursementRemoteDataSource {
  @override
  Future<void> deleteReimbursement(String id) async {}

  @override
  Future<void> deleteCashAdvance(String id) async {}

  int getExpensesFeedCallCount = 0;
  int getCategoriesCallCount = 0;
  int getReimbursementDetailCallCount = 0;
  int createReimbursementCallCount = 0;
  int approveReimbursementCallCount = 0;
  int disburseReimbursementCallCount = 0;
  int getCashAdvanceDetailCallCount = 0;
  int createCashAdvanceCallCount = 0;
  int approveCashAdvanceCallCount = 0;
  int disburseCashAdvanceCallCount = 0;
  int refundCashAdvanceCallCount = 0;

  dynamic mockExpensesFeedResult;
  List<ReimbursementCategoryModel> mockCategoriesResult = [];
  dynamic mockReimbursementDetailResult;
  String mockCreateReimbursementResult = 'CLM-001';
  dynamic mockCashAdvanceDetailResult;
  String mockCreateCashAdvanceResult = 'CA-001';

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
    getExpensesFeedCallCount++;
    return mockExpensesFeedResult as ExpensesFeedResponseModel;
  }

  @override
  Future<List<ReimbursementCategoryModel>> getCategories() async {
    getCategoriesCallCount++;
    return mockCategoriesResult;
  }

  @override
  Future<ReimbursementDetailModel> getReimbursementDetail(String id) async {
    getReimbursementDetailCallCount++;
    return mockReimbursementDetailResult as ReimbursementDetailModel;
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
    createReimbursementCallCount++;
    return mockCreateReimbursementResult;
  }

  @override
  Future<void> approveReimbursement({
    required String id,
    required bool isApproved,
    String? approverNotes,
    String? rejectionReason,
  }) async {
    approveReimbursementCallCount++;
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
    disburseReimbursementCallCount++;
  }

  @override
  Future<CashAdvanceDetailModel> getCashAdvanceDetail(String id) async {
    getCashAdvanceDetailCallCount++;
    return mockCashAdvanceDetailResult as CashAdvanceDetailModel;
  }

  @override
  Future<String> createCashAdvance({
    required String title,
    required String purpose,
    required double requestedAmount,
    String? settlementDeadline,
  }) async {
    createCashAdvanceCallCount++;
    return mockCreateCashAdvanceResult;
  }

  @override
  Future<void> approveCashAdvance({
    required String id,
    required bool isApproved,
    double? approvedAmount,
    String? approverNotes,
  }) async {
    approveCashAdvanceCallCount++;
  }

  @override
  Future<void> disburseCashAdvance({
    required String id,
    required String disbursementMethod,
    String? disbursementNotes,
    XFile? proofFile,
  }) async {
    disburseCashAdvanceCallCount++;
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
    refundCashAdvanceCallCount++;
  }
}

void main() {
  group('ReimbursementRepositoryImpl Tests', () {
    late _MockReimbursementRemoteDataSource mockRemoteDataSource;
    late ReimbursementRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockReimbursementRemoteDataSource();
      repository = ReimbursementRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getExpensesFeed delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockExpensesFeedResult = ExpensesFeedResponseModel.fromJson({
        'data': [
          {
            'id': 'exp-1',
            'referenceNumber': 'CLM-001',
            'expenseType': 'reimbursement',
            'title': 'Bensin',
            'requestedAmount': 100000.0,
            'status': 'requested',
            'createdAt': '2026-10-15T08:00:00Z',
            'employee': {'id': 'emp-1', 'firstName': 'Budi'},
          }
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getExpensesFeed(page: 1, size: 10);

      expect(mockRemoteDataSource.getExpensesFeedCallCount, equals(1));
      expect(result.items.first.referenceNumber, equals('CLM-001'));
    });

    test('getCategories delegates to remote data source', () async {
      mockRemoteDataSource.mockCategoriesResult = [
        ReimbursementCategoryModel.fromJson({
          'id': 'cat-1',
          'companyId': 'comp-1',
          'name': 'Transportasi',
          'code': 'TRN',
          'limitType': 'fixed',
          'isActive': true,
        }),
      ];

      final result = await repository.getCategories();

      expect(mockRemoteDataSource.getCategoriesCallCount, equals(1));
      expect(result.length, equals(1));
      expect(result.first.name, equals('Transportasi'));
    });

    test('getReimbursementDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockReimbursementDetailResult =
          ReimbursementDetailModel.fromJson({
        'id': 'reimb-1',
        'claimNumber': 'CLM-001',
        'type': 'transport',
        'title': 'Perjalanan Dinas',
        'totalRequestedAmount': 250000.0,
        'status': 'requested',
        'createdAt': '2026-10-15T08:00:00Z',
        'employee': {'id': 'emp-1', 'firstName': 'Budi'},
      });

      final result = await repository.getReimbursementDetail('reimb-1');

      expect(mockRemoteDataSource.getReimbursementDetailCallCount, equals(1));
      expect(result.id, equals('reimb-1'));
      expect(result.claimNumber, equals('CLM-001'));
    });

    test('createReimbursement delegates to remote data source', () async {
      mockRemoteDataSource.mockCreateReimbursementResult = 'CLM-999';

      final result = await repository.createReimbursement(
        title: 'Tiket Kereta',
        type: 'transport',
        items: [
          {'categoryId': 'cat-1', 'amount': 250000}
        ],
      );

      expect(mockRemoteDataSource.createReimbursementCallCount, equals(1));
      expect(result, equals('CLM-999'));
    });

    test('approveReimbursement delegates to remote data source', () async {
      await repository.approveReimbursement(
        id: 'reimb-1',
        isApproved: true,
        approverNotes: 'Approved',
      );

      expect(mockRemoteDataSource.approveReimbursementCallCount, equals(1));
    });

    test('disburseReimbursement delegates to remote data source', () async {
      await repository.disburseReimbursement(
        id: 'reimb-1',
        disbursementMethod: 'bank_transfer',
        paymentReference: 'REF-123',
      );

      expect(mockRemoteDataSource.disburseReimbursementCallCount, equals(1));
    });

    test('getCashAdvanceDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockCashAdvanceDetailResult =
          CashAdvanceDetailModel.fromJson({
        'id': 'ca-1',
        'advanceNumber': 'CA-001',
        'title': 'Kasbon',
        'purpose': 'Dinas Luar Kota',
        'requestedAmount': 500000.0,
        'status': 'requested',
        'createdAt': '2026-10-15T08:00:00Z',
        'employee': {'id': 'emp-1', 'firstName': 'Budi'},
      });

      final result = await repository.getCashAdvanceDetail('ca-1');

      expect(mockRemoteDataSource.getCashAdvanceDetailCallCount, equals(1));
      expect(result.id, equals('ca-1'));
      expect(result.advanceNumber, equals('CA-001'));
    });

    test('createCashAdvance delegates to remote data source', () async {
      mockRemoteDataSource.mockCreateCashAdvanceResult = 'CA-999';

      final result = await repository.createCashAdvance(
        title: 'Kasbon Acara',
        purpose: 'Beli ATK',
        requestedAmount: 300000.0,
      );

      expect(mockRemoteDataSource.createCashAdvanceCallCount, equals(1));
      expect(result, equals('CA-999'));
    });

    test('approveCashAdvance delegates to remote data source', () async {
      await repository.approveCashAdvance(
        id: 'ca-1',
        isApproved: true,
        approvedAmount: 300000.0,
      );

      expect(mockRemoteDataSource.approveCashAdvanceCallCount, equals(1));
    });

    test('disburseCashAdvance delegates to remote data source', () async {
      await repository.disburseCashAdvance(
        id: 'ca-1',
        disbursementMethod: 'cash',
        disbursementNotes: 'Diserahkan langsung',
      );

      expect(mockRemoteDataSource.disburseCashAdvanceCallCount, equals(1));
    });

    test('refundCashAdvance delegates to remote data source', () async {
      await repository.refundCashAdvance(
        id: 'ca-1',
        amount: 50000.0,
        method: 'transfer',
        notes: 'Sisa dana',
      );

      expect(mockRemoteDataSource.refundCashAdvanceCallCount, equals(1));
    });
  });
}
