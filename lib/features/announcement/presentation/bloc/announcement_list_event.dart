import 'package:equatable/equatable.dart';

abstract class AnnouncementListEvent extends Equatable {
  const AnnouncementListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman pertama kali dibuka atau dimuat ulang dari awal.
class AnnouncementListStarted extends AnnouncementListEvent {
  const AnnouncementListStarted();
}

/// Event pull-to-refresh untuk menyegarkan data daftar pengumuman.
class AnnouncementListRefreshed extends AnnouncementListEvent {
  const AnnouncementListRefreshed();
}

/// Event saat scroll mencapai batas bawah untuk memuat halaman berikutnya (infinite pagination).
class AnnouncementListLoadMore extends AnnouncementListEvent {
  const AnnouncementListLoadMore();
}

/// Event saat teks pencarian diubah oleh pengguna.
class AnnouncementSearchChanged extends AnnouncementListEvent {
  final String query;

  const AnnouncementSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event saat filter kategori dan/atau prioritas diterapkan dari Bottom Sheet.
class AnnouncementFilterApplied extends AnnouncementListEvent {
  final String? category;
  final String? priority;

  const AnnouncementFilterApplied({
    this.category,
    this.priority,
  });

  @override
  List<Object?> get props => [category, priority];
}

/// Event saat pengguna menekan tombol reset filter.
class AnnouncementFilterReset extends AnnouncementListEvent {
  const AnnouncementFilterReset();
}
