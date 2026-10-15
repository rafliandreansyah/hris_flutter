/// Kontak resmi Oasish yang ditampilkan di aplikasi.
/// Ubah di satu tempat ini bila nomor atau email admin berubah.
abstract class AppContacts {
  /// Nomor WhatsApp tanpa tanda plus, format internasional.
  static const String whatsappNumber = '6285888164634';

  /// Nomor WhatsApp untuk ditampilkan ke pengguna.
  static const String whatsappNumberDisplay = '+62 858-8816-4634';

  /// Pesan pembuka saat pengguna menghubungi via WhatsApp.
  static const String whatsappGreeting =
      'Halo Tim Oasish, saya tertarik dengan software HRIS untuk usaha saya';

  static String get whatsappUrl =>
      'https://api.whatsapp.com/send/?phone=$whatsappNumber'
      '&text=${Uri.encodeQueryComponent(whatsappGreeting)}'
      '&type=phone_number&app_absent=0';

  static const String adminEmail = 'halo@hroasish.com';
}
