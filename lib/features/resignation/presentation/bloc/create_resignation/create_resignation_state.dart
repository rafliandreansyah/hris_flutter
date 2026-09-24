import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';

enum CreateResignationStatus {
  initial,
  loadingInitial,
  initialLoaded,
  submitting,
  success,
  failure,
}

class CreateResignationState extends Equatable {
  final CreateResignationStatus status;
  final ResignationInitialFormModel? initialData;
  final DateTime? selectedEffectiveDate;
  final bool isEarlyNotice;
  final String earlyNoticeReason;
  final String selectedCategory;
  final String reasonNotes;
  final ResignationColleagueModel? selectedColleague;
  final String handoverNotes;
  final XFile? file;
  final bool isAgreed;
  final String? errorMessage;

  const CreateResignationState({
    this.status = CreateResignationStatus.initial,
    this.initialData,
    this.selectedEffectiveDate,
    this.isEarlyNotice = false,
    this.earlyNoticeReason = '',
    this.selectedCategory = 'career_advancement',
    this.reasonNotes = '',
    this.selectedColleague,
    this.handoverNotes = '',
    this.file,
    this.isAgreed = false,
    this.errorMessage,
  });

  int get requiredNoticePeriodDays =>
      initialData?.companyPolicy.effectiveNoticePeriodDays ?? 30;

  int get daysDiff {
    if (selectedEffectiveDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      selectedEffectiveDate!.year,
      selectedEffectiveDate!.month,
      selectedEffectiveDate!.day,
    );
    return target.difference(today).inDays;
  }

  bool get isEarlyNoticeTriggered {
    if (selectedEffectiveDate == null) return false;
    return daysDiff < requiredNoticePeriodDays;
  }

  bool get canSubmit {
    if (selectedEffectiveDate == null) return false;
    if (reasonNotes.trim().isEmpty) return false;
    if (selectedCategory.trim().isEmpty) return false;
    if (isEarlyNoticeTriggered) {
      if (!isEarlyNotice) return false;
      if (earlyNoticeReason.trim().isEmpty) return false;
    }
    if (!isAgreed) return false;
    return true;
  }

  CreateResignationState copyWith({
    CreateResignationStatus? status,
    ResignationInitialFormModel? initialData,
    DateTime? selectedEffectiveDate,
    bool? isEarlyNotice,
    String? earlyNoticeReason,
    String? selectedCategory,
    String? reasonNotes,
    ResignationColleagueModel? selectedColleague,
    bool clearColleague = false,
    String? handoverNotes,
    XFile? file,
    bool clearFile = false,
    bool? isAgreed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateResignationState(
      status: status ?? this.status,
      initialData: initialData ?? this.initialData,
      selectedEffectiveDate:
          selectedEffectiveDate ?? this.selectedEffectiveDate,
      isEarlyNotice: isEarlyNotice ?? this.isEarlyNotice,
      earlyNoticeReason: earlyNoticeReason ?? this.earlyNoticeReason,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      reasonNotes: reasonNotes ?? this.reasonNotes,
      selectedColleague: clearColleague
          ? null
          : (selectedColleague ?? this.selectedColleague),
      handoverNotes: handoverNotes ?? this.handoverNotes,
      file: clearFile ? null : (file ?? this.file),
      isAgreed: isAgreed ?? this.isAgreed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        initialData,
        selectedEffectiveDate,
        isEarlyNotice,
        earlyNoticeReason,
        selectedCategory,
        reasonNotes,
        selectedColleague,
        handoverNotes,
        file,
        isAgreed,
        errorMessage,
      ];
}
