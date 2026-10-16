import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/rating_selector.dart';
import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet kuesioner exit interview (skala 1–5, umpan balik, saran).
/// Tetap terbuka selama request berjalan dan menutup otomatis saat sukses.
Future<void> showExitInterviewSheet(
  BuildContext context, {
  required ResignationListBloc bloc,
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
      child: const ExitInterviewSheet(),
    ),
  );
}

class ExitInterviewSheet extends StatefulWidget {
  const ExitInterviewSheet({super.key});

  @override
  State<ExitInterviewSheet> createState() => _ExitInterviewSheetState();
}

class _ExitInterviewSheetState extends State<ExitInterviewSheet> {
  static const _scale = {'1': 'Sangat buruk', '5': 'Sangat baik'};

  final _feedbackController = TextEditingController();
  final _suggestionsController = TextEditingController();
  int? _culture;
  int? _manager;
  int? _salary;
  int? _growth;
  int? _workLife;
  bool _wouldRecommend = true;
  bool _isAnonymous = false;
  String? _error;

  @override
  void dispose() {
    _feedbackController.dispose();
    _suggestionsController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_feedbackController.text.trim().isEmpty) {
      setState(() => _error = 'Umpan balik alasan resign wajib diisi');
      return;
    }
    setState(() => _error = null);
    context.read<ResignationListBloc>().add(
      ResignationListExitInterviewSubmitted(
        ExitInterviewRequestModel(
          satisfactionCulture: _culture,
          satisfactionManager: _manager,
          satisfactionSalary: _salary,
          satisfactionGrowth: _growth,
          satisfactionWorkLifeBalance: _workLife,
          reasonFeedback: _feedbackController.text.trim(),
          suggestions: _suggestionsController.text.trim(),
          wouldRecommend: _wouldRecommend,
          isAnonymous: _isAnonymous,
        ),
      ),
    );
  }

  Widget _rating(
    String label,
    int? value,
    ValueChanged<int> onChanged,
    bool enabled,
    Color textCol,
    String keyName,
  ) {
    return Padding(
      key: ValueKey('exit_interview_$keyName'),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RatingSelector(
            min: 1,
            max: 5,
            value: value,
            labels: _scale,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

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
        final busy = state.isActionSubmitting;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kuesioner Exit Interview',
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Penilaian Anda membantu perusahaan menjadi lebih baik.',
                style: AppTypography.bodySmall.copyWith(color: subtitleCol),
              ),
              const SizedBox(height: AppSpacing.md),
              _rating('Budaya kerja', _culture, (v) => setState(() => _culture = v), !busy, textCol, 'culture'),
              _rating('Atasan langsung', _manager, (v) => setState(() => _manager = v), !busy, textCol, 'manager'),
              _rating('Gaji & benefit', _salary, (v) => setState(() => _salary = v), !busy, textCol, 'salary'),
              _rating('Pengembangan karier', _growth, (v) => setState(() => _growth = v), !busy, textCol, 'growth'),
              _rating('Keseimbangan kerja-hidup', _workLife, (v) => setState(() => _workLife = v), !busy, textCol, 'worklife'),
              AppTextField(
                key: const ValueKey('exit_interview_feedback'),
                label: 'Alasan utama Anda resign',
                isRequired: true,
                hintText: 'Ceritakan alasan Anda',
                controller: _feedbackController,
                maxLines: 3,
                enabled: !busy,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _error!,
                    key: const ValueKey('exit_interview_error'),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const ValueKey('exit_interview_suggestions'),
                label: 'Saran untuk perusahaan (opsional)',
                hintText: 'Apa yang bisa kami perbaiki?',
                controller: _suggestionsController,
                maxLines: 3,
                enabled: !busy,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile.adaptive(
                key: const ValueKey('exit_interview_recommend'),
                contentPadding: EdgeInsets.zero,
                value: _wouldRecommend,
                onChanged: busy ? null : (v) => setState(() => _wouldRecommend = v),
                title: Text(
                  'Saya akan merekomendasikan perusahaan ini',
                  style: AppTypography.bodyMedium.copyWith(color: textCol),
                ),
              ),
              SwitchListTile.adaptive(
                key: const ValueKey('exit_interview_anonymous'),
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                onChanged: busy ? null : (v) => setState(() => _isAnonymous = v),
                title: Text(
                  'Kirim secara anonim',
                  style: AppTypography.bodyMedium.copyWith(color: textCol),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Batal',
                      variant: AppButtonVariant.outlined,
                      height: 50,
                      onPressed: busy ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: AppButton(
                      key: const ValueKey('exit_interview_submit'),
                      text: 'Kirim',
                      leadingIcon: LucideIcons.send,
                      height: 50,
                      isLoading: busy,
                      onPressed: busy ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
