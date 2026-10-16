import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_task_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';

/// Label status task (Indonesia, konsisten dengan web).
String lifecycleTaskStatusLabel(String status) => switch (status) {
      'pending' => 'Menunggu',
      'in_progress' => 'Berjalan',
      'done' => 'Selesai',
      'skipped' => 'Dilewati',
      'blocked' => 'Terblokir',
      _ => status,
    };

LifecycleTone lifecycleTaskTone(LifecycleTaskModel t) {
  if (t.status == 'done') return LifecycleTone.success;
  if (t.status == 'blocked') return LifecycleTone.danger;
  if (t.isOverdue) return LifecycleTone.danger;
  if (t.status == 'skipped') return LifecycleTone.neutral;
  return LifecycleTone.warning;
}

/// Komponen bersama untuk menyelesaikan tugas (dipakai kartu onboarding & status offboarding).
/// Mengembalikan `true` bila tugas berhasil diselesaikan sehingga pemanggil dapat memuat ulang data.
Future<bool> showLifecycleTaskActionSheet(
  BuildContext context,
  LifecycleTaskModel task, {
  LifecycleRepository? repository,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) => TaskActionCubit(repository: repository),
      child: LifecycleTaskActionSheet(task: task),
    ),
  );
  return result ?? false;
}

class LifecycleTaskActionSheet extends StatelessWidget {
  final LifecycleTaskModel task;
  const LifecycleTaskActionSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return BlocConsumer<TaskActionCubit, TaskActionState>(
      listener: (context, state) {
        if (state.completedTaskId == task.id) {
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          AppDialogUtil.showError(context, message: state.errorMessage!);
        }
      },
      builder: (context, state) {
        final busy = state.busyTaskId == task.id;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    LifecycleStatusPill(
                      label: lifecycleTaskStatusLabel(task.status),
                      tone: lifecycleTaskTone(task),
                    ),
                    if (task.isRequired) ...[
                      const SizedBox(width: 8),
                      const LifecycleStatusPill(label: 'Wajib', tone: LifecycleTone.info),
                    ],
                  ],
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    task.description!,
                    style: AppTypography.bodyMedium.copyWith(color: c.text),
                  ),
                ],
                if (task.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tenggat ${lcFormatDate(task.dueDate)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: task.isOverdue ? AppColors.errorRed : c.subtitle,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _actions(context, c, busy),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, LifecycleColors c, bool busy) {
    // Tugas yang bukan milik saya / sudah ditutup: hanya informasi.
    if (task.isClosed) {
      return Text(
        'Tugas ini sudah ${lifecycleTaskStatusLabel(task.status).toLowerCase()}.',
        style: AppTypography.bodySmall.copyWith(color: c.subtitle),
      );
    }
    if (!task.isMine) {
      return Text(
        'Tugas ini ditangani oleh pihak lain (${task.assigneeRole.toUpperCase()}). Anda hanya dapat memantau statusnya.',
        style: AppTypography.bodySmall.copyWith(color: c.subtitle),
      );
    }

    switch (task.type) {
      case 'system_check':
        // Status diperbarui otomatis oleh sistem; tidak ada tombol selesai.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status tugas ini diperbarui otomatis setelah data Anda lengkap. Lengkapi data di halaman profil.',
              style: AppTypography.bodySmall.copyWith(color: c.subtitle),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Buka Profil',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                Navigator.of(context).pop(false);
                context.push(Routes.EMPLOYEE_DETAIL);
              },
            ),
          ],
        );
      case 'document_upload':
        // API hanya menerima URL lampiran dan belum ada endpoint unggah untuk mobile.
        return Text(
          'Tugas ini membutuhkan unggahan berkas. Silakan serahkan berkas ke HR atau selesaikan melalui aplikasi web.',
          style: AppTypography.bodySmall.copyWith(color: c.subtitle),
        );
      case 'acknowledgment':
        return AppButton(
          text: 'Setuju',
          leadingIcon: Icons.check,
          isLoading: busy,
          onPressed: busy ? null : () => context.read<TaskActionCubit>().complete(task),
        );
      default:
        return AppButton(
          text: 'Tandai Selesai',
          leadingIcon: Icons.check,
          isLoading: busy,
          onPressed: busy ? null : () => context.read<TaskActionCubit>().complete(task),
        );
    }
  }
}
