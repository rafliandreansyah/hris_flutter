import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';

/// Repository palsu: semua perilaku diatur lewat field; panggilan dicatat untuk asersi.
class FakeLifecycleRepository implements LifecycleRepository {
  ApiException? error;
  ApiException? saveError;
  ApiException? submitError;
  ApiException? ackError;
  ApiException? contractsError;
  ApiException? careerError;

  EvaluationAssignedPage assignedPage = const EvaluationAssignedPage(
    items: [],
    total: 0,
    page: 1,
    totalPages: 1,
  );
  EvaluationForm? form;
  List<MyEvaluationItem> myEvaluations = const [];
  MyEvaluationDetail? myDetail;
  MyEvaluationDetail? myDetailAfterAck;
  ContractOverviewModel contracts = const ContractOverviewModel();
  List<CareerHistoryItem> career = const [];
  OffboardingStatusModel? offboarding;
  OnboardingProgressModel? onboarding;
  List<LifecycleTaskModel> tasks = const [];

  final List<List<EvaluationAnswer>> savedAnswers = [];
  final List<String?> savedProposals = [];
  final List<String> assignedCalls = [];
  final List<int> assignedPages = [];
  final List<String> completedTasks = [];
  int ackCalls = 0;
  int submitCalls = 0;

  @override
  Future<EvaluationAssignedPage> getAssignedEvaluations({
    String status = 'open',
    int page = 1,
    int size = 10,
  }) async {
    if (error != null) throw error!;
    assignedCalls.add(status);
    assignedPages.add(page);
    return assignedPage;
  }

  @override
  Future<EvaluationForm> getEvaluationForm(String id) async {
    if (error != null) throw error!;
    return form!;
  }

  @override
  Future<void> saveEvaluationAnswers(
    String id, {
    required List<EvaluationAnswer> answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) async {
    if (saveError != null) throw saveError!;
    savedAnswers.add(answers);
    savedProposals.add(evaluatorProposal);
  }

  @override
  Future<EvaluationSubmitResult> submitEvaluation(
    String id, {
    List<EvaluationAnswer>? answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) async {
    submitCalls++;
    if (submitError != null) throw submitError!;
    return const EvaluationSubmitResult(
      id: 'e1',
      status: 'submitted',
      overallScore: 4.6,
      bandLabel: 'Sangat Memuaskan',
    );
  }

  @override
  Future<List<MyEvaluationItem>> getMyEvaluations() async {
    if (error != null) throw error!;
    return myEvaluations;
  }

  @override
  Future<MyEvaluationDetail> getMyEvaluation(String id) async {
    if (error != null) throw error!;
    return (ackCalls > 0 ? myDetailAfterAck : null) ?? myDetail!;
  }

  @override
  Future<DateTime?> acknowledgeEvaluation(String id, {String? comment}) async {
    ackCalls++;
    if (ackError != null) throw ackError!;
    return DateTime(2026, 11, 2);
  }

  @override
  Future<ContractOverviewModel> getMyContracts() async {
    if (contractsError != null) throw contractsError!;
    return contracts;
  }

  @override
  Future<List<CareerHistoryItem>> getMyCareerHistory() async {
    if (careerError != null) throw careerError!;
    return career;
  }

  @override
  Future<OffboardingStatusModel?> getMyOffboarding() async => offboarding;

  @override
  Future<OnboardingProgressModel?> getMyOnboarding() async {
    if (error != null) throw error!;
    return onboarding;
  }

  @override
  Future<List<LifecycleTaskModel>> getMyTasks({String status = 'pending'}) async {
    if (error != null) throw error!;
    return tasks;
  }

  @override
  Future<void> completeTask(String id, {String? notes, String? attachmentUrl}) async {
    if (error != null) throw error!;
    completedTasks.add(id);
  }
}
