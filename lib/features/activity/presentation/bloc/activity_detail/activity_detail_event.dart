import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:image_picker/image_picker.dart';

abstract class ActivityDetailEvent extends Equatable {
  const ActivityDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat detail screen diinisialisasi
class ActivityDetailStarted extends ActivityDetailEvent {
  final ActivityItem? initialActivity;
  final String? activityId;

  const ActivityDetailStarted({
    this.initialActivity,
    this.activityId,
  });

  @override
  List<Object?> get props => [initialActivity, activityId];
}

/// Event memuat detail data dari API GET /activity/{id}
class ActivityDetailFetchRequested extends ActivityDetailEvent {
  final String id;
  final bool showLoading;

  const ActivityDetailFetchRequested({
    required this.id,
    this.showLoading = true,
  });

  @override
  List<Object?> get props => [id, showLoading];
}

/// Event menyelesaikan aktivitas kerja (PATCH /activity/{id}/finish)
class ActivityDetailFinishSubmitted extends ActivityDetailEvent {
  final String id;
  final String notes;
  final XFile? file;

  const ActivityDetailFinishSubmitted({
    required this.id,
    required this.notes,
    this.file,
  });

  @override
  List<Object?> get props => [id, notes, file];
}

/// Event membatalkan aktivitas kerja (PATCH /activity/{id}/cancel)
class ActivityDetailCancelSubmitted extends ActivityDetailEvent {
  final String id;
  final String notes;
  final XFile? file;

  const ActivityDetailCancelSubmitted({
    required this.id,
    required this.notes,
    this.file,
  });

  @override
  List<Object?> get props => [id, notes, file];
}
