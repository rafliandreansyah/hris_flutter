import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';

void main() {
  group('CashAdvanceDetailModel Tests', () {
    test('CashAdvanceRefundModel parses json correctly', () {
      final json = {
        'id': 'ref-1',
        'amount': 250000.0,
        'refundMethod': 'cash_refund',
        'proofUrl': 'uploads/kwitansi_refund.jpg',
        'notes': 'Pengembalian sisa dana bensin',
        'createdAt': '2026-09-21T15:00:00.000Z',
      };

      final refund = CashAdvanceRefundModel.fromJson(json);

      expect(refund.id, 'ref-1');
      expect(refund.amount, 250000.0);
      expect(refund.method, 'cash_refund');
      expect(refund.notes, 'Pengembalian sisa dana bensin');
      expect(refund.resolvedProofUrl, isNotNull);
      expect(refund.resolvedProofUrl, contains('kwitansi_refund.jpg'));
    });

    test('CashAdvanceSettlementReportModel parses json correctly', () {
      final json = {
        'id': 'rep-1',
        'claimNumber': 'CLM-SETTLE-001',
        'title': 'Laporan Nota Operasional',
        'totalRequestedAmount': 1750000.0,
        'totalApprovedAmount': 1750000.0,
        'balanceType': 'refund',
        'balanceAmount': 250000.0,
        'status': 'approved',
      };

      final report = CashAdvanceSettlementReportModel.fromJson(json);

      expect(report.id, 'rep-1');
      expect(report.claimNumber, 'CLM-SETTLE-001');
      expect(report.totalRequestedAmount, 1750000.0);
      expect(report.totalApprovedAmount, 1750000.0);
      expect(report.balanceType, 'refund');
      expect(report.balanceAmount, 250000.0);
    });

    test('CashAdvanceDetailModel calculates progress and remaining amounts correctly', () {
      final json = {
        'id': 'adv-1',
        'advanceNumber': 'ADV-2026-0001',
        'title': 'Kasbon Dinas Surabaya',
        'purpose': 'Biaya akomodasi dan transport',
        'requestedAmount': 2000000.0,
        'approvedAmount': 2000000.0,
        'status': 'disbursed',
        'disbursementMethod': 'manual_transfer',
        'disbursedAt': '2026-09-15T08:00:00.000Z',
        'settlementDeadline': '2026-09-30T23:59:59.000Z',
        'createdAt': '2026-09-14T08:00:00.000Z',
        'employee': {
          'id': 'emp-1',
          'firstName': 'Sarah',
          'lastName': 'Connor',
          'email': 'sarah@example.com',
        },
        'refunds': [
          {
            'id': 'ref-1',
            'amount': 250000.0,
            'refundMethod': 'cash_refund',
            'createdAt': '2026-09-20T00:00:00.000Z',
          }
        ],
        'settlementReport': {
          'id': 'rep-1',
          'claimNumber': 'CLM-SETTLE-001',
          'title': 'Nota Pengeluaran',
          'totalRequestedAmount': 1500000.0,
          'totalApprovedAmount': 1500000.0,
          'status': 'approved',
        }
      };

      final detail = CashAdvanceDetailModel.fromJson(json);

      expect(detail.id, 'adv-1');
      expect(detail.advanceNumber, 'ADV-2026-0001');
      expect(detail.disbursedAmount, 2000000.0);
      expect(detail.settledAmount, 1500000.0);
      expect(detail.refundedAmount, 250000.0);
      // Remaining = 2,000,000 - 1,500,000 - 250,000 = 250,000
      expect(detail.remainingAmount, 250000.0);
      // Progress = (1,500,000 + 250,000) / 2,000,000 = 1,750,000 / 2,000,000 = 0.875
      expect(detail.settlementProgress, 0.875);
      expect(detail.deadlineDateTime, isNotNull);
      expect(detail.deadlineDateTime!.year, 2026);
      expect(detail.isOverdue, isFalse);
    });

    test('CashAdvanceDetailModel handles overdue condition', () {
      final json = {
        'id': 'adv-overdue',
        'advanceNumber': 'ADV-OVERDUE',
        'title': 'Kasbon Telat',
        'purpose': 'Dinas lampau',
        'requestedAmount': 1000000.0,
        'approvedAmount': 1000000.0,
        'status': 'disbursed',
        'settlementDeadline': '2020-01-01T00:00:00.000Z',
        'createdAt': '2019-12-01T00:00:00.000Z',
        'employee': {'id': '1', 'firstName': 'A', 'email': 'a@a.com'},
      };

      final detail = CashAdvanceDetailModel.fromJson(json);

      expect(detail.remainingAmount, 1000000.0);
      expect(detail.isOverdue, isTrue);
    });
  });
}
