import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';

abstract class CreateResignationEvent extends Equatable {
  const CreateResignationEvent();

  @override
  List<Object?> get props => [];
}

class CreateResignationStarted extends CreateResignationEvent {
  const CreateResignationStarted();
}

class CreateResignationDateChanged extends CreateResignationEvent {
  final DateTime date;

  const CreateResignationDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class CreateResignationEarlyWaiverToggled extends CreateResignationEvent {
  final bool isEarlyNotice;

  const CreateResignationEarlyWaiverToggled(this.isEarlyNotice);

  @override
  List<Object?> get props => [isEarlyNotice];
}

class CreateResignationEarlyReasonChanged extends CreateResignationEvent {
  final String reason;

  const CreateResignationEarlyReasonChanged(this.reason);

  @override
  List<Object?> get props => [reason];
}

class CreateResignationCategoryChanged extends CreateResignationEvent {
  final String category;

  const CreateResignationCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class CreateResignationReasonNotesChanged extends CreateResignationEvent {
  final String notes;

  const CreateResignationReasonNotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class CreateResignationColleagueSelected extends CreateResignationEvent {
  final ResignationColleagueModel? colleague;

  const CreateResignationColleagueSelected(this.colleague);

  @override
  List<Object?> get props => [colleague];
}

class CreateResignationHandoverNotesChanged extends CreateResignationEvent {
  final String notes;

  const CreateResignationHandoverNotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class CreateResignationFileChanged extends CreateResignationEvent {
  final XFile? file;

  const CreateResignationFileChanged(this.file);

  @override
  List<Object?> get props => [file];
}

class CreateResignationAgreementToggled extends CreateResignationEvent {
  final bool isAgreed;

  const CreateResignationAgreementToggled(this.isAgreed);

  @override
  List<Object?> get props => [isAgreed];
}

class CreateResignationSubmitted extends CreateResignationEvent {
  const CreateResignationSubmitted();
}
