import 'package:equatable/equatable.dart';

abstract class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

/// Memuat bahasa yang tersimpan di storage lokal (default 'id')
class LocaleStarted extends LocaleEvent {
  const LocaleStarted();
}

/// Pengguna mengubah bahasa via pengaturan (memanggil PUT /auth/language dan menyimpan lokal)
class LocaleChanged extends LocaleEvent {
  final String languageCode;

  const LocaleChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

/// Sinkronisasi bahasa dari respons profil server (/auth/profile) tanpa PUT ulang
class LocaleSynced extends LocaleEvent {
  final String languageCode;

  const LocaleSynced(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
