/// Tautan dokumen legal Oasish yang dihosting di landing page (hroasish.com).
abstract class LegalLinks {
  static const String privacyPolicy = 'https://hroasish.com/kebijakan-privasi/';
  static const String termsConditions = 'https://hroasish.com/syarat-ketentuan/';
  static const String refundPolicy =
      'https://hroasish.com/kebijakan-pengembalian-dana/';
  static const String faq = 'https://hroasish.com/faq/';
  static const String deleteData = 'https://hroasish.com/hapus-data/';
  static const String contact = 'https://hroasish.com/kontak/';

  /// Versi kebijakan yang harus disetujui. Samakan dengan tanggal "lastUpdated" halaman
  /// Kebijakan Privasi; menaikkan nilai ini meminta semua pengguna menyetujui ulang.
  static const String consentVersion = '2026-10-25';
}
