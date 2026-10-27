import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_forbidden_state.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/team_expiring_contracts_cubit.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _contractTypeLabels = {
  'pkwt': 'PKWT (Kontrak)',
  'pkwtt': 'PKWTT (Tetap)',
  'internship': 'Magang',
  'freelance': 'Freelance',
};

/// Kontrak bawahan yang berakhir dalam 30 hari. Hanya untuk atasan/pemegang izin:
/// tanpa izin, layar menampilkan state terlarang dan server menjawab 403.
class TeamExpiringContractsScreen extends StatelessWidget {
  final LifecycleRepository? repository;

  /// Untuk tes: mengganti pemeriksaan izin.
  final bool? hasAccessOverride;

  const TeamExpiringContractsScreen({
    super.key,
    this.repository,
    this.hasAccessOverride,
  });

  static bool hasAccess() {
    final storage = SecureStorageService.instance;
    return !storage.hasLoadedPermissions ||
        storage.hasAnyPermissionInMemory(AppPermissions.teamLifecycle);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LifecycleColors.of(context);
    final allowed = hasAccessOverride ?? hasAccess();
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
          l10n?.teamContractsTitle ?? 'Kontrak Berakhir Tim',
          style: AppTypography.titleMedium.copyWith(color: c.text, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: allowed
            ? BlocProvider(
                create: (_) => TeamExpiringContractsCubit(repository: repository)..load(),
                child: const _Body(),
              )
            : const AppForbiddenState(
                message: 'Halaman ini hanya dapat diakses oleh atasan.',
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TeamExpiringContractsCubit, TeamExpiringContractsState>(
      builder: (context, state) {
        final cubit = context.read<TeamExpiringContractsCubit>();
        switch (state.status) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const RequestCardShimmerLoading(itemCount: 3);
          case LoadStatus.failure:
            if (state.errorStatusCode == 403) {
              return AppForbiddenState(
                message: state.errorMessage ?? 'Anda tidak memiliki hak akses.',
                onRetry: cubit.load,
              );
            }
            return LifecycleErrorState(
              message: state.errorMessage ?? 'Gagal memuat kontrak yang akan berakhir.',
              statusCode: state.errorStatusCode,
              onRetry: cubit.load,
            );
          case LoadStatus.success:
            if (state.items.isEmpty) {
              return RefreshIndicator(
                onRefresh: cubit.load,
                child: AppEmptyState(
                  icon: LucideIcons.calendarCheck,
                  title: l10n?.teamContractsEmptyTitle ?? 'Tidak Ada Kontrak yang Segera Berakhir',
                  message: l10n?.teamContractsEmptyMessage ??
                      'Belum ada kontrak bawahan yang berakhir dalam 30 hari ke depan.',
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
                itemBuilder: (context, i) => _ContractCard(item: state.items[i]),
              ),
            );
        }
      },
    );
  }
}

class _ContractCard extends StatelessWidget {
  final TeamExpiringContract item;
  const _ContractCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = item.daysRemaining <= 7 ? LifecycleTone.danger : LifecycleTone.warning;
    return RequestListCardFrame(
      onTap: item.evaluationId == null
          ? null
          : () => context.push(
                Routes.LIFECYCLE_EVALUATION_FORM,
                extra: {'id': item.evaluationId, 'fallbackToResult': true},
              ),
      header: RequestCardHeader(
        name: item.employeeName,
        role: item.positionName,
        department: item.departmentName,
        avatarUrl: item.photoUrl,
        initials: item.employeeName.isNotEmpty ? item.employeeName[0] : '?',
        trailing: LifecycleStatusPill(
          label: l10n?.teamContractsDaysLeft(item.daysRemaining) ??
              'Sisa ${item.daysRemaining} hari',
          tone: tone,
        ),
      ),
      children: [
        RequestCardInfoLine(
          icon: LucideIcons.fileText,
          text:
              '${lcLabel(_contractTypeLabels, item.type)} · ${l10n?.teamContractsEndsOn(lcFormatDate(item.endDate)) ?? 'Berakhir ${lcFormatDate(item.endDate)}'}',
        ),
        const SizedBox(height: AppSpacing.sm),
        RequestCardInfoLine(
          icon: item.evaluationId == null ? LucideIcons.clock : LucideIcons.clipboardList,
          text: item.evaluationId == null
              ? (l10n?.teamContractsNoEvaluation ?? 'Evaluasi belum dibuat')
              : (l10n?.teamContractsOpenEvaluation ?? 'Lihat Evaluasi'),
          emphasize: item.evaluationId != null,
        ),
      ],
    );
  }
}
