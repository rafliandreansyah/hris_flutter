import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper pemformatan mata uang Rupiah.
String formatRupiah(num? amount) {
  if (amount == null) return 'Rp 0';
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Status pengeluaran (reimbursement & kasbon).
enum ExpenseStatus {
  requested,
  approved,
  disbursed,
  settlementInProgress,
  settled,
  rejected,
}

extension ExpenseStatusExtension on ExpenseStatus {
  String get label {
    switch (this) {
      case ExpenseStatus.requested:
        return 'Menunggu Persetujuan';
      case ExpenseStatus.approved:
        return 'Disetujui';
      case ExpenseStatus.disbursed:
        return 'Dicairkan';
      case ExpenseStatus.settlementInProgress:
        return 'Proses Settlement';
      case ExpenseStatus.settled:
        return 'Selesai';
      case ExpenseStatus.rejected:
        return 'Ditolak';
    }
  }

  Color get textColor {
    switch (this) {
      case ExpenseStatus.requested:
        return const Color(0xFFB45309); // Amber 700
      case ExpenseStatus.approved:
        return const Color(0xFF0F766E); // Teal 700
      case ExpenseStatus.disbursed:
      case ExpenseStatus.settled:
        return const Color(0xFF166534); // Green 800
      case ExpenseStatus.settlementInProgress:
        return const Color(0xFF4338CA); // Indigo 700
      case ExpenseStatus.rejected:
        return const Color(0xFF991B1B); // Red 800
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ExpenseStatus.requested:
        return const Color(0xFFFEF3C7); // Amber 100
      case ExpenseStatus.approved:
        return const Color(0xFFCCFBF1); // Teal 100
      case ExpenseStatus.disbursed:
      case ExpenseStatus.settled:
        return const Color(0xFFDCFCE7); // Green 100
      case ExpenseStatus.settlementInProgress:
        return const Color(0xFFE0E7FF); // Indigo 100
      case ExpenseStatus.rejected:
        return const Color(0xFFFEE2E2); // Red 100
    }
  }

  Color get dotColor {
    switch (this) {
      case ExpenseStatus.requested:
        return const Color(0xFFF59E0B);
      case ExpenseStatus.approved:
        return const Color(0xFF14B8A6);
      case ExpenseStatus.disbursed:
      case ExpenseStatus.settled:
        return const Color(0xFF16A34A);
      case ExpenseStatus.settlementInProgress:
        return const Color(0xFF6366F1);
      case ExpenseStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

ExpenseStatus parseExpenseStatus(String? raw) {
  if (raw == null) return ExpenseStatus.requested;
  switch (raw.toLowerCase()) {
    case 'approved':
      return ExpenseStatus.approved;
    case 'disbursed':
      return ExpenseStatus.disbursed;
    case 'settlement_in_progress':
      return ExpenseStatus.settlementInProgress;
    case 'settled':
      return ExpenseStatus.settled;
    case 'rejected':
      return ExpenseStatus.rejected;
    case 'requested':
    case 'pending':
    default:
      return ExpenseStatus.requested;
  }
}

/// Helper nama label metode pencairan.
String formatDisbursementMethod(String? method) {
  if (method == null) return '-';
  switch (method.toLowerCase()) {
    case 'manual_transfer':
      return 'Transfer Bank';
    case 'cash':
      return 'Uang Tunai (Petty Cash)';
    case 'payroll':
      return 'Masuk Payroll';
    case 'payment_gateway':
      return 'Payment Gateway';
    default:
      return method;
  }
}
