/// Helper fungsi untuk mengonversi angka nominal uang Rupiah ke kalimat teks terbilang bahasa Indonesia.
///
/// Contoh:
/// - `1500000` -> `"Satu Juta Lima Ratus Ribu Rupiah"`
/// - `250000` -> `"Dua Ratus Lima Puluh Ribu Rupiah"`
String angkaKeTerbilang(num number) {
  final n = number.toInt();
  if (n <= 0) return 'Nol Rupiah';

  final hasil = _bilang(n).trim();
  // Kapitalisasi huruf pertama setiap kata
  final kata = hasil.split(' ').map((k) {
    if (k.isEmpty) return '';
    return k[0].toUpperCase() + k.substring(1).toLowerCase();
  }).join(' ');

  return '$kata Rupiah';
}

String _bilang(int n) {
  const satuan = [
    '',
    'satu',
    'dua',
    'tiga',
    'empat',
    'lima',
    'enam',
    'tujuh',
    'delapan',
    'sembilan',
    'sepuluh',
    'sebelas',
  ];

  if (n < 12) {
    return satuan[n];
  } else if (n < 20) {
    return '${_bilang(n - 10)} belas';
  } else if (n < 100) {
    final sisa = n % 10;
    return '${_bilang(n ~/ 10)} puluh ${sisa > 0 ? _bilang(sisa) : ''}';
  } else if (n < 200) {
    final sisa = n - 100;
    return 'seratus ${sisa > 0 ? _bilang(sisa) : ''}';
  } else if (n < 1000) {
    final sisa = n % 100;
    return '${_bilang(n ~/ 100)} ratus ${sisa > 0 ? _bilang(sisa) : ''}';
  } else if (n < 2000) {
    final sisa = n - 1000;
    return 'seribu ${sisa > 0 ? _bilang(sisa) : ''}';
  } else if (n < 1000000) {
    final sisa = n % 1000;
    return '${_bilang(n ~/ 1000)} ribu ${sisa > 0 ? _bilang(sisa) : ''}';
  } else if (n < 1000000000) {
    final sisa = n % 1000000;
    return '${_bilang(n ~/ 1000000)} juta ${sisa > 0 ? _bilang(sisa) : ''}';
  } else if (n < 1000000000000) {
    final sisa = n % 1000000000;
    return '${_bilang(n ~/ 1000000000)} milyar ${sisa > 0 ? _bilang(sisa) : ''}';
  } else {
    final sisa = n % 1000000000000;
    return '${_bilang(n ~/ 1000000000000)} triliun ${sisa > 0 ? _bilang(sisa) : ''}';
  }
}
