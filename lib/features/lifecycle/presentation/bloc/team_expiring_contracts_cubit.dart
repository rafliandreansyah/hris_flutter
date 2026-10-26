import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/repositories/lifecycle_repository_impl.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';

class TeamExpiringContractsState extends Equatable {
  final LoadStatus status;
  final List<TeamExpiringContract> items;
  final String? errorMessage;
  final int? errorStatusCode;

  const TeamExpiringContractsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.errorStatusCode,
  });

  @override
  List<Object?> get props => [status, items, errorMessage, errorStatusCode];
}

/// Kontrak bawahan yang berakhir dalam 30 hari (H-30). Server menolak (403) bila bukan atasan.
class TeamExpiringContractsCubit extends Cubit<TeamExpiringContractsState> {
  static const int days = 30;

  final LifecycleRepository _repository;

  TeamExpiringContractsCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const TeamExpiringContractsState());

  Future<void> load() async {
    emit(const TeamExpiringContractsState(status: LoadStatus.loading));
    try {
      final items = await _repository.getTeamExpiringContracts(days: days);
      emit(TeamExpiringContractsState(status: LoadStatus.success, items: items));
    } on ApiException catch (e) {
      emit(
        TeamExpiringContractsState(
          status: LoadStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }
}
