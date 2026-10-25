import 'dart:async';

import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/app_error_message.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sumber daftar karyawan pada [AssetEmployeePickerModal].
enum AssetPickerSource {
  /// Rekan kerja (`/employee/coworkers`): alih tangan antar karyawan.
  coworkers,

  /// Direktori pegawai berhalaman dengan pencarian server (`/employee`): admin
  /// aset yang menyerahkan ke karyawan mana pun. Bila server menolak (403)
  /// otomatis kembali ke daftar rekan kerja.
  directory,
}

/// Modal Bottom Sheet untuk memilih karyawan (Penerima Serah Terima / Alih Tangan)
class AssetEmployeePickerModal extends StatefulWidget {
  final String title;
  final String? excludeEmployeeId;

  /// Karyawan yang sedang terpilih; diberi tanda centang di daftar.
  final String? selectedEmployeeId;
  final AssetPickerSource source;
  final EmployeeRepository? repository;

  const AssetEmployeePickerModal({
    super.key,
    this.title = 'Pilih Karyawan Penerima',
    this.excludeEmployeeId,
    this.selectedEmployeeId,
    this.source = AssetPickerSource.coworkers,
    this.repository,
  });

  static Future<EmployeeDirectoryItem?> show(
    BuildContext context, {
    String title = 'Pilih Karyawan Penerima',
    String? excludeEmployeeId,
    String? selectedEmployeeId,
    AssetPickerSource source = AssetPickerSource.coworkers,
  }) {
    return showModalBottomSheet<EmployeeDirectoryItem>(
      context: context,
      isScrollControlled: true,
      // Sheet ini menggambar drag handle sendiri; matikan handle bawaan tema agar tidak ganda
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AssetEmployeePickerModal(
        title: title,
        excludeEmployeeId: excludeEmployeeId,
        selectedEmployeeId: selectedEmployeeId,
        source: source,
      ),
    );
  }

  @override
  State<AssetEmployeePickerModal> createState() =>
      _AssetEmployeePickerModalState();
}

class _AssetEmployeePickerModalState extends State<AssetEmployeePickerModal> {
  static const int _pageSize = 30;

  late final EmployeeRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _errorMessage;

  /// True bila daftar berasal dari direktori (pencarian & halaman di server).
  late bool _usingDirectory = widget.source == AssetPickerSource.directory;
  List<EmployeeDirectoryItem> _allEmployees = [];
  List<EmployeeDirectoryItem> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmployeeRepositoryImpl();
    _scrollController.addListener(_onScroll);
    _fetchEmployees();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Keluarkan pemegang saat ini dan diri sendiri (tidak masuk akal sebagai
  /// penerima), mencocokkan id maupun rawId agar tidak bergantung fallback id.
  List<EmployeeDirectoryItem> _applyExclusion(List<EmployeeDirectoryItem> list) {
    final me = SecureStorageService.instance.employeeIdInMemory;
    final excluded = <String>{
      if (widget.excludeEmployeeId?.isNotEmpty ?? false)
        widget.excludeEmployeeId!,
      if (me?.isNotEmpty ?? false) me!,
    };
    return list
        .where((e) => !excluded.contains(e.id) && !excluded.contains(e.rawId))
        .toList();
  }

  Future<void> _fetchEmployees() {
    return _usingDirectory ? _fetchDirectory(reset: true) : _fetchCoworkers();
  }

  Future<void> _fetchCoworkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = _applyExclusion(await _repository.getCoworkers());
      if (!mounted) return;
      setState(() {
        _allEmployees = list;
        _isLoading = false;
        _hasMore = false;
      });
      _filterLocally(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppErrorMessage.from(e);
      });
    }
  }

  Future<void> _fetchDirectory({required bool reset}) async {
    if (!reset && (_isLoadingMore || !_hasMore)) return;
    final query = _searchController.text.trim();
    final targetPage = reset ? 1 : _page + 1;

    setState(() {
      if (reset) {
        _isLoading = true;
        _errorMessage = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await _repository.getEmployees(
        page: targetPage,
        size: _pageSize,
        search: query.isEmpty ? null : query,
      );
      // Abaikan hasil usang bila kata kunci sudah berganti saat menunggu.
      if (!mounted || query != _searchController.text.trim()) return;
      final fresh = _applyExclusion(response.data);
      setState(() {
        _allEmployees = reset ? fresh : [..._allEmployees, ...fresh];
        _filteredEmployees = _allEmployees;
        _page = targetPage;
        _hasMore = targetPage < response.meta.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
      _loadMoreIfViewportNotFilled();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 && reset) {
        // Tidak berwenang membuka direktori penuh: pakai daftar rekan kerja.
        _usingDirectory = false;
        await _fetchCoworkers();
        return;
      }
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (reset) _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (reset) _errorMessage = AppErrorMessage.from(e);
      });
    }
  }

  /// Bila halaman pertama belum memenuhi layar (tidak bisa digulir), muat berikutnya.
  void _loadMoreIfViewportNotFilled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasMore || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        _fetchDirectory(reset: false);
      }
    });
  }

  void _onScroll() {
    if (!_usingDirectory || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _fetchDirectory(reset: false);
    }
  }

  void _filterLocally(String query) {
    final trimmed = query.trim().toLowerCase();
    setState(() {
      if (trimmed.isEmpty) {
        _filteredEmployees = _allEmployees;
      } else {
        _filteredEmployees = _allEmployees.where((emp) {
          final nameMatch = emp.name.toLowerCase().contains(trimmed);
          final idMatch = emp.displayId.toLowerCase().contains(trimmed);
          final deptMatch = emp.department.toLowerCase().contains(trimmed);
          final roleMatch = emp.role.toLowerCase().contains(trimmed);
          final companyMatch =
              (emp.company ?? '').toLowerCase().contains(trimmed);
          return nameMatch || idMatch || deptMatch || roleMatch || companyMatch;
        }).toList();
      }
    });
  }

  void _onSearch(String query) {
    if (!_usingDirectory) {
      _filterLocally(query);
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetchDirectory(reset: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: borderCol,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textCol,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Cari nama, no. pegawai, jabatan, atau divisi...',
              onChanged: _onSearch,
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // List content
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const RequestCardShimmerLoading(itemCount: 5);
    }

    if (_errorMessage != null) {
      return AppEmptyState(
        icon: LucideIcons.circleAlert,
        title: 'Gagal Memuat Daftar Karyawan',
        message: _errorMessage,
        actionText: 'Coba Lagi',
        actionIcon: LucideIcons.rotateCcw,
        onAction: _fetchEmployees,
      );
    }

    if (_filteredEmployees.isEmpty) {
      return const AppEmptyState(
        icon: LucideIcons.users,
        title: 'Karyawan Tidak Ditemukan',
        message: 'Tidak ada karyawan yang cocok dengan kata kunci pencarian.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredEmployees.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 12),
      itemBuilder: (context, index) {
        if (index >= _filteredEmployees.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: AppLoadingIndicator.small()),
          );
        }
        final item = _filteredEmployees[index];
        return InkWell(
          onTap: () => Navigator.of(context).pop(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: EmployeeInfoRow(
                    employee: item,
                    avatarSize: 42,
                  ),
                ),
                if (item.id == widget.selectedEmployeeId)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: Icon(
                      LucideIcons.circleCheck,
                      size: 20,
                      color: AppColors.brandTeal,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
