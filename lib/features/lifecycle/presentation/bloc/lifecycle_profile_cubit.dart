import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/repositories/lifecycle_repository_impl.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';

/// Kontrak & riwayat karier untuk Profil. Dua bagian dimuat paralel dan gagal terpisah
/// sehingga satu bagian error tidak mengosongkan yang lain.
class LifecycleProfileState extends Equatable {
  final LoadStatus status;
  final ContractOverviewModel? contracts;
  final List<CareerHistoryItem> career;
  final String? contractsError;
  final String? careerError;

  const LifecycleProfileState({
    this.status = LoadStatus.initial,
    this.contracts,
    this.career = const [],
    this.contractsError,
    this.careerError,
  });

  bool get isEmpty =>
      (contracts == null || (contracts!.activeContract == null && contracts!.contracts.isEmpty)) &&
      career.isEmpty;

  @override
  List<Object?> get props => [status, contracts, career, contractsError, careerError];
}

class LifecycleProfileCubit extends Cubit<LifecycleProfileState> {
  final LifecycleRepository _repository;

  LifecycleProfileCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const LifecycleProfileState());

  Future<void> load() async {
    emit(const LifecycleProfileState(status: LoadStatus.loading));
    ContractOverviewModel? contracts;
    var career = <CareerHistoryItem>[];
    String? contractsError;
    String? careerError;

    Future<void> loadContracts() async {
      try {
        contracts = await _repository.getMyContracts();
      } on ApiException catch (e) {
        contractsError = e.message;
      }
    }

    Future<void> loadCareer() async {
      try {
        career = await _repository.getMyCareerHistory();
      } on ApiException catch (e) {
        careerError = e.message;
      }
    }

    await Future.wait([loadContracts(), loadCareer()]);

    final allFailed = contractsError != null && careerError != null;
    emit(
      LifecycleProfileState(
        status: allFailed ? LoadStatus.failure : LoadStatus.success,
        contracts: contracts,
        career: career,
        contractsError: contractsError,
        careerError: careerError,
      ),
    );
  }
}
