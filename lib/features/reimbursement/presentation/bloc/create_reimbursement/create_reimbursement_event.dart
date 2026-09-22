import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';

abstract class CreateReimbursementEvent extends Equatable {
  const CreateReimbursementEvent();

  @override
  List<Object?> get props => [];
}

class CreateReimbursementStarted extends CreateReimbursementEvent {
  const CreateReimbursementStarted();
}

class CreateReimbursementTypeChanged extends CreateReimbursementEvent {
  final String type;
  const CreateReimbursementTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class CreateReimbursementCashAdvanceSelected extends CreateReimbursementEvent {
  final String? cashAdvanceId;
  const CreateReimbursementCashAdvanceSelected(this.cashAdvanceId);

  @override
  List<Object?> get props => [cashAdvanceId];
}

class CreateReimbursementCashAdvanceObjectSelected extends CreateReimbursementEvent {
  final ExpenseFeedItemModel cashAdvance;
  const CreateReimbursementCashAdvanceObjectSelected(this.cashAdvance);

  @override
  List<Object?> get props => [cashAdvance];
}

class CreateReimbursementItemAdded extends CreateReimbursementEvent {
  final Map<String, dynamic> item;
  const CreateReimbursementItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class CreateReimbursementItemRemoved extends CreateReimbursementEvent {
  final int index;
  const CreateReimbursementItemRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

class CreateReimbursementFileChanged extends CreateReimbursementEvent {
  final XFile? file;
  const CreateReimbursementFileChanged(this.file);

  @override
  List<Object?> get props => [file];
}

class CreateReimbursementSubmitted extends CreateReimbursementEvent {
  final String title;
  final String? description;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final List<XFile>? files;

  const CreateReimbursementSubmitted({
    required this.title,
    this.description,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.files,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        bankName,
        bankAccountNumber,
        bankAccountHolder,
        files,
      ];
}
