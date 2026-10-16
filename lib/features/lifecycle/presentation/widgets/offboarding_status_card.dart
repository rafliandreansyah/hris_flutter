import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/pages/lifecycle_tasks_screen.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String offboardingStatusLabel(String status) => switch (status) {
      'initiated' || 'in_progress' => 'Proses offboarding berjalan',
      'pending_clearance' => 'Menunggu clearance',
      'clearance_completed' => 'Clearance selesai',
      'settled' => 'Offboarding selesai',
      'canceled' => 'Dibatalkan',
      _ => status,
    };

/// Status offboarding dari `GET /resignations/my-status` → blok `offboarding`.
/// Tidak menampilkan nominal apa pun (server memang tidak mengirimnya).
class OffboardingStatusCard extends StatelessWidget {
  final OffboardingStatusModel offboarding;
  final VoidCallback onTaskChanged;
  final LifecycleRepository? repository;

  const OffboardingStatusCard({
    super.key,
    required this.offboarding,
    required this.onTaskChanged,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final o = offboarding;
    final ratio = o.progress.total == 0 ? 0.0 : o.progress.done / o.progress.total;
    return LifecycleCard(
      key: const ValueKey('offboarding-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.logOut, color: c.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offboardingStatusLabel(o.status),
                  style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DateRow(label: 'Hari kerja terakhir', value: lcFormatDate(o.lastWorkingDate)),
          _DateRow(label: 'Efektif keluar', value: lcFormatDate(o.effectiveExitDate)),
          _DateRow(
            label: 'Akses dicabut',
            value: o.accessRevokedAt == null ? 'Belum' : lcFormatDate(o.accessRevokedAt),
          ),
          if (o.tasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            const LifecycleSectionTitle('Clearance'),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadius.borderFull,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: c.border,
                valueColor: AlwaysStoppedAnimation(c.brand),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${o.progress.done} dari ${o.progress.total} selesai',
              style: AppTypography.bodySmall.copyWith(color: c.subtitle),
            ),
            const SizedBox(height: 8),
            for (final t in o.tasks) ...[
              LifecycleTaskTile(task: t, repository: repository, onChanged: onTaskChanged),
              const SizedBox(height: 8),
            ],
          ],
          if (o.paklaring.issued) ...[
            const SizedBox(height: 14),
            const LifecycleSectionTitle('Surat Paklaring'),
            const SizedBox(height: 6),
            Row(
              key: const ValueKey('paklaring-info'),
              children: [
                const Icon(LucideIcons.fileCheck, color: Color(0xFF10B981)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No. ${o.paklaring.number ?? '-'} • terbit ${lcFormatDate(o.paklaring.issuedAt)}',
                    style: AppTypography.bodySmall.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  const _DateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: c.subtitle)),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
