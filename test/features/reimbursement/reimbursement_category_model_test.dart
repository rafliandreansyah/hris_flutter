import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';

void main() {
  group('Reimbursement Category Model Tests', () {
    test('ReimbursementCategoryModel fromJson full fields', () {
      final json = {
        'id': 'cat-01',
        'companyId': 'comp-01',
        'name': 'Transportasi & Bensin',
        'code': 'TRANSPORT',
        'description': 'Klaim biaya bensin operasional dan tol',
        'limitType': 'monthly',
        'defaultLimit': 1500000.0,
        'receiptMaxAgeDays': 14,
        'isActive': true,
      };

      final model = ReimbursementCategoryModel.fromJson(json);
      expect(model.id, 'cat-01');
      expect(model.companyId, 'comp-01');
      expect(model.name, 'Transportasi & Bensin');
      expect(model.code, 'TRANSPORT');
      expect(model.description, 'Klaim biaya bensin operasional dan tol');
      expect(model.limitType, 'monthly');
      expect(model.defaultLimit, 1500000.0);
      expect(model.receiptMaxAgeDays, 14);
      expect(model.isActive, true);
    });

    test('ReimbursementCategoryModel fallback defaults on minimal json', () {
      final json = {
        'id': 'cat-02',
        'name': 'Akomodasi',
      };

      final model = ReimbursementCategoryModel.fromJson(json);
      expect(model.id, 'cat-02');
      expect(model.name, 'Akomodasi');
      expect(model.companyId, '');
      expect(model.code, '');
      expect(model.description, isNull);
      expect(model.limitType, 'unlimited');
      expect(model.defaultLimit, isNull);
      expect(model.receiptMaxAgeDays, isNull);
      expect(model.isActive, true);
    });
  });

  group('Expense Item View Model & Formatters Tests', () {
    test('formatRupiah formatting', () {
      expect(formatRupiah(null), 'Rp 0');
      expect(formatRupiah(0), 'Rp 0');
      // Format 500000 with id_ID currency formatter
      final formatted = formatRupiah(500000);
      expect(formatted.startsWith('Rp'), true);
      expect(formatted.contains('500'), true);
    });

    test('ExpenseStatusExtension labels and colors', () {
      for (final st in ExpenseStatus.values) {
        expect(st.label.isNotEmpty, true);
        expect(st.tone, isA<AppStatusTone>());
      }
      expect(ExpenseStatus.requested.label, 'Menunggu Persetujuan');
      expect(ExpenseStatus.approved.label, 'Disetujui');
      expect(ExpenseStatus.disbursed.label, 'Dicairkan');
      expect(ExpenseStatus.settlementInProgress.label, 'Proses Penyelesaian');
      expect(ExpenseStatus.settled.label, 'Selesai');
      expect(ExpenseStatus.rejected.label, 'Ditolak');
    });

    test('parseExpenseStatus string conversion', () {
      expect(parseExpenseStatus('approved'), ExpenseStatus.approved);
      expect(parseExpenseStatus('disbursed'), ExpenseStatus.disbursed);
      expect(parseExpenseStatus('settlement_in_progress'), ExpenseStatus.settlementInProgress);
      expect(parseExpenseStatus('settled'), ExpenseStatus.settled);
      expect(parseExpenseStatus('rejected'), ExpenseStatus.rejected);
      expect(parseExpenseStatus('requested'), ExpenseStatus.requested);
      expect(parseExpenseStatus('pending'), ExpenseStatus.requested);
      expect(parseExpenseStatus(null), ExpenseStatus.requested);
      expect(parseExpenseStatus('unknown_status'), ExpenseStatus.requested);
    });

    test('formatDisbursementMethod conversion', () {
      expect(formatDisbursementMethod('manual_transfer'), 'Transfer Bank');
      expect(formatDisbursementMethod('cash'), 'Uang Tunai (Petty Cash)');
      expect(formatDisbursementMethod('payroll'), 'Masuk Payroll');
      expect(formatDisbursementMethod('payment_gateway'), 'Payment Gateway');
      expect(formatDisbursementMethod(null), '-');
      expect(formatDisbursementMethod('custom_method'), 'custom_method');
    });
  });
}
