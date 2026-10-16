import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Hasil evaluasi milik saya (hanya yang sudah diputuskan).
class MyEvaluationsScreen extends StatelessWidget {
  final LifecycleRepository? repository;
  const MyEvaluationsScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return BlocProvider(
      create: (_) => MyEvaluationsCubit(repository: repository)..load(),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(LucideIcons.arrowLeft, color: c.text),
          ),
          title: Text(
            'Hasil Evaluasi Saya',
            style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MyEvaluationsCubit, MyEvaluationsState>(
            builder: (context, state) {
              final cubit = context.read<MyEvaluationsCubit>();
              switch (state.status) {
                case LoadStatus.initial:
                case LoadStatus.loading:
                  return const RequestCardShimmerLoading(itemCount: 3);
                case LoadStatus.failure:
                  return LifecycleErrorState(
                    message: state.errorMessage ?? 'Gagal memuat hasil evaluasi.',
                    statusCode: state.errorStatusCode,
                    onRetry: cubit.load,
                  );
                case LoadStatus.success:
                  if (state.items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: cubit.load,
                      child: const AppEmptyState(
                        icon: LucideIcons.clipboardList,
                        title: 'Belum Ada Hasil Evaluasi',
                        message: 'Hasil evaluasi akan muncul di sini setelah HR menetapkan keputusan.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: cubit.load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _ResultCard(item: state.items[i]),
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MyEvaluationItem item;
  const _ResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final needsAck = item.status == 'decided' && !item.acknowledged;
    return LifecycleCard(
      onTap: () async {
        await context.push(Routes.LIFECYCLE_MY_EVALUATION_DETAIL, extra: item.id);
        if (context.mounted) context.read<MyEvaluationsCubit>().load();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lcLabel(lcEvaluationTypeLabels, item.evaluationType),
                  style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
                ),
              ),
              if (item.overallScore != null)
                Text(
                  item.overallScore!.toStringAsFixed(2),
                  style: AppTypography.titleMedium.copyWith(color: c.brand, fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Periode berakhir ${lcFormatDate(item.periodEndDate)}',
            style: AppTypography.bodySmall.copyWith(color: c.subtitle),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (item.decision != null)
                LifecycleStatusPill(
                  label: lcLabel(lcDecisionLabels, item.decision),
                  tone: LifecycleTone.info,
                ),
              if (needsAck)
                const LifecycleStatusPill(label: 'Perlu konfirmasi', tone: LifecycleTone.warning)
              else if (item.acknowledged)
                const LifecycleStatusPill(label: 'Sudah dikonfirmasi', tone: LifecycleTone.success),
            ],
          ),
        ],
      ),
    );
  }
}
