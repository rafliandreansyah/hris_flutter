import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';

/// Fake [LifecycleRepository] untuk widget test yang menanam
/// `LifecycleProfileSection` (mis. EmployeeDetailScreen). Mencegah request
/// jaringan nyata sehingga test deterministik.
///
/// Hanya method profil yang diimplementasikan; method lain melempar
/// [UnimplementedError] bila dipanggil tanpa sengaja.
class FakeLifecycleRepository implements LifecycleRepository {
  ContractOverviewModel contracts = const ContractOverviewModel();
  List<CareerHistoryItem> career = const [];

  @override
  Future<ContractOverviewModel> getMyContracts() async => contracts;

  @override
  Future<List<CareerHistoryItem>> getMyCareerHistory() async => career;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'FakeLifecycleRepository.${invocation.memberName} belum di-stub',
      );
}
