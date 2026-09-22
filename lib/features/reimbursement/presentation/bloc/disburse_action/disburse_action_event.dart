import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class DisburseActionEvent extends Equatable {
  const DisburseActionEvent();

  @override
  List<Object?> get props => [];
}

class DisburseMethodChanged extends DisburseActionEvent {
  final String method; // 'manual_transfer', 'cash', 'payroll'
  const DisburseMethodChanged(this.method);

  @override
  List<Object?> get props => [method];
}

class DisburseProofFileChanged extends DisburseActionEvent {
  final XFile? file;
  const DisburseProofFileChanged(this.file);

  @override
  List<Object?> get props => [file];
}

class DisburseSubmitted extends DisburseActionEvent {
  final String claimId;
  final String? paymentReference;
  final String? notes;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? payrollPeriodId;

  const DisburseSubmitted({
    required this.claimId,
    this.paymentReference,
    this.notes,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.payrollPeriodId,
  });

  @override
  List<Object?> get props => [
        claimId,
        paymentReference,
        notes,
        bankName,
        bankAccountNumber,
        bankAccountHolder,
        payrollPeriodId,
      ];
}
