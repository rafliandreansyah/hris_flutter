import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_state.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet review pengajuan resign bawahan (1-on-1 atasan).
///
/// Untuk pengajuan berstatus `submitted` atasan dapat menyetujui / menolak.
/// Pengajuan yang sudah diproses ditampilkan read-only. Sheet tetap terbuka
/// selama request berjalan (loading pada tombol) dan menutup otomatis saat sukses.
Future<void> showResignationReviewSheet(
  BuildContext context, {
  required ResignationListBloc bloc,
  required SubordinateResignationItemModel item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: ResignationReviewSheet(item: item),
    ),
  );
}

class ResignationReviewSheet extends StatefulWidget {
  final SubordinateResignationItemModel item;

  const ResignationReviewSheet({super.key, required this.item});

  @override
  State<ResignationReviewSheet> createState() => _ResignationReviewSheetState();
}

class _ResignationReviewSheetState extends State<ResignationReviewSheet> {
  final _notesController = TextEditingController();
  bool _isApproved = true;
  bool _approveEarlyNotice = true;
  String? _notesError;

  bool get _isPending => widget.item.status.toLowerCase() == 'submitted';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final notes = _notesController.text.trim();
    if (notes.length < 5) {
      setState(() {
        _notesError = _isApproved
            ? 'Catatan diskusi 1-on-1 minimal 5 karakter'
            : 'Alasan penolakan minimal 5 karakter';
      });
      return;
    }
    setState(() => _notesError = null);
    context.read<ResignationListBloc>().add(
      ResignationListSubordinateReviewed(
        id: widget.item.id,
        isApproved: _isApproved,
        notes: notes,
        approveEarlyNotice: _approveEarlyNotice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brand = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final item = widget.item;
    final fmt = DateFormat('d MMM yyyy');

    return BlocConsumer<ResignationListBloc, ResignationListState>(
      listenWhen: (p, c) =>
          p.actionSuccessMessage != c.actionSuccessMessage &&
          c.actionSuccessMessage != null,
      listener: (context, state) {
        // Tutup HANYA route sheet ini (dialog sukses dari layar induk bisa
        // sudah terbuka di atasnya, sehingga pop() biasa menutup dialog itu).
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isActionSubmitting;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPending ? 'Review Pengajuan Resign' : 'Detail Pengajuan Resign',
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RequestDetailPersonCard(
                title: 'Informasi Pengaju',
                name: item.employeeName,
                position: item.positionName,
                department: item.departmentName,
                employeeNumber: item.employeeNik,
                email: item.employee?.email,
                phone: item.employee?.phone,
                avatarUrl: item.avatarUrl,
                // Sheet ini hanya dibuka atasan/HR, jadi pengaju selalu orang lain.
                showContactActions: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    _InfoLine(
                      label: 'Tanggal efektif',
                      value: item.effectiveDate != null
                          ? fmt.format(item.effectiveDate!)
                          : '-',
                    ),
                    _InfoLine(
                      label: 'Masa pemberitahuan',
                      value:
                          '${item.actualNoticePeriodDays} dari ${item.requiredNoticePeriodDays} hari',
                    ),
                    _InfoLine(label: 'Kategori alasan', value: item.reasonCategory),
                    _InfoLine(
                      label: 'Alasan',
                      value: item.reason.isEmpty ? '-' : item.reason,
                    ),
                    if (item.handoverToName != null)
                      _InfoLine(label: 'Serah terima ke', value: item.handoverToName!),
                  ],
                ),
              ),
              if (item.isEarlyNotice) ...[
                const SizedBox(height: AppSpacing.sm + 4),
                Container(
                  key: const ValueKey('resignation_review_early_notice'),
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md + 4),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.triangleAlert,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Pemberitahuan lebih awal dari kebijakan. Alasan: '
                          '${item.earlyNoticeReason ?? '-'}',
                          style: AppTypography.bodySmall.copyWith(color: textCol),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (_isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceButton(
                        key: const ValueKey('resignation_review_approve_choice'),
                        label: 'Setujui',
                        icon: LucideIcons.check,
                        selected: _isApproved,
                        color: brand,
                        onTap: isSubmitting
                            ? null
                            : () => setState(() {
                                _isApproved = true;
                                _notesError = null;
                              }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: _ChoiceButton(
                        key: const ValueKey('resignation_review_reject_choice'),
                        label: 'Tolak',
                        icon: LucideIcons.x,
                        selected: !_isApproved,
                        color: AppColors.errorRed,
                        onTap: isSubmitting
                            ? null
                            : () => setState(() {
                                _isApproved = false;
                                _notesError = null;
                              }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: const ValueKey('resignation_review_notes'),
                  label: _isApproved ? 'Catatan diskusi 1-on-1' : 'Alasan penolakan',
                  isRequired: true,
                  hintText: _isApproved
                      ? 'Ringkasan hasil diskusi dengan karyawan'
                      : 'Jelaskan alasan penolakan',
                  controller: _notesController,
                  maxLines: 3,
                  enabled: !isSubmitting,
                  onChanged: (_) {
                    if (_notesError != null) setState(() => _notesError = null);
                  },
                ),
                if (_notesError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _notesError!,
                      key: const ValueKey('resignation_review_notes_error'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                if (_isApproved && item.isEarlyNotice) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile.adaptive(
                    key: const ValueKey('resignation_review_early_switch'),
                    contentPadding: EdgeInsets.zero,
                    value: _approveEarlyNotice,
                    onChanged: isSubmitting
                        ? null
                        : (v) => setState(() => _approveEarlyNotice = v),
                    title: Text(
                      'Setujui pemberitahuan lebih awal',
                      style: AppTypography.bodyMedium.copyWith(color: textCol),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Batal',
                        variant: AppButtonVariant.outlined,
                        height: 50,
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('resignation_review_submit'),
                        text: _isApproved ? 'Setujui' : 'Tolak',
                        variant: _isApproved
                            ? AppButtonVariant.primary
                            : AppButtonVariant.danger,
                        height: 50,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                if (item.managerNotes != null && item.managerNotes!.trim().isNotEmpty)
                  Container(
                    key: const ValueKey('resignation_review_manager_notes'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md + 4),
                      border: Border(left: BorderSide(color: brand, width: 3)),
                    ),
                    child: Text(
                      item.managerNotes!,
                      style: AppTypography.bodySmall.copyWith(
                        color: textCol,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Tutup',
                  variant: AppButtonVariant.outlined,
                  height: 50,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keputusan Anda akan tercatat dan diteruskan ke HR.',
                style: AppTypography.labelSmall.copyWith(color: subtitleCol),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: subtitleCol),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: textCol,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  const _ChoiceButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: selected ? color : AppColors.outlineMuted,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : null),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: selected ? color : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
