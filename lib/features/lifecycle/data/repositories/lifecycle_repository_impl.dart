import 'package:hris_flutter/features/lifecycle/data/datasources/lifecycle_remote_datasource.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';

class LifecycleRepositoryImpl implements LifecycleRepository {
  final LifecycleRemoteDataSource _ds;

  LifecycleRepositoryImpl({LifecycleRemoteDataSource? remoteDataSource})
      : _ds = remoteDataSource ?? LifecycleRemoteDataSource();

  @override
  Future<EvaluationAssignedPage> getAssignedEvaluations({
    String status = 'open',
    int page = 1,
    int size = 10,
  }) =>
      _ds.getAssignedEvaluations(status: status, page: page, size: size);

  @override
  Future<EvaluationForm> getEvaluationForm(String id) => _ds.getEvaluationForm(id);

  @override
  Future<void> saveEvaluationAnswers(
    String id, {
    required List<EvaluationAnswer> answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) =>
      _ds.saveEvaluationAnswers(
        id,
        answers: answers,
        evaluatorProposal: evaluatorProposal,
        evaluatorNotes: evaluatorNotes,
      );

  @override
  Future<EvaluationSubmitResult> submitEvaluation(
    String id, {
    List<EvaluationAnswer>? answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) =>
      _ds.submitEvaluation(
        id,
        answers: answers,
        evaluatorProposal: evaluatorProposal,
        evaluatorNotes: evaluatorNotes,
      );

  @override
  Future<List<MyEvaluationItem>> getMyEvaluations() => _ds.getMyEvaluations();

  @override
  Future<MyEvaluationDetail> getMyEvaluation(String id) => _ds.getMyEvaluation(id);

  @override
  Future<DateTime?> acknowledgeEvaluation(String id, {String? comment}) =>
      _ds.acknowledgeEvaluation(id, comment: comment);

  @override
  Future<ContractOverviewModel> getMyContracts() => _ds.getMyContracts();

  @override
  Future<List<TeamExpiringContract>> getTeamExpiringContracts({int days = 30}) =>
      _ds.getTeamExpiringContracts(days: days);

  @override
  Future<List<CareerHistoryItem>> getMyCareerHistory() => _ds.getMyCareerHistory();

  @override
  Future<OffboardingStatusModel?> getMyOffboarding() => _ds.getMyOffboarding();

  @override
  Future<OnboardingProgressModel?> getMyOnboarding() => _ds.getMyOnboarding();

  @override
  Future<List<LifecycleTaskModel>> getMyTasks({String status = 'pending'}) =>
      _ds.getMyTasks(status: status);

  @override
  Future<void> completeTask(String id, {String? notes, String? attachmentUrl}) =>
      _ds.completeTask(id, notes: notes, attachmentUrl: attachmentUrl);
}
