import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_task_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_task_action_sheet.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Daftar tugas lifecycle milik saya (tujuan klik notifikasi `lifecycle_task` / `lifecycle_onboarding`).
class LifecycleTasksScreen extends StatelessWidget {
  final LifecycleRepository? repository;
  const LifecycleTasksScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return BlocProvider(
      create: (_) => MyTasksCubit(repository: repository)..load(),
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
            'Tugas Saya',
            style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MyTasksCubit, MyTasksState>(
            builder: (context, state) {
              final cubit = context.read<MyTasksCubit>();
              switch (state.status) {
                case LoadStatus.initial:
                case LoadStatus.loading:
                  return const RequestCardShimmerLoading(itemCount: 3);
                case LoadStatus.failure:
                  return LifecycleErrorState(
                    message: state.errorMessage ?? 'Gagal memuat daftar tugas.',
                    onRetry: cubit.load,
                  );
                case LoadStatus.success:
                  final mine = state.tasks.where((t) => t.isMine).toList();
                  if (mine.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: cubit.load,
                      child: const AppEmptyState(
                        icon: LucideIcons.listChecks,
                        title: 'Tidak Ada Tugas',
                        message: 'Belum ada tugas yang perlu Anda selesaikan.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: cubit.load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: mine.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => LifecycleTaskTile(
                        task: mine[i],
                        onChanged: cubit.load,
                      ),
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

/// Satu baris tugas; ketuk membuka sheet aksi.
class LifecycleTaskTile extends StatelessWidget {
  final LifecycleTaskModel task;
  final VoidCallback onChanged;
  final LifecycleRepository? repository;

  const LifecycleTaskTile({
    super.key,
    required this.task,
    required this.onChanged,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return LifecycleCard(
      onTap: () async {
        final done = await showLifecycleTaskActionSheet(context, task, repository: repository);
        if (done) onChanged();
      },
      child: Row(
        children: [
          Icon(
            task.status == 'done' ? LucideIcons.circleCheck : LucideIcons.circle,
            color: task.status == 'done' ? const Color(0xFF10B981) : c.subtitle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
                ),
                if (task.dueDate != null)
                  Text(
                    'Tenggat ${lcFormatDate(task.dueDate)}',
                    style: AppTypography.bodySmall.copyWith(color: c.subtitle),
                  ),
              ],
            ),
          ),
          LifecycleStatusPill(
            label: lifecycleTaskStatusLabel(task.status),
            tone: lifecycleTaskTone(task),
          ),
        ],
      ),
    );
  }
}
