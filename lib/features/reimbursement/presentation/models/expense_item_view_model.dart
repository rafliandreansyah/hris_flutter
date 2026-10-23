import 'package:hris_flutter/core/widgets/app_status_chip.dart';
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

  AppStatusTone get tone {
    switch (this) {
      case ExpenseStatus.requested:
      case ExpenseStatus.settlementInProgress:
        return AppStatusTone.warning;
      case ExpenseStatus.approved:
      case ExpenseStatus.settled:
        return AppStatusTone.success;
      case ExpenseStatus.disbursed:
        return AppStatusTone.info;
      case ExpenseStatus.rejected:
        return AppStatusTone.error;
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
