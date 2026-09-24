import 'package:equatable/equatable.dart';

/// Kriteria filter untuk daftar fasilitas aset (Screen 3: Oasish Filter Fasilitas).
class AssetFilterCriteria extends Equatable {
  /// Nilai status sesuai backend:
  /// - 'all': Semua Status
  /// - 'ACTIVE': Aktif (default)
  /// - 'PENDING_ACCEPTANCE': Menunggu Konfirmasi
  /// - 'RETURNED': Riwayat (Dikembalikan)
  /// - 'REJECTED': Ditolak
  /// - 'AVAILABLE': Pool Gudang (Tersedia)
  final String status;

  /// ID kategori aset yang dipilih
  final String? categoryId;

  /// Nama kategori aset untuk label chip filter
  final String? categoryName;

  /// Pilihan urutan: 'newest', 'oldest', 'name_asc', 'name_desc'
  final String sortBy;

  /// Kata kunci pencarian
  final String? search;

  const AssetFilterCriteria({
    this.status = 'all',
    this.categoryId,
    this.categoryName,
    this.sortBy = 'newest',
    this.search,
  });

  /// Status apakah filter aktif (berbeda dari kondisi default)
  bool get hasActiveFilter =>
      (status != 'all' && status.isNotEmpty) ||
      (categoryId != null && categoryId!.isNotEmpty) ||
      (sortBy != 'newest') ||
      (search != null && search!.trim().isNotEmpty);

  /// Jumlah filter aktif yang sedang diterapkan
  int get activeFilterCount {
    int count = 0;
    if (status != 'all' && status.isNotEmpty) count++;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (sortBy != 'newest') count++;
    if (search != null && search!.trim().isNotEmpty) count++;
    return count;
  }

  AssetFilterCriteria copyWith({
    String? status,
    String? categoryId,
    bool clearCategory = false,
    String? categoryName,
    String? sortBy,
    String? search,
    bool clearSearch = false,
  }) {
    return AssetFilterCriteria(
      status: status ?? this.status,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      sortBy: sortBy ?? this.sortBy,
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  /// Reset ke nilai default
  factory AssetFilterCriteria.initial() => const AssetFilterCriteria(
        status: 'all',
        categoryId: null,
        categoryName: null,
        sortBy: 'newest',
        search: null,
      );

  @override
  List<Object?> get props => [status, categoryId, categoryName, sortBy, search];
}
