import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal Bottom Sheet untuk memilih karyawan (Penerima Serah Terima / Alih Tangan)
class AssetEmployeePickerModal extends StatefulWidget {
  final String title;
  final String? excludeEmployeeId;
  final EmployeeRepository? repository;

  const AssetEmployeePickerModal({
    super.key,
    this.title = 'Pilih Karyawan Penerima',
    this.excludeEmployeeId,
    this.repository,
  });

  static Future<EmployeeDirectoryItem?> show(
    BuildContext context, {
    String title = 'Pilih Karyawan Penerima',
    String? excludeEmployeeId,
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
      ),
    );
  }

  @override
  State<AssetEmployeePickerModal> createState() =>
      _AssetEmployeePickerModalState();
}

class _AssetEmployeePickerModalState extends State<AssetEmployeePickerModal> {
  late final EmployeeRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<EmployeeDirectoryItem> _allEmployees = [];
  List<EmployeeDirectoryItem> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmployeeRepositoryImpl();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getCoworkers();
      final filtered = widget.excludeEmployeeId != null
          ? list.where((e) => e.id != widget.excludeEmployeeId).toList()
          : list;

      if (mounted) {
        setState(() {
          _allEmployees = filtered;
          _filteredEmployees = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onSearch(String query) {
    final trimmed = query.trim().toLowerCase();
    setState(() {
      if (trimmed.isEmpty) {
        _filteredEmployees = _allEmployees;
      } else {
        _filteredEmployees = _allEmployees.where((emp) {
          final nameMatch = emp.name.toLowerCase().contains(trimmed);
          final idMatch = emp.displayId.toLowerCase().contains(trimmed);
          final deptMatch = emp.department.toLowerCase().contains(trimmed);
          return nameMatch || idMatch || deptMatch;
        }).toList();
      }
    });
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
              hintText: 'Cari nama, NIK, atau divisi...',
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
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => const RequestCardShimmerLoading(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 32,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat daftar karyawan',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchEmployees,
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredEmployees.length,
      separatorBuilder: (context, index) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final item = _filteredEmployees[index];
        return InkWell(
          onTap: () => Navigator.of(context).pop(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: EmployeeInfoRow(
              employee: item,
              avatarSize: 42,
            ),
          ),
        );
      },
    );
  }
}
