import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Detail hasil evaluasi + konfirmasi "Saya sudah membaca".
class MyEvaluationDetailScreen extends StatelessWidget {
  final String evaluationId;
  final LifecycleRepository? repository;

  const MyEvaluationDetailScreen({super.key, required this.evaluationId, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyEvaluationDetailCubit(repository: repository)..load(evaluationId),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return BlocConsumer<MyEvaluationDetailCubit, MyEvaluationDetailState>(
      listenWhen: (a, b) =>
          (b.justAcknowledged && !a.justAcknowledged) ||
          (b.errorMessage != null && a.errorMessage != b.errorMessage && b.detail != null),
      listener: (context, state) {
        if (state.justAcknowledged) {
          AppDialogUtil.showSuccess(context, message: 'Terima kasih, hasil evaluasi telah dikonfirmasi.');
        } else if (state.errorMessage != null) {
          AppDialogUtil.showError(context, message: state.errorMessage!);
        }
      },
      builder: (context, state) {
        final detail = state.detail;
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
              'Detail Evaluasi',
              style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: switch (state.status) {
              LoadStatus.initial || LoadStatus.loading => const RequestCardShimmerLoading(itemCount: 2),
              LoadStatus.failure => LifecycleErrorState(
                  message: state.errorMessage ?? 'Gagal memuat hasil evaluasi.',
                  statusCode: state.errorStatusCode,
                  onRetry: () {},
                ),
              LoadStatus.success => _Body(detail: detail!, commentController: _comment),
            },
          ),
          bottomNavigationBar: (detail != null && detail.requiresAcknowledgment)
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: AppButton(
                      text: 'Saya sudah membaca',
                      leadingIcon: LucideIcons.check,
                      isLoading: state.isAcknowledging,
                      onPressed: state.isAcknowledging
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              context
                                  .read<MyEvaluationDetailCubit>()
                                  .acknowledge(comment: _comment.text);
                            },
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final MyEvaluationDetail detail;
  final TextEditingController commentController;

  const _Body({required this.detail, required this.commentController});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final s = detail.summary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        LifecycleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lcLabel(lcEvaluationTypeLabels, s.evaluationType),
                style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
              ),
              Text(
                'Periode berakhir ${lcFormatDate(s.periodEndDate)}',
                style: AppTypography.bodySmall.copyWith(color: c.subtitle),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Skor akhir',
                      value: s.overallScore?.toStringAsFixed(2) ?? '-',
                    ),
                  ),
                  Expanded(child: _Stat(label: 'Kategori', value: s.bandLabel ?? '-')),
                ],
              ),
              const SizedBox(height: 16),
              const LifecycleSectionTitle('Keputusan'),
              const SizedBox(height: 4),
              Text(
                s.decision == null ? 'Belum ditetapkan' : lcLabel(lcDecisionLabels, s.decision),
                style: AppTypography.titleSmall.copyWith(color: c.brand, fontWeight: FontWeight.w800),
              ),
              Text(
                'Ditetapkan ${lcFormatDate(s.decidedAt)}',
                style: AppTypography.bodySmall.copyWith(color: c.subtitle),
              ),
            ],
          ),
        ),
        if (detail.newContractStartDate != null) ...[
          const SizedBox(height: 12),
          LifecycleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LifecycleSectionTitle('Kontrak baru'),
                const SizedBox(height: 8),
                Text(
                  '${lcFormatDate(detail.newContractStartDate)} – ${lcFormatDate(detail.newContractEndDate)}',
                  style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
                ),
                if (detail.newContractNumber != null)
                  Text(
                    'No. ${detail.newContractNumber}',
                    style: AppTypography.bodySmall.copyWith(color: c.subtitle),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (detail.requiresAcknowledgment)
          LifecycleCard(
            child: AppTextField(
              label: 'Komentar (opsional)',
              hintText: 'Tulis tanggapan Anda',
              maxLines: 3,
              controller: commentController,
            ),
          )
        else if (detail.acknowledgedAt != null)
          LifecycleCard(
            child: Row(
              key: const ValueKey('ack-status'),
              children: [
                const Icon(LucideIcons.circleCheck, color: Color(0xFF10B981)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Anda mengonfirmasi hasil ini pada ${lcFormatDate(detail.acknowledgedAt)}'
                    '${(detail.employeeComment ?? '').isNotEmpty ? '\n“${detail.employeeComment}”' : ''}',
                    style: AppTypography.bodySmall.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: c.subtitle)),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
