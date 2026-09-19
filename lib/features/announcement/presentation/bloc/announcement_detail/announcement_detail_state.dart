import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';

enum AnnouncementDetailStatus { initial, loading, success, failure }

class AnnouncementDetailState extends Equatable {
  final AnnouncementDetailStatus status;
  final AnnouncementDetailModel? detail;
  final bool isAcknowledging;
  final bool isAcknowledgedSuccess;
  final String? errorMessage;
  final String? actionMessage;

  const AnnouncementDetailState({
    this.status = AnnouncementDetailStatus.initial,
    this.detail,
    this.isAcknowledging = false,
    this.isAcknowledgedSuccess = false,
    this.errorMessage,
    this.actionMessage,
  });

  AnnouncementDetailState copyWith({
    AnnouncementDetailStatus? status,
    AnnouncementDetailModel? detail,
    bool? isAcknowledging,
    bool? isAcknowledgedSuccess,
    String? errorMessage,
    String? actionMessage,
  }) {
    return AnnouncementDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isAcknowledging: isAcknowledging ?? this.isAcknowledging,
      isAcknowledgedSuccess:
          isAcknowledgedSuccess ?? this.isAcknowledgedSuccess,
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        detail,
        isAcknowledging,
        isAcknowledgedSuccess,
        errorMessage,
        actionMessage,
      ];
}
