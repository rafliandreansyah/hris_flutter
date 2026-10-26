import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';

abstract class LifecycleRepository {
  // Evaluasi — penilai
  Future<EvaluationAssignedPage> getAssignedEvaluations({
    String status = 'open',
    int page = 1,
    int size = 10,
  });
  Future<EvaluationForm> getEvaluationForm(String id);
  Future<void> saveEvaluationAnswers(
    String id, {
    required List<EvaluationAnswer> answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  });
  Future<EvaluationSubmitResult> submitEvaluation(
    String id, {
    List<EvaluationAnswer>? answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  });

  // Evaluasi — karyawan
  Future<List<MyEvaluationItem>> getMyEvaluations();
  Future<MyEvaluationDetail> getMyEvaluation(String id);
  Future<DateTime?> acknowledgeEvaluation(String id, {String? comment});

  // Profil
  Future<ContractOverviewModel> getMyContracts();
  Future<List<TeamExpiringContract>> getTeamExpiringContracts({int days = 30});
  Future<List<CareerHistoryItem>> getMyCareerHistory();

  // Offboarding / onboarding / tugas
  Future<OffboardingStatusModel?> getMyOffboarding();
  Future<OnboardingProgressModel?> getMyOnboarding();
  Future<List<LifecycleTaskModel>> getMyTasks({String status = 'pending'});
  Future<void> completeTask(String id, {String? notes, String? attachmentUrl});
}
