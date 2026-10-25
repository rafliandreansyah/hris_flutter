import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/evaluation_assigned_bloc.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Daftar penilaian yang harus saya isi sebagai atasan/penilai.
class EvaluationAssignedScreen extends StatelessWidget {
  final LifecycleRepository? repository;

  const EvaluationAssignedScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EvaluationAssignedBloc(repository: repository)
        ..add(const EvaluationAssignedStarted()),
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
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<EvaluationAssignedBloc>().add(const EvaluationAssignedLoadMore());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
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
          'Penilaian Tim',
          style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<EvaluationAssignedBloc, EvaluationAssignedState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      for (final f in const [('open', 'Perlu dinilai'), ('history', 'Riwayat')])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('filter-${f.$1}'),
                            label: Text(f.$2),
                            selected: state.filter == f.$1,
                            onSelected: (_) => context
                                .read<EvaluationAssignedBloc>()
                                .add(EvaluationAssignedFilterChanged(f.$1)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, EvaluationAssignedState state) {
    final bloc = context.read<EvaluationAssignedBloc>();
    Future<void> refresh() async => bloc.add(const EvaluationAssignedRefreshed());

    switch (state.status) {
      case EvaluationAssignedStatus.initial:
      case EvaluationAssignedStatus.loading:
        return const RequestCardShimmerLoading();
      case EvaluationAssignedStatus.failure:
        return RefreshIndicator(
          onRefresh: refresh,
          child: LifecycleErrorState(
            message: state.errorMessage ?? 'Gagal memuat daftar penilaian.',
            statusCode: state.errorStatusCode,
            onRetry: () => bloc.add(const EvaluationAssignedRefreshed()),
          ),
        );
      case EvaluationAssignedStatus.success:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: AppEmptyState(
              icon: LucideIcons.clipboardCheck,
              title: state.filter == 'open'
                  ? 'Tidak Ada Penilaian'
                  : 'Belum Ada Riwayat Penilaian',
              message: state.filter == 'open'
                  ? 'Belum ada karyawan yang perlu Anda nilai saat ini.'
                  : 'Penilaian yang sudah Anda kirim akan muncul di sini.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i >= state.items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: AppLoadingIndicator(),
                  ),
                );
              }
              return _AssignedCard(item: state.items[i]);
            },
          ),
        );
    }
  }
}

class _AssignedCard extends StatelessWidget {
  final EvaluationAssignedItem item;
  const _AssignedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return LifecycleCard(
      onTap: () async {
        await context.push(Routes.LIFECYCLE_EVALUATION_FORM, extra: item.id);
        if (context.mounted) {
          context.read<EvaluationAssignedBloc>().add(const EvaluationAssignedRefreshed());
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeInfoRow(
            name: item.employee.name,
            role: item.employee.positionName,
            department: item.employee.departmentName,
            employeeId: item.employee.employeeNumber,
            avatarUrl: item.employee.photoUrl,
            initials: item.employee.name.isNotEmpty ? item.employee.name[0] : '?',
            avatarSize: 44,
          ),
          const SizedBox(height: 12),
          Text(
            lcLabel(lcEvaluationTypeLabels, item.evaluationType),
            style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Batas penilaian: ${lcFormatDate(item.dueDate)}',
            style: AppTypography.bodySmall.copyWith(
              color: item.isOverdue && item.isOpen ? const Color(0xFFEF4444) : c.subtitle,
              fontWeight: item.isOverdue && item.isOpen ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              LifecycleStatusPill(
                label: lcLabel(lcEvaluationStatusLabels, item.status),
                tone: evaluationStatusTone(item.status),
              ),
              if (item.isOverdue && item.isOpen) ...[
                const SizedBox(width: 8),
                const LifecycleStatusPill(label: 'Terlambat', tone: LifecycleTone.danger),
              ],
              const Spacer(),
              if (item.overallScore != null)
                Text(
                  item.overallScore!.toStringAsFixed(2),
                  style: AppTypography.titleSmall.copyWith(
                    color: c.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
