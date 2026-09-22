import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

class DisburseActionState extends Equatable {
  final String method; // 'manual_transfer', 'cash', 'payroll'
  final XFile? proofFile;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const DisburseActionState({
    this.method = 'manual_transfer',
    this.proofFile,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  DisburseActionState copyWith({
    String? method,
    XFile? proofFile,
    bool clearProofFile = false,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DisburseActionState(
      method: method ?? this.method,
      proofFile: clearProofFile ? null : (proofFile ?? this.proofFile),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        method,
        proofFile,
        isSubmitting,
        isSuccess,
        errorMessage,
      ];
}
