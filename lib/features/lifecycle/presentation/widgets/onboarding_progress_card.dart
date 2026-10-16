import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_task_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/pages/lifecycle_tasks_screen.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu dashboard "Lengkapi data Anda (x dari y)". Mandiri: memuat datanya sendiri, tersembunyi saat
/// tidak ada onboarding aktif / gagal memuat, sehingga tidak pernah memblokir dashboard.
class OnboardingProgressCard extends StatelessWidget {
  final LifecycleRepository? repository;
  const OnboardingProgressCard({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCardCubit(repository: repository)..load(),
      child: BlocBuilder<OnboardingCardCubit, OnboardingCardState>(
        builder: (context, state) {
          if (!state.visible) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: OnboardingProgressCardView(
              onboarding: state.onboarding!,
              onChanged: () => context.read<OnboardingCardCubit>().load(),
              repository: repository,
            ),
          );
        },
      ),
    );
  }
}

class OnboardingProgressCardView extends StatelessWidget {
  final OnboardingProgressModel onboarding;
  final VoidCallback onChanged;
  final LifecycleRepository? repository;

  const OnboardingProgressCardView({
    super.key,
    required this.onboarding,
    required this.onChanged,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final p = onboarding.progress;
    final ratio = p.total == 0 ? 0.0 : p.done / p.total;
    return LifecycleCard(
      onTap: () => _openTasks(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listChecks, color: c.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lengkapi data Anda (${p.done} dari ${p.total})',
                  style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: c.subtitle),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(c.brand),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Onboarding ${onboarding.referenceNumber}',
            style: AppTypography.bodySmall.copyWith(color: c.subtitle),
          ),
        ],
      ),
    );
  }

  Future<void> _openTasks(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _TasksSheet(
        tasks: onboarding.myTasks,
        repository: repository,
        onChanged: onChanged,
      ),
    );
    onChanged();
  }
}

class _TasksSheet extends StatelessWidget {
  final List<LifecycleTaskModel> tasks;
  final LifecycleRepository? repository;
  final VoidCallback onChanged;

  const _TasksSheet({required this.tasks, required this.onChanged, this.repository});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shrinkWrap: true,
      children: [
        Text(
          'Tugas Onboarding Saya',
          style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Text(
            'Tidak ada tugas yang perlu Anda selesaikan. HR sedang memproses sisanya.',
            style: AppTypography.bodyMedium.copyWith(color: c.subtitle),
          ),
        for (final t in tasks) ...[
          LifecycleTaskTile(task: t, repository: repository, onChanged: () {
            Navigator.of(context).pop();
            onChanged();
          }),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
