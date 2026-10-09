import 'package:intl/intl.dart';

/// Formatter standar untuk menampilkan nominal Rupiah di seluruh aplikasi.
///
/// Jika [amount] bernilai `null`, mengembalikan `'Rp 0'`.
/// Jika [compact] bernilai `true`, nominal besar dapat disingkat (misal: Rp 1,5 jt).
String formatRupiah(num? amount, {bool compact = false}) {
  if (amount == null) return 'Rp 0';
  if (compact && amount.abs() >= 1000000) {
    final millions = amount / 1000000;
    final formatted = NumberFormat('#,##0.#', 'id_ID').format(millions);
    return 'Rp $formatted jt';
  }
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
