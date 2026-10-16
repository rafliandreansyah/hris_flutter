import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/evaluation_form_bloc.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/rating_selector.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Form penilaian dinamis (kriteria dari template) dengan simpan draf otomatis.
class EvaluationFormScreen extends StatelessWidget {
  final String evaluationId;

  /// Dari klik notifikasi: bila saya bukan penilai (404), buka hasil evaluasi milik saya.
  final bool fallbackToResult;
  final LifecycleRepository? repository;
  final EvaluationFormBloc? bloc;

  const EvaluationFormScreen({
    super.key,
    required this.evaluationId,
    this.fallbackToResult = false,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<EvaluationFormBloc>.value(
        value: bloc!,
        child: _FormView(evaluationId: evaluationId, fallbackToResult: fallbackToResult),
      );
    }
    return BlocProvider(
      create: (_) => EvaluationFormBloc(repository: repository)
        ..add(EvaluationFormStarted(evaluationId)),
      child: _FormView(evaluationId: evaluationId, fallbackToResult: fallbackToResult),
    );
  }
}

class _FormView extends StatelessWidget {
  final String evaluationId;
  final bool fallbackToResult;

  const _FormView({required this.evaluationId, required this.fallbackToResult});

  Future<void> _confirmSubmit(BuildContext context, EvaluationFormState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final bloc = context.read<EvaluationFormBloc>();
    final ok = await AppDialogUtil.showConfirmation(
      context,
      title: 'Kirim Penilaian?',
      message:
          'Penilaian untuk ${state.form!.employee.name} akan dikirim ke HR dan tidak dapat diubah lagi.',
      confirmText: 'Kirim',
    );
    if (ok) bloc.add(const EvaluationFormSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return BlocConsumer<EvaluationFormBloc, EvaluationFormState>(
      listenWhen: (a, b) =>
          a.status != b.status ||
          (b.errorMessage != null && a.errorMessage != b.errorMessage),
      listener: (context, state) async {
        if (state.status == EvaluationFormStatus.failure &&
            state.errorStatusCode == 404 &&
            fallbackToResult) {
          context.pushReplacement(Routes.LIFECYCLE_MY_EVALUATION_DETAIL, extra: evaluationId);
          return;
        }
        if (state.status == EvaluationFormStatus.submitted) {
          final r = state.submitResult!;
          await AppDialogUtil.showSuccess(
            context,
            title: 'Penilaian Terkirim',
            message:
                'Skor akhir ${r.overallScore.toStringAsFixed(2)}${r.bandLabel != null ? ' • ${r.bandLabel}' : ''}.',
          );
          if (context.mounted) context.pop();
        } else if (state.errorMessage != null &&
            state.status == EvaluationFormStatus.loaded &&
            state.saveState != EvaluationDraftSaveState.error) {
          // Gagal kirim (400/409): pesan apa adanya dari server
          AppDialogUtil.showError(context, message: state.errorMessage!);
        }
      },
      builder: (context, state) {
        final form = state.form;
        final submitting = state.status == EvaluationFormStatus.submitting;
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: c.background,
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(LucideIcons.arrowLeft, color: c.text),
            ),
            title: Text(
              'Form Penilaian',
              style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
            ),
            actions: [if (form != null && form.canEdit) _SaveIndicator(state: state.saveState)],
          ),
          body: SafeArea(child: _content(context, state, c)),
          bottomNavigationBar: (form != null && form.canEdit)
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: AppButton(
                      text: 'Kirim Penilaian',
                      leadingIcon: LucideIcons.send,
                      isLoading: submitting,
                      onPressed: state.canSubmit && !submitting
                          ? () => _confirmSubmit(context, state)
                          : null,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _content(BuildContext context, EvaluationFormState state, LifecycleColors c) {
    final bloc = context.read<EvaluationFormBloc>();
    switch (state.status) {
      case EvaluationFormStatus.initial:
      case EvaluationFormStatus.loading:
        return const RequestCardShimmerLoading(itemCount: 3);
      case EvaluationFormStatus.failure:
        return LifecycleErrorState(
          message: state.errorMessage ?? 'Gagal memuat form penilaian.',
          statusCode: state.errorStatusCode,
          onRetry: () => bloc.add(EvaluationFormStarted(evaluationId)),
        );
      case EvaluationFormStatus.loaded:
      case EvaluationFormStatus.submitting:
      case EvaluationFormStatus.submitted:
        final form = state.form!;
        final editable = form.canEdit && state.status == EvaluationFormStatus.loaded;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(form: form),
            if (form.revisionNotes != null && form.revisionNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RevisionBanner(notes: form.revisionNotes!),
            ],
            if (!form.canEdit) ...[
              const SizedBox(height: 12),
              LifecycleCard(
                child: Text(
                  'Penilaian ini sudah dikirim dan tidak dapat diubah.',
                  style: AppTypography.bodyMedium.copyWith(color: c.subtitle),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _MetricsCard(metrics: form.metrics),
            const SizedBox(height: 16),
            const LifecycleSectionTitle('Kriteria Penilaian'),
            const SizedBox(height: 8),
            for (final item in form.items) ...[
              _CriterionCard(
                item: item,
                form: form,
                score: state.scores[item.id],
                text: state.texts[item.id] ?? '',
                enabled: editable,
              ),
              const SizedBox(height: 12),
            ],
            if (state.tentativeScore != null)
              LifecycleCard(
                child: Row(
                  children: [
                    Icon(LucideIcons.calculator, size: 18, color: c.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Skor sementara (resmi dihitung saat dikirim)',
                        style: AppTypography.bodySmall.copyWith(color: c.subtitle),
                      ),
                    ),
                    Text(
                      state.tentativeScore!.toStringAsFixed(2),
                      style: AppTypography.titleMedium.copyWith(
                        color: c.brand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const LifecycleSectionTitle('Usulan Keputusan'),
            const SizedBox(height: 8),
            LifecycleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioGroup<String>(
                    groupValue: state.proposal,
                    onChanged: (v) {
                      if (editable) bloc.add(EvaluationFormProposalChanged(v));
                    },
                    child: Column(
                      children: [
                        for (final p in form.allowedProposals)
                          RadioListTile<String>(
                            key: ValueKey('proposal-$p'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: p,
                            enabled: editable,
                            title: Text(lcLabel(lcDecisionLabels, p)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PersistentTextField(
                    fieldKey: const ValueKey('evaluator-notes'),
                    label: 'Catatan penilai (opsional)',
                    hintText: 'Tambahkan catatan untuk HR',
                    initialText: state.evaluatorNotes,
                    enabled: editable,
                    onChanged: (v) => bloc.add(EvaluationFormNotesChanged(v)),
                  ),
                ],
              ),
            ),
            if (editable && state.missingRequired.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Lengkapi kriteria wajib: ${state.missingRequired.map((e) => e.title).join(', ')}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
              ),
            ],
          ],
        );
    }
  }
}

class _SaveIndicator extends StatelessWidget {
  final EvaluationDraftSaveState state;
  const _SaveIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final (text, color) = switch (state) {
      EvaluationDraftSaveState.saving => ('Menyimpan…', c.subtitle),
      EvaluationDraftSaveState.saved => ('Draf tersimpan', c.brand),
      EvaluationDraftSaveState.error => ('Gagal simpan', AppColors.errorRed),
      EvaluationDraftSaveState.dirty => ('Belum tersimpan', c.subtitle),
      EvaluationDraftSaveState.idle => ('', c.subtitle),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Text(text, style: AppTypography.labelSmall.copyWith(color: color)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final EvaluationForm form;
  const _Header({required this.form});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return LifecycleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            form.employee.name,
            style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
          ),
          Text(
            [form.employee.positionName, form.employee.departmentName]
                .whereType<String>()
                .join(' • '),
            style: AppTypography.bodySmall.copyWith(color: c.subtitle),
          ),
          const SizedBox(height: 10),
          Text(
            lcLabel(lcEvaluationTypeLabels, form.evaluationType),
            style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
          ),
          Text(
            'Periode ${lcFormatDate(form.periodStartDate)} – ${lcFormatDate(form.periodEndDate)}',
            style: AppTypography.bodySmall.copyWith(color: c.subtitle),
          ),
          Text(
            'Batas penilaian ${lcFormatDate(form.dueDate)}',
            style: AppTypography.bodySmall.copyWith(color: c.subtitle),
          ),
          const SizedBox(height: 8),
          LifecycleStatusPill(
            label: lcLabel(lcEvaluationStatusLabels, form.status),
            tone: evaluationStatusTone(form.status),
          ),
        ],
      ),
    );
  }
}

class _RevisionBanner extends StatelessWidget {
  final String notes;
  const _RevisionBanner({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('revision-banner'),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: AppRadius.borderLg,
        border: Border(left: BorderSide(color: AppColors.warning, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan revisi dari HR',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onWarningContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notes,
            style: AppTypography.bodySmall.copyWith(color: AppColors.onWarningContainer),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final EvaluationSupportingMetrics metrics;
  const _MetricsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    Widget cell(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
              ),
              Text(label, style: AppTypography.labelSmall.copyWith(color: c.subtitle)),
            ],
          ),
        );
    return LifecycleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LifecycleSectionTitle('Data pendukung'),
          const SizedBox(height: 10),
          Row(
            children: [
              cell('Kehadiran', '${metrics.attendanceRate.toStringAsFixed(0)}%'),
              cell('Hadir', '${metrics.totalPresent}'),
              cell('Terlambat', '${metrics.totalLate}'),
              cell('SP aktif', '${metrics.activeWarningLetters}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CriterionCard extends StatelessWidget {
  final EvaluationTemplateItem item;
  final EvaluationForm form;
  final int? score;
  final String text;
  final bool enabled;

  const _CriterionCard({
    required this.item,
    required this.form,
    required this.score,
    required this.text,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final bloc = context.read<EvaluationFormBloc>();
    return LifecycleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: item.title,
              children: [
                if (item.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: AppTypography.bodySmall.copyWith(color: c.subtitle),
            ),
          ],
          const SizedBox(height: 12),
          if (item.isRating)
            RatingSelector(
              min: form.scaleMin,
              max: form.scaleMax,
              value: score,
              labels: form.scaleLabels,
              enabled: enabled,
              onChanged: (v) => bloc.add(EvaluationFormRatingChanged(item.id, v)),
            )
          else
            _PersistentTextField(
              fieldKey: ValueKey('text-${item.id}'),
              hintText: 'Tulis jawaban',
              initialText: text,
              enabled: enabled,
              onChanged: (v) => bloc.add(EvaluationFormTextChanged(item.id, v)),
            ),
        ],
      ),
    );
  }
}

/// Field teks dengan controller yang bertahan antar rebuild (nilai awal hanya dipakai sekali).
class _PersistentTextField extends StatefulWidget {
  final Key fieldKey;
  final String? label;
  final String hintText;
  final String initialText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _PersistentTextField({
    required this.fieldKey,
    this.label,
    required this.hintText,
    required this.initialText,
    required this.enabled,
    required this.onChanged,
  }) : super(key: fieldKey);

  @override
  State<_PersistentTextField> createState() => _PersistentTextFieldState();
}

class _PersistentTextFieldState extends State<_PersistentTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: widget.hintText,
      maxLines: 3,
      enabled: widget.enabled,
      controller: _controller,
      onChanged: widget.onChanged,
    );
  }
}
