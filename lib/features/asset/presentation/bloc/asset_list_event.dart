import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/asset/data/models/asset_filter_criteria.dart';

abstract class AssetListEvent extends Equatable {
  const AssetListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman Fasilitas Saya dibuka pertama kali
class AssetListStarted extends AssetListEvent {
  const AssetListStarted();
}

/// Event pull-to-refresh
class AssetListRefreshed extends AssetListEvent {
  const AssetListRefreshed();
}

/// Event paginasi (scroll ke bawah)
class AssetListLoadMore extends AssetListEvent {
  const AssetListLoadMore();
}

/// Event perubahan kata kunci pencarian
class AssetListSearchChanged extends AssetListEvent {
  final String query;

  const AssetListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event penerapan kriteria filter dari bottom sheet
class AssetListFilterApplied extends AssetListEvent {
  final AssetFilterCriteria criteria;

  const AssetListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Event reset filter ke kondisi awal
class AssetListFilterReset extends AssetListEvent {
  const AssetListFilterReset();
}

/// Event pemilihan cepat kategori aset via chip horizontal
class AssetListCategorySelected extends AssetListEvent {
  final String? categoryId;
  final String? categoryName;

  const AssetListCategorySelected({this.categoryId, this.categoryName});

  @override
  List<Object?> get props => [categoryId, categoryName];
}

/// Event konfirmasi penerimaan fasilitas (Approve)
class AssetAssignmentApproved extends AssetListEvent {
  final String assignmentId;

  const AssetAssignmentApproved(this.assignmentId);

  @override
  List<Object?> get props => [assignmentId];
}

/// Event penolakan serah terima fasilitas (Reject)
class AssetAssignmentRejected extends AssetListEvent {
  final String assignmentId;
  final String reason;

  const AssetAssignmentRejected({
    required this.assignmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [assignmentId, reason];
}
