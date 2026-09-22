import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom Sheet untuk memilih kasbon aktif (`disbursed`) milik karyawan
/// untuk pelaporan penyelesaian (settlement) nota reimbursement.
class CashAdvancePickerSheet extends StatefulWidget {
  final ReimbursementRepository? repository;
  final String? selectedCashAdvanceId;

  const CashAdvancePickerSheet({
    super.key,
    this.repository,
    this.selectedCashAdvanceId,
  });

  static Future<ExpenseFeedItemModel?> show(
    BuildContext context, {
    ReimbursementRepository? repository,
    String? selectedCashAdvanceId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return showModalBottomSheet<ExpenseFeedItemModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CashAdvancePickerSheet(
        repository: repository ?? context.read<ReimbursementRepository>(),
        selectedCashAdvanceId: selectedCashAdvanceId,
      ),
    );
  }

  @override
  State<CashAdvancePickerSheet> createState() => _CashAdvancePickerSheetState();
}

class _CashAdvancePickerSheetState extends State<CashAdvancePickerSheet> {
  late final ReimbursementRepository _repository;
  bool _isLoading = true;
  String? _errorMessage;
  List<ExpenseFeedItemModel> _advances = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ReimbursementRepository>();
    _loadCashAdvances();
  }

  Future<void> _loadCashAdvances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feed = await _repository.getExpensesFeed(
        page: 1,
        size: 50,
        approver: false,
        type: 'cash_advance',
        status: 'disbursed',
      );
      if (!mounted) return;
      setState(() {
        _advances = feed.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Kasbon Aktif',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textCol,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daftar kasbon yang telah dicairkan finance',
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleCol,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: textCol),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Body
            Flexible(
              child: _buildBody(
                isDark,
                textCol,
                subtitleCol,
                brandColor,
                borderCol,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color textCol,
    Color subtitleCol,
    Color brandColor,
    Color borderCol,
  ) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            color: brandColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, color: AppColors.errorRed, size: 36),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat kasbon aktif',
                style: AppTypography.titleSmall.copyWith(color: textCol),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: subtitleCol),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadCashAdvances,
                icon: const Icon(LucideIcons.rotateCw, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_advances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.receiptText,
                  size: 28,
                  color: subtitleCol,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tidak Ada Kasbon Aktif',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Saat ini Anda tidak memiliki kasbon berstatus dicairkan yang memerlukan penyelesaian nota.',
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _advances.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _advances[index];
        final isSelected = item.id == widget.selectedCashAdvanceId;

        return InkWell(
          onTap: () => Navigator.of(context).pop(item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? brandColor.withValues(alpha: isDark ? 0.2 : 0.08)
                  : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? brandColor : borderCol,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.banknote,
                    color: brandColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.referenceNumber,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: brandColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatRupiah(item.approvedAmount ?? item.requestedAmount),
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textCol,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textCol,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected ? LucideIcons.circleCheck : LucideIcons.chevronRight,
                  size: 20,
                  color: isSelected ? brandColor : subtitleCol,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
