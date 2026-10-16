import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';

/// Memanggil `/api/v1/lifecycle/*`. Error jaringan/HTTP (404/409/400) sudah dipetakan
/// menjadi [ApiException] dengan pesan dari server oleh [ApiClient].
class LifecycleRemoteDataSource {
  final ApiClient _api;

  LifecycleRemoteDataSource({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  Map<String, dynamic> _root(dynamic raw, String fallback) {
    if (raw is Map<String, dynamic>) return raw;
    throw ApiException(message: fallback);
  }

  dynamic _data(dynamic raw, String fallback) => _root(raw, fallback)['data'];

  Map<String, dynamic> _dataMap(dynamic raw, String fallback) {
    final d = _data(raw, fallback);
    if (d is Map<String, dynamic>) return d;
    throw ApiException(message: fallback);
  }

  Future<EvaluationAssignedPage> getAssignedEvaluations({
    String status = 'open',
    int page = 1,
    int size = 10,
  }) async {
    final res = await _api.get(
      ApiEndpoints.lifecycleEvaluationsAssigned,
      queryParameters: {'status': status, 'page': page, 'size': size},
    );
    return EvaluationAssignedPage.fromJson(
      _root(res.data, 'Gagal memuat daftar penilaian.'),
    );
  }

  Future<EvaluationForm> getEvaluationForm(String id) async {
    final res = await _api.get(ApiEndpoints.lifecycleEvaluation(id));
    return EvaluationForm.fromJson(_dataMap(res.data, 'Gagal memuat form penilaian.'));
  }

  Map<String, dynamic> _answersBody({
    List<EvaluationAnswer>? answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) =>
      {
        if (answers != null) 'answers': answers.map((a) => a.toJson()).toList(),
        'evaluatorProposal': ?evaluatorProposal,
        'evaluatorNotes': ?evaluatorNotes,
      };

  Future<void> saveEvaluationAnswers(
    String id, {
    required List<EvaluationAnswer> answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) async {
    await _api.put(
      ApiEndpoints.lifecycleEvaluationAnswers(id),
      data: _answersBody(
        answers: answers,
        evaluatorProposal: evaluatorProposal,
        evaluatorNotes: evaluatorNotes,
      ),
    );
  }

  Future<EvaluationSubmitResult> submitEvaluation(
    String id, {
    List<EvaluationAnswer>? answers,
    String? evaluatorProposal,
    String? evaluatorNotes,
  }) async {
    final res = await _api.post(
      ApiEndpoints.lifecycleEvaluationSubmit(id),
      data: _answersBody(
        answers: answers,
        evaluatorProposal: evaluatorProposal,
        evaluatorNotes: evaluatorNotes,
      ),
    );
    return EvaluationSubmitResult.fromJson(
      _dataMap(res.data, 'Gagal mengirim penilaian.'),
    );
  }

  Future<List<MyEvaluationItem>> getMyEvaluations() async {
    final res = await _api.get(ApiEndpoints.lifecycleEvaluationsMy);
    return lcList(_data(res.data, 'Gagal memuat hasil evaluasi.'))
        .map(MyEvaluationItem.fromJson)
        .toList();
  }

  Future<MyEvaluationDetail> getMyEvaluation(String id) async {
    final res = await _api.get(ApiEndpoints.lifecycleEvaluationMyDetail(id));
    return MyEvaluationDetail.fromJson(
      _dataMap(res.data, 'Gagal memuat hasil evaluasi.'),
    );
  }

  Future<DateTime?> acknowledgeEvaluation(String id, {String? comment}) async {
    final res = await _api.post(
      ApiEndpoints.lifecycleEvaluationAcknowledge(id),
      data: {if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim()},
    );
    return lcDate(_dataMap(res.data, 'Gagal mengonfirmasi hasil.')['acknowledgedAt']);
  }

  Future<ContractOverviewModel> getMyContracts() async {
    final res = await _api.get(ApiEndpoints.lifecycleContractsMy);
    return ContractOverviewModel.fromJson(
      _dataMap(res.data, 'Gagal memuat data kontrak.'),
    );
  }

  Future<List<CareerHistoryItem>> getMyCareerHistory() async {
    final res = await _api.get(ApiEndpoints.lifecycleCareerHistoryMy);
    return lcList(_data(res.data, 'Gagal memuat riwayat karier.'))
        .map(CareerHistoryItem.fromJson)
        .toList();
  }

  Future<OffboardingStatusModel?> getMyOffboarding() async {
    final res = await _api.get(ApiEndpoints.lifecycleOffboardingMy);
    final d = _data(res.data, 'Gagal memuat status offboarding.');
    return d is Map<String, dynamic> ? OffboardingStatusModel.fromJson(d) : null;
  }

  Future<OnboardingProgressModel?> getMyOnboarding() async {
    final res = await _api.get(ApiEndpoints.lifecycleOnboardingMy);
    final d = _data(res.data, 'Gagal memuat progres onboarding.');
    return d is Map<String, dynamic> ? OnboardingProgressModel.fromJson(d) : null;
  }

  Future<List<LifecycleTaskModel>> getMyTasks({String status = 'pending'}) async {
    final res = await _api.get(
      ApiEndpoints.lifecycleTasksMy,
      queryParameters: {'status': status},
    );
    return lcList(_data(res.data, 'Gagal memuat daftar tugas.'))
        .map(LifecycleTaskModel.fromJson)
        .toList();
  }

  Future<void> completeTask(String id, {String? notes, String? attachmentUrl}) async {
    await _api.post(
      ApiEndpoints.lifecycleTaskComplete(id),
      data: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'attachmentUrl': ?attachmentUrl,
      },
    );
  }
}
