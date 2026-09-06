import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Direktori Pegawai Oasish HRIS sesuai Google Stitch.
/// Menampilkan daftar pegawai dari API `/employee` dengan paginasi (default 30),
/// filter cascading, infinite scroll, dan search input interaktif yang otomatis
/// menyembunyikan diri saat scroll ke atas dan muncul kembali saat scroll ke bawah.
class EmployeeDirectoryScreen extends StatefulWidget {
  final List<EmployeeDirectoryItem>? customEmployees;
  final EmployeeRepository? employeeRepository;

  const EmployeeDirectoryScreen({
    super.key,
    this.customEmployees,
    this.employeeRepository,
  });

  @override
  State<EmployeeDirectoryScreen> createState() =>
      _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final EmployeeRepository _repository;
  Timer? _debounceTimer;

  String _searchQuery = '';
  EmployeeFilterCriteria _filterCriteria = const EmployeeFilterCriteria();

  List<EmployeeDirectoryItem> _employees = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;

  int _currentPage = 1;
  int _totalPages = 1;
  static const int _defaultPageSize = 30;

  // Interaktivitas Search Input: menyembunyikan saat scroll ke atas (reverse),
  // dan tampil lagi saat scroll ke bawah (forward)
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.employeeRepository ?? EmployeeRepositoryImpl();

    if (widget.customEmployees != null) {
      _employees = List.from(widget.customEmployees!);
    } else {
      _loadEmployees(page: 1, isRefresh: true);
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _currentPage < _totalPages) {
        _loadEmployees(page: _currentPage + 1, isRefresh: false);
      }
    }
  }

  Future<void> _loadEmployees({
    required int page,
    bool isRefresh = false,
  }) async {
    // Jika customEmployees disediakan untuk testing lokal, gunakan data tersebut
    if (widget.customEmployees != null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      if (isRefresh) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await _repository.getEmployees(
        page: page,
        size: _defaultPageSize,
        companyId: _filterCriteria.companyId,
        departmentId: _filterCriteria.departmentId,
        positionId: _filterCriteria.positionId,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _employees = response.data;
          } else {
            _employees.addAll(response.data);
          }
          _currentPage = response.meta.page;
          _totalPages = response.meta.totalPages;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Graceful fallback ke sample data jika unauthenticated atau offline
          if (isRefresh && _employees.isEmpty) {
            _employees = List.from(EmployeeDirectoryItem.sampleEmployees);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadEmployees(page: 1, isRefresh: true);
    });
  }

  List<String> get _availableCompanies {
    final comps = _employees
        .map((e) => e.company)
        .whereType<String>()
        .toSet()
        .toList();
    comps.sort();
    return ['Semua Perusahaan', ...comps];
  }

  List<String> get _availableDepartments {
    final depts = _employees.map((e) => e.department).toSet().toList();
    depts.sort();
    return ['Semua Departemen', ...depts];
  }

  List<String> get _availablePositions {
    final roles = _employees.map((e) => e.role).toSet().toList();
    roles.sort();
    return ['Semua Jabatan', ...roles];
  }

  List<EmployeeDirectoryItem> get _filteredEmployees {
    // Jika data berasal dari server atau fallback lokal,
    // kita juga terapkan client-side filtering untuk memastikan instant UI response
    return _employees.where((emp) {
      // 1. Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matches = emp.name.toLowerCase().contains(q) ||
            emp.role.toLowerCase().contains(q) ||
            emp.department.toLowerCase().contains(q) ||
            emp.email.toLowerCase().contains(q) ||
            emp.id.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // 2. Filter by Company
      if (_filterCriteria.company != null &&
          _filterCriteria.company != 'Semua Perusahaan') {
        if (emp.company != null &&
            emp.company!.toLowerCase() !=
                _filterCriteria.company!.toLowerCase()) {
          return false;
        }
      }

      // 3. Filter by Department
      if (_filterCriteria.department != null &&
          _filterCriteria.department != 'Semua Departemen') {
        if (emp.department.toLowerCase() !=
            _filterCriteria.department!.toLowerCase()) {
          return false;
        }
      }

      // 4. Filter by Position / Role
      if (_filterCriteria.position != null &&
          _filterCriteria.position != 'Semua Jabatan') {
        if (emp.role.toLowerCase() !=
            _filterCriteria.position!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onEmployeeTapped(EmployeeDirectoryItem employee) {
    context.push(Routes.EMPLOYEE_DETAIL, extra: employee);
  }

  Widget _buildActiveFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDeleted,
    required Color brandColor,
    required Color textCol,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: brandColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brandColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              LucideIcons.x,
              size: 13,
              color: brandColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final surfaceCol =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final filteredList = _filteredEmployees;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: bgCol.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Directory',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Find colleagues, departments & contact info',
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showEmployeeFilterBottomSheet(
                context,
                initialCriteria: _filterCriteria,
                availableCompanies: _availableCompanies,
                availableDepartments: _availableDepartments,
                availablePositions: _availablePositions,
              );
              if (result != null) {
                setState(() {
                  _filterCriteria = result;
                });
                _loadEmployees(page: 1, isRefresh: true);
              }
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  color: _filterCriteria.hasActiveFilter ? brandColor : textCol,
                  size: 20,
                ),
                if (_filterCriteria.hasActiveFilter)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgCol, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Direktori',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Dynamic Hide/Show Search Bar on Scroll
            // Menutup ketika scroll ke atas (content bergerak ke atas)
            // dan tampil lagi saat scroll ke bawah (content bergerak ke bawah)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isSearchVisible ? 62 : 0,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: bgCol,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isSearchVisible ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceCol,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: (val) {
                        _debounceTimer?.cancel();
                        setState(() {
                          _searchQuery = val;
                        });
                        _loadEmployees(page: 1, isRefresh: true);
                      },
                      style: AppTypography.bodyMedium.copyWith(color: textCol),
                      decoration: InputDecoration(
                        hintText:
                            'Search by name, role, department, or email...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: subtitleCol,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: subtitleCol,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: subtitleCol,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Main Scrollable Content with Scroll Notification Listener
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.metrics.axis == Axis.vertical) {
                    final delta = notification.scrollDelta ?? 0;

                    // Jika berada di dekat batas atas, selalu tampilkan search bar
                    if (notification.metrics.pixels <= 10) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                    // Saat scroll ke atas (content bergerak ke atas / offset membesar) -> sembunyikan search bar
                    else if (delta > 3) {
                      if (_isSearchVisible) {
                        setState(() => _isSearchVisible = false);
                      }
                    }
                    // Saat scroll ke bawah (content bergerak ke bawah / offset mengecil) -> tampilkan search bar
                    else if (delta < -3) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () => _loadEmployees(page: 1, isRefresh: true),
                  color: brandColor,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Active Filter Chips Row
                      if (_filterCriteria.hasActiveFilter)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_filterCriteria.company != null &&
                                      _filterCriteria.company !=
                                          'Semua Perusahaan')
                                    _buildActiveFilterChip(
                                      label: _filterCriteria.company!,
                                      icon: LucideIcons.building,
                                      onDeleted: () {
                                        setState(() {
                                          _filterCriteria =
                                              _filterCriteria.copyWith(
                                            company: 'Semua Perusahaan',
                                            companyId: '',
                                          );
                                        });
                                        _loadEmployees(
                                            page: 1, isRefresh: true);
                                      },
                                      brandColor: brandColor,
                                      textCol: textCol,
                                    ),
                                  if (_filterCriteria.department != null &&
                                      _filterCriteria.department !=
                                          'Semua Departemen')
                                    _buildActiveFilterChip(
                                      label: _filterCriteria.department!,
                                      icon: LucideIcons.layers,
                                      onDeleted: () {
                                        setState(() {
                                          _filterCriteria =
                                              _filterCriteria.copyWith(
                                            department: 'Semua Departemen',
                                            departmentId: '',
                                          );
                                        });
                                        _loadEmployees(
                                            page: 1, isRefresh: true);
                                      },
                                      brandColor: brandColor,
                                      textCol: textCol,
                                    ),
                                  if (_filterCriteria.position != null &&
                                      _filterCriteria.position !=
                                          'Semua Jabatan')
                                    _buildActiveFilterChip(
                                      label: _filterCriteria.position!,
                                      icon: LucideIcons.idCard,
                                      onDeleted: () {
                                        setState(() {
                                          _filterCriteria =
                                              _filterCriteria.copyWith(
                                            position: 'Semua Jabatan',
                                            positionId: '',
                                          );
                                        });
                                        _loadEmployees(
                                            page: 1, isRefresh: true);
                                      },
                                      brandColor: brandColor,
                                      textCol: textCol,
                                    ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _filterCriteria =
                                            const EmployeeFilterCriteria();
                                      });
                                      _loadEmployees(page: 1, isRefresh: true);
                                    },
                                    child: Text(
                                      'Hapus Semua',
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: brandColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Loading First Page Indicator
                      if (_isLoading && _employees.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(brandColor),
                              ),
                            ),
                          ),
                        )
                      // Employee Cards List or Empty State
                      else if (filteredList.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 48,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: brandColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.userX,
                                      size: 28,
                                      color: brandColor,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Pegawai tidak ditemukan',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: textCol,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _filterCriteria.hasActiveFilter &&
                                            _searchQuery.isNotEmpty
                                        ? 'Tidak ada pegawai yang cocok dengan kata kunci "$_searchQuery" dan filter yang aktif.'
                                        : _filterCriteria.hasActiveFilter
                                            ? 'Tidak ada pegawai yang cocok dengan kriteria filter yang dipilih.'
                                            : 'Tidak ada pegawai yang cocok dengan kata kunci "$_searchQuery".',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: subtitleCol,
                                    ),
                                  ),
                                  if (_filterCriteria.hasActiveFilter ||
                                      _searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _filterCriteria =
                                              const EmployeeFilterCriteria();
                                        });
                                        _loadEmployees(
                                            page: 1, isRefresh: true);
                                      },
                                      icon: const Icon(LucideIcons.rotateCcw,
                                          size: 15),
                                      label: const Text(
                                          'Reset Filter & Pencarian'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: brandColor,
                                        side: BorderSide(color: brandColor),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final employee = filteredList[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: EmployeeCard(
                                    employee: employee,
                                    onTap: () => _onEmployeeTapped(employee),
                                  ),
                                );
                              },
                              childCount: filteredList.length,
                            ),
                          ),
                        ),

                      // Infinite Scroll Loading Indicator: hanya tampil jika sedang memuat halaman berikutnya (_isLoadingMore)
                      if (_isLoadingMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(brandColor),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (!_isLoading &&
                          _currentPage >= _totalPages &&
                          filteredList.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                            child: Center(
                              child: Text(
                                'Semua data pegawai telah ditampilkan',
                                style: AppTypography.labelSmall.copyWith(
                                  color: subtitleCol.withValues(alpha: 0.7),
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
