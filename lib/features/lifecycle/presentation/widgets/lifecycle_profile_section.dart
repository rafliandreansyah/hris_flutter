import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_profile_cubit.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _contractTypeLabels = {
  'pkwt': 'PKWT (Kontrak)',
  'pkwtt': 'PKWTT (Tetap)',
  'probation': 'Masa Percobaan',
  'internship': 'Magang',
  'freelance': 'Freelance',
};

const _contractStatusLabels = {
  'active': 'Aktif',
  'expired': 'Berakhir',
  'terminated': 'Diakhiri',
  'completed': 'Selesai',
  'draft': 'Draf',
};

const _changeTypeLabels = {
  'new_hire': 'Karyawan baru',
  'promotion': 'Promosi',
  'demotion': 'Penurunan jabatan',
  'transfer': 'Mutasi',
  'rotation': 'Rotasi',
  'contract_renewal': 'Perpanjangan kontrak',
  'contract_change': 'Perubahan kontrak',
  'rehire': 'Bergabung kembali',
  'termination': 'Berhenti',
};

/// Bagian profil: kontrak & riwayat karier (read-only, tanpa gaji). Hanya untuk profil sendiri.
class LifecycleProfileSection extends StatelessWidget {
  final LifecycleRepository? repository;
  const LifecycleProfileSection({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LifecycleProfileCubit(repository: repository)..load(),
      child: const LifecycleProfileSectionView(),
    );
  }
}

class LifecycleProfileSectionView extends StatelessWidget {
  const LifecycleProfileSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return BlocBuilder<LifecycleProfileCubit, LifecycleProfileState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LifecycleSectionTitle('Kontrak & Riwayat Karier'),
            const SizedBox(height: 8),
            _Links(),
            const SizedBox(height: 12),
            if (state.status == LoadStatus.initial || state.status == LoadStatus.loading)
              const LifecycleCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (state.status == LoadStatus.failure)
              LifecycleCard(
                key: const ValueKey('lifecycle-profile-error'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.contractsError ?? 'Gagal memuat kontrak & riwayat karier.',
                        style: AppTypography.bodySmall.copyWith(color: c.subtitle),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<LifecycleProfileCubit>().load(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (state.isEmpty && state.contractsError == null && state.careerError == null)
              LifecycleCard(
                key: const ValueKey('lifecycle-profile-empty'),
                child: Text(
                  'Belum ada data kontrak atau riwayat karier.',
                  style: AppTypography.bodySmall.copyWith(color: c.subtitle),
                ),
              )
            else ...[
              if (state.contractsError != null)
                _PartialError(message: state.contractsError!)
              else if (state.contracts != null)
                _ContractsCard(overview: state.contracts!),
              const SizedBox(height: 12),
              if (state.careerError != null)
                _PartialError(message: state.careerError!)
              else if (state.career.isNotEmpty)
                _CareerTimeline(items: state.career),
            ],
          ],
        );
      },
    );
  }
}

class _Links extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    Widget link(IconData icon, String label, String route) => Expanded(
          child: LifecycleCard(
            onTap: () => context.push(route),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: c.brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(color: c.text, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        link(LucideIcons.clipboardList, 'Hasil Evaluasi', Routes.LIFECYCLE_MY_EVALUATIONS),
        const SizedBox(width: 8),
        link(LucideIcons.clipboardCheck, 'Penilaian Tim', Routes.LIFECYCLE_EVALUATIONS),
      ],
    );
  }
}

class _PartialError extends StatelessWidget {
  final String message;
  const _PartialError({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return LifecycleCard(
      child: Text(message, style: AppTypography.bodySmall.copyWith(color: c.subtitle)),
    );
  }
}

class _ContractsCard extends StatelessWidget {
  final ContractOverviewModel overview;
  const _ContractsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final a = overview.activeContract;
    final pk = overview.pkwtSummary;
    return LifecycleCard(
      key: const ValueKey('contracts-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _contractTypeLabels[a.type] ?? a.type,
                    style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w800),
                  ),
                ),
                if (a.isNearExpiry)
                  const LifecycleStatusPill(label: 'Segera berakhir', tone: LifecycleTone.warning),
              ],
            ),
            Text(
              'No. ${a.contractNumber}',
              style: AppTypography.bodySmall.copyWith(color: c.subtitle),
            ),
            const SizedBox(height: 6),
            Text(
              '${lcFormatDate(a.startDate)} – ${a.endDate == null ? 'tidak terbatas' : lcFormatDate(a.endDate)}',
              style: AppTypography.bodyMedium.copyWith(color: c.text),
            ),
            if (a.daysUntilExpiry != null)
              Text(
                a.daysUntilExpiry! >= 0
                    ? 'Sisa ${a.daysUntilExpiry} hari'
                    : 'Berakhir ${-a.daysUntilExpiry!} hari lalu',
                style: AppTypography.bodySmall.copyWith(
                  color: a.isNearExpiry ? const Color(0xFFB45309) : c.subtitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ] else
            Text(
              'Tidak ada kontrak aktif.',
              style: AppTypography.bodyMedium.copyWith(color: c.subtitle),
            ),
          if (pk.totalPkwtMonths > 0) ...[
            const SizedBox(height: 14),
            const LifecycleSectionTitle('Akumulasi PKWT'),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadius.borderFull,
              child: LinearProgressIndicator(
                value: pk.usedRatio,
                minHeight: 8,
                backgroundColor: c.border,
                valueColor: AlwaysStoppedAnimation(
                  pk.usedRatio >= 0.9 ? const Color(0xFFEF4444) : c.brand,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${pk.totalPkwtMonths.toStringAsFixed(0)} dari ${pk.maxContractMonths.toStringAsFixed(0)} bulan',
              style: AppTypography.bodySmall.copyWith(color: c.subtitle),
            ),
          ],
          if (overview.contracts.isNotEmpty) ...[
            const SizedBox(height: 14),
            const LifecycleSectionTitle('Riwayat Kontrak'),
            const SizedBox(height: 6),
            for (final k in overview.contracts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${k.sequence} ${_contractTypeLabels[k.type] ?? k.type}\n'
                        '${lcFormatDate(k.startDate)} – ${k.endDate == null ? '-' : lcFormatDate(k.endDate)}',
                        style: AppTypography.bodySmall.copyWith(color: c.text),
                      ),
                    ),
                    LifecycleStatusPill(
                      label: _contractStatusLabels[k.status] ?? k.status,
                      tone: k.status == 'active' ? LifecycleTone.success : LifecycleTone.neutral,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CareerTimeline extends StatelessWidget {
  final List<CareerHistoryItem> items;
  const _CareerTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    return LifecycleCard(
      key: const ValueKey('career-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LifecycleSectionTitle('Linimasa Karier'),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            _CareerRow(item: items[i], isLast: i == items.length - 1, color: c),
        ],
      ),
    );
  }
}

class _CareerRow extends StatelessWidget {
  final CareerHistoryItem item;
  final bool isLast;
  final LifecycleColors color;
  const _CareerRow({required this.item, required this.isLast, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    final changes = <String>[
      if (item.prevPositionName != item.positionName && item.positionName != null)
        '${item.prevPositionName ?? '-'} → ${item.positionName}',
      if (item.prevDepartmentName != item.departmentName)
        '${item.prevDepartmentName} → ${item.departmentName}',
      if (item.prevCompanyName != item.companyName)
        '${item.prevCompanyName} → ${item.companyName}',
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: c.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _changeTypeLabels[item.changeType] ?? item.changeType,
                    style: AppTypography.titleSmall.copyWith(color: c.text, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    lcFormatDate(item.effectiveDate),
                    style: AppTypography.labelSmall.copyWith(color: c.subtitle),
                  ),
                  for (final line in changes)
                    Text(line, style: AppTypography.bodySmall.copyWith(color: c.text)),
                  if (changes.isEmpty)
                    Text(
                      [item.positionName, item.departmentName].whereType<String>().join(' • '),
                      style: AppTypography.bodySmall.copyWith(color: c.text),
                    ),
                  if (item.reason != null && item.reason!.isNotEmpty)
                    Text(
                      item.reason!,
                      style: AppTypography.bodySmall.copyWith(
                        color: c.subtitle,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
