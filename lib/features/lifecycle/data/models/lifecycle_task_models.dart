import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';

class LifecycleTaskModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String type; // manual | document_upload | acknowledgment | system_check
  final String? systemCheckKey;
  final String assigneeRole;
  final bool isRequired;
  final String status; // pending | in_progress | done | skipped | blocked
  final DateTime? dueDate;
  final bool isOverdue;
  final String subjectName;
  final bool isSubjectMe;
  final bool isMine;
  final bool canComplete;
  final DateTime? completedAt;
  final String parentKind;
  final String parentId;

  const LifecycleTaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.systemCheckKey,
    required this.assigneeRole,
    required this.isRequired,
    required this.status,
    this.dueDate,
    this.isOverdue = false,
    this.subjectName = '',
    this.isSubjectMe = false,
    this.isMine = false,
    this.canComplete = false,
    this.completedAt,
    this.parentKind = '',
    this.parentId = '',
  });

  bool get isClosed => status == 'done' || status == 'skipped';

  factory LifecycleTaskModel.fromJson(Map<String, dynamic> j) {
    final parent = (j['parent'] as Map<String, dynamic>?) ?? const {};
    return LifecycleTaskModel(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      description: j['description'] as String?,
      type: j['type']?.toString() ?? 'manual',
      systemCheckKey: j['systemCheckKey'] as String?,
      assigneeRole: j['assigneeRole']?.toString() ?? '',
      isRequired: j['isRequired'] as bool? ?? false,
      status: j['status']?.toString() ?? 'pending',
      dueDate: lcDate(j['dueDate']),
      isOverdue: j['isOverdue'] as bool? ?? false,
      subjectName: j['subjectName']?.toString() ?? '',
      isSubjectMe: j['isSubjectMe'] as bool? ?? false,
      isMine: j['isMine'] as bool? ?? false,
      canComplete: j['canComplete'] as bool? ?? false,
      completedAt: lcDate(j['completedAt']),
      parentKind: parent['kind']?.toString() ?? '',
      parentId: parent['id']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, status, canComplete, completedAt];
}

class LifecycleProgress extends Equatable {
  final int done;
  final int total;
  final int requiredDone;
  final int requiredTotal;

  const LifecycleProgress({
    this.done = 0,
    this.total = 0,
    this.requiredDone = 0,
    this.requiredTotal = 0,
  });

  factory LifecycleProgress.fromJson(Map<String, dynamic>? j) =>
      LifecycleProgress(
        done: lcInt(j?['done']),
        total: lcInt(j?['total']),
        requiredDone: lcInt(j?['requiredDone']),
        requiredTotal: lcInt(j?['requiredTotal']),
      );

  @override
  List<Object?> get props => [done, total, requiredDone, requiredTotal];
}

class OnboardingProgressModel extends Equatable {
  final String id;
  final String referenceNumber;
  final String status;
  final DateTime? joinDate;
  final bool isRehire;
  final LifecycleProgress progress;
  final List<LifecycleTaskModel> myTasks;

  const OnboardingProgressModel({
    required this.id,
    required this.referenceNumber,
    required this.status,
    this.joinDate,
    this.isRehire = false,
    required this.progress,
    this.myTasks = const [],
  });

  /// Kartu dashboard hanya tampil bila masih ada pekerjaan yang belum selesai.
  bool get hasOpenWork => progress.done < progress.total;

  factory OnboardingProgressModel.fromJson(Map<String, dynamic> j) =>
      OnboardingProgressModel(
        id: j['id']?.toString() ?? '',
        referenceNumber: j['referenceNumber']?.toString() ?? '-',
        status: j['status']?.toString() ?? '',
        joinDate: lcDate(j['joinDate']),
        isRehire: j['isRehire'] as bool? ?? false,
        progress: LifecycleProgress.fromJson(
          j['progress'] as Map<String, dynamic>?,
        ),
        myTasks: lcList(j['myTasks']).map(LifecycleTaskModel.fromJson).toList(),
      );

  @override
  List<Object?> get props => [id, status, progress, myTasks];
}

class PaklaringInfo extends Equatable {
  final bool issued;
  final String? number;
  final String? url;
  final DateTime? issuedAt;

  const PaklaringInfo({
    this.issued = false,
    this.number,
    this.url,
    this.issuedAt,
  });

  factory PaklaringInfo.fromJson(Map<String, dynamic>? j) => PaklaringInfo(
        issued: j?['issued'] as bool? ?? false,
        number: j?['number'] as String?,
        url: j?['url'] as String?,
        issuedAt: lcDate(j?['issuedAt']),
      );

  @override
  List<Object?> get props => [issued, number, url, issuedAt];
}

class OffboardingStatusModel extends Equatable {
  final String id;
  final String referenceNumber;
  final String exitType;
  final String status;
  final DateTime? lastWorkingDate;
  final DateTime? effectiveExitDate;
  final DateTime? accessRevokedAt;
  final LifecycleProgress progress;
  final List<LifecycleTaskModel> tasks;
  final PaklaringInfo paklaring;

  const OffboardingStatusModel({
    required this.id,
    required this.referenceNumber,
    required this.exitType,
    required this.status,
    this.lastWorkingDate,
    this.effectiveExitDate,
    this.accessRevokedAt,
    required this.progress,
    this.tasks = const [],
    this.paklaring = const PaklaringInfo(),
  });

  factory OffboardingStatusModel.fromJson(Map<String, dynamic> j) =>
      OffboardingStatusModel(
        id: j['id']?.toString() ?? '',
        referenceNumber: j['referenceNumber']?.toString() ?? '-',
        exitType: j['exitType']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        lastWorkingDate: lcDate(j['lastWorkingDate']),
        effectiveExitDate: lcDate(j['effectiveExitDate']),
        accessRevokedAt: lcDate(j['accessRevokedAt']),
        progress: LifecycleProgress.fromJson(
          j['progress'] as Map<String, dynamic>?,
        ),
        tasks: lcList(j['tasks']).map(LifecycleTaskModel.fromJson).toList(),
        paklaring: PaklaringInfo.fromJson(j['paklaring'] as Map<String, dynamic>?),
      );

  @override
  List<Object?> get props => [id, status, progress, tasks, paklaring];
}
