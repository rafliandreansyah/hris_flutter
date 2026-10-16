import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';

class EvaluationEmployeeBrief extends Equatable {
  final String id;
  final String name;
  final String? employeeNumber;
  final String? departmentName;
  final String? positionName;
  final String? photoUrl;

  const EvaluationEmployeeBrief({
    required this.id,
    required this.name,
    this.employeeNumber,
    this.departmentName,
    this.positionName,
    this.photoUrl,
  });

  factory EvaluationEmployeeBrief.fromJson(Map<String, dynamic> j) =>
      EvaluationEmployeeBrief(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '-',
        employeeNumber: j['employeeNumber'] as String?,
        departmentName: j['departmentName'] as String?,
        positionName: j['positionName'] as String?,
        photoUrl: j['photoUrl'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, employeeNumber, departmentName, positionName, photoUrl];
}

class EvaluationAssignedItem extends Equatable {
  final String id;
  final String referenceNumber;
  final String evaluationType;
  final String status;
  final EvaluationEmployeeBrief employee;
  final DateTime? periodEndDate;
  final DateTime? dueDate;
  final DateTime? decisionDeadline;
  final bool isOverdue;
  final double? overallScore;
  final String? bandLabel;

  const EvaluationAssignedItem({
    required this.id,
    required this.referenceNumber,
    required this.evaluationType,
    required this.status,
    required this.employee,
    this.periodEndDate,
    this.dueDate,
    this.decisionDeadline,
    this.isOverdue = false,
    this.overallScore,
    this.bandLabel,
  });

  bool get isOpen => status == 'draft' || status == 'revision_requested';

  factory EvaluationAssignedItem.fromJson(Map<String, dynamic> j) =>
      EvaluationAssignedItem(
        id: j['id']?.toString() ?? '',
        referenceNumber: j['referenceNumber']?.toString() ?? '-',
        evaluationType: j['evaluationType']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        employee: EvaluationEmployeeBrief.fromJson(
          (j['employee'] as Map<String, dynamic>?) ?? const {},
        ),
        periodEndDate: lcDate(j['periodEndDate']),
        dueDate: lcDate(j['dueDate']),
        decisionDeadline: lcDate(j['decisionDeadline']),
        isOverdue: j['isOverdue'] as bool? ?? false,
        overallScore: lcDouble(j['overallScore']),
        bandLabel: j['bandLabel'] as String?,
      );

  @override
  List<Object?> get props => [id, status, dueDate, isOverdue, overallScore];
}

class EvaluationAssignedPage extends Equatable {
  final List<EvaluationAssignedItem> items;
  final int total;
  final int page;
  final int totalPages;

  const EvaluationAssignedPage({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory EvaluationAssignedPage.fromJson(Map<String, dynamic> j) {
    final meta = (j['meta'] as Map<String, dynamic>?) ?? const {};
    return EvaluationAssignedPage(
      items: lcList(j['data']).map(EvaluationAssignedItem.fromJson).toList(),
      total: lcInt(meta['total']),
      page: lcInt(meta['page'], 1),
      totalPages: lcInt(meta['totalPages'], 1),
    );
  }

  @override
  List<Object?> get props => [items, total, page, totalPages];
}

class EvaluationTemplateItem extends Equatable {
  final String id;
  final String code;
  final String title;
  final String? description;
  final bool isRating;
  final double? weight;
  final bool isRequired;

  const EvaluationTemplateItem({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.isRating,
    this.weight,
    required this.isRequired,
  });

  factory EvaluationTemplateItem.fromJson(Map<String, dynamic> j) =>
      EvaluationTemplateItem(
        id: j['id']?.toString() ?? '',
        code: j['code']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        isRating: j['type'] == 'rating',
        weight: lcDouble(j['weight']),
        isRequired: j['isRequired'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, isRating, weight, isRequired];
}

class EvaluationAnswer extends Equatable {
  final String templateItemId;
  final int? score;
  final String? textAnswer;

  const EvaluationAnswer({
    required this.templateItemId,
    this.score,
    this.textAnswer,
  });

  factory EvaluationAnswer.fromJson(Map<String, dynamic> j) => EvaluationAnswer(
        templateItemId: j['templateItemId']?.toString() ?? '',
        score: (j['score'] as num?)?.toInt(),
        textAnswer: j['textAnswer'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'templateItemId': templateItemId,
        'score': score,
        'textAnswer': textAnswer,
      };

  @override
  List<Object?> get props => [templateItemId, score, textAnswer];
}

class EvaluationSupportingMetrics extends Equatable {
  final double attendanceRate;
  final int totalPresent;
  final int totalLate;
  final int activeWarningLetters;

  const EvaluationSupportingMetrics({
    this.attendanceRate = 0,
    this.totalPresent = 0,
    this.totalLate = 0,
    this.activeWarningLetters = 0,
  });

  factory EvaluationSupportingMetrics.fromJson(Map<String, dynamic> j) =>
      EvaluationSupportingMetrics(
        attendanceRate: lcDouble(j['attendanceRate']) ?? 0,
        totalPresent: lcInt(j['totalPresent']),
        totalLate: lcInt(j['totalLate']),
        activeWarningLetters: lcInt(j['activeWarningLetters']),
      );

  @override
  List<Object?> get props =>
      [attendanceRate, totalPresent, totalLate, activeWarningLetters];
}

class EvaluationForm extends Equatable {
  final String id;
  final String referenceNumber;
  final String evaluationType;
  final String status;
  final EvaluationEmployeeBrief employee;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final DateTime? dueDate;
  final bool canEdit;
  final String? revisionNotes;
  final String? evaluatorProposal;
  final String? evaluatorNotes;
  final String templateName;
  final int scaleMin;
  final int scaleMax;
  final Map<String, String> scaleLabels;
  final List<EvaluationTemplateItem> items;
  final List<String> allowedProposals;
  final List<EvaluationAnswer> answers;
  final EvaluationSupportingMetrics metrics;

  const EvaluationForm({
    required this.id,
    required this.referenceNumber,
    required this.evaluationType,
    required this.status,
    required this.employee,
    this.periodStartDate,
    this.periodEndDate,
    this.dueDate,
    required this.canEdit,
    this.revisionNotes,
    this.evaluatorProposal,
    this.evaluatorNotes,
    required this.templateName,
    required this.scaleMin,
    required this.scaleMax,
    this.scaleLabels = const {},
    this.items = const [],
    this.allowedProposals = const [],
    this.answers = const [],
    this.metrics = const EvaluationSupportingMetrics(),
  });

  factory EvaluationForm.fromJson(Map<String, dynamic> j) {
    final tpl = (j['template'] as Map<String, dynamic>?) ?? const {};
    final labels = tpl['scaleLabels'];
    return EvaluationForm(
      id: j['id']?.toString() ?? '',
      referenceNumber: j['referenceNumber']?.toString() ?? '-',
      evaluationType: j['evaluationType']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      employee: EvaluationEmployeeBrief.fromJson(
        (j['employee'] as Map<String, dynamic>?) ?? const {},
      ),
      periodStartDate: lcDate(j['periodStartDate']),
      periodEndDate: lcDate(j['periodEndDate']),
      dueDate: lcDate(j['dueDate']),
      canEdit: j['canEdit'] as bool? ?? false,
      revisionNotes: j['revisionNotes'] as String?,
      evaluatorProposal: j['evaluatorProposal'] as String?,
      evaluatorNotes: j['evaluatorNotes'] as String?,
      templateName: tpl['name']?.toString() ?? '',
      scaleMin: lcInt(tpl['scaleMin'], 1),
      scaleMax: lcInt(tpl['scaleMax'], 5),
      scaleLabels: labels is Map
          ? labels.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      items: lcList(tpl['items']).map(EvaluationTemplateItem.fromJson).toList(),
      allowedProposals: (tpl['allowedProposals'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      answers: lcList(j['answers']).map(EvaluationAnswer.fromJson).toList(),
      metrics: EvaluationSupportingMetrics.fromJson(
        (j['supportingMetrics'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  @override
  List<Object?> get props =>
      [id, status, canEdit, revisionNotes, answers, evaluatorProposal];
}

class EvaluationSubmitResult extends Equatable {
  final String id;
  final String status;
  final double overallScore;
  final String? bandLabel;

  const EvaluationSubmitResult({
    required this.id,
    required this.status,
    required this.overallScore,
    this.bandLabel,
  });

  factory EvaluationSubmitResult.fromJson(Map<String, dynamic> j) =>
      EvaluationSubmitResult(
        id: j['id']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        overallScore: lcDouble(j['overallScore']) ?? 0,
        bandLabel: j['bandLabel'] as String?,
      );

  @override
  List<Object?> get props => [id, status, overallScore, bandLabel];
}

class MyEvaluationItem extends Equatable {
  final String id;
  final String referenceNumber;
  final String evaluationType;
  final String status;
  final DateTime? periodEndDate;
  final DateTime? decidedAt;
  final String? decision;
  final double? overallScore;
  final String? bandLabel;
  final bool acknowledged;

  const MyEvaluationItem({
    required this.id,
    required this.referenceNumber,
    required this.evaluationType,
    required this.status,
    this.periodEndDate,
    this.decidedAt,
    this.decision,
    this.overallScore,
    this.bandLabel,
    this.acknowledged = false,
  });

  factory MyEvaluationItem.fromJson(Map<String, dynamic> j) => MyEvaluationItem(
        id: j['id']?.toString() ?? '',
        referenceNumber: j['referenceNumber']?.toString() ?? '-',
        evaluationType: j['evaluationType']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        periodEndDate: lcDate(j['periodEndDate']),
        decidedAt: lcDate(j['decidedAt']),
        decision: j['decision'] as String?,
        overallScore: lcDouble(j['overallScore']),
        bandLabel: j['bandLabel'] as String?,
        acknowledged: j['acknowledged'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, status, decision, overallScore, acknowledged];
}

class MyEvaluationDetail extends Equatable {
  final MyEvaluationItem summary;
  final DateTime? newContractStartDate;
  final DateTime? newContractEndDate;
  final String? newContractNumber;
  final DateTime? acknowledgedAt;
  final String? employeeComment;
  final bool requiresAcknowledgment;

  const MyEvaluationDetail({
    required this.summary,
    this.newContractStartDate,
    this.newContractEndDate,
    this.newContractNumber,
    this.acknowledgedAt,
    this.employeeComment,
    this.requiresAcknowledgment = false,
  });

  factory MyEvaluationDetail.fromJson(Map<String, dynamic> j) =>
      MyEvaluationDetail(
        summary: MyEvaluationItem.fromJson(j),
        newContractStartDate: lcDate(j['newContractStartDate']),
        newContractEndDate: lcDate(j['newContractEndDate']),
        newContractNumber: j['newContractNumber'] as String?,
        acknowledgedAt: lcDate(j['acknowledgedAt']),
        employeeComment: j['employeeComment'] as String?,
        requiresAcknowledgment: j['requiresAcknowledgment'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [summary, acknowledgedAt, employeeComment, requiresAcknowledgment];
}
