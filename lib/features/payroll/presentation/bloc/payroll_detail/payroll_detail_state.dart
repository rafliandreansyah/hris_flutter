import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';

enum PayrollDetailStatus {
  initial,
  loading,
  success,
  failure,
}

class PayrollDetailState extends Equatable {
  final PayrollDetailStatus status;
  final PayrollDetailModel? detail;
  final bool isDownloading;
  final String? downloadedPdfUrl;
  final bool isPrivacyMasked;
  final String? errorMessage;

  const PayrollDetailState({
    this.status = PayrollDetailStatus.initial,
    this.detail,
    this.isDownloading = false,
    this.downloadedPdfUrl,
    this.isPrivacyMasked = true,
    this.errorMessage,
  });

  PayrollDetailState copyWith({
    PayrollDetailStatus? status,
    PayrollDetailModel? detail,
    bool? isDownloading,
    String? downloadedPdfUrl,
    bool clearDownloadedPdfUrl = false,
    bool? isPrivacyMasked,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PayrollDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadedPdfUrl: clearDownloadedPdfUrl
          ? null
          : (downloadedPdfUrl ?? this.downloadedPdfUrl),
      isPrivacyMasked: isPrivacyMasked ?? this.isPrivacyMasked,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        detail,
        isDownloading,
        downloadedPdfUrl,
        isPrivacyMasked,
        errorMessage,
      ];
}
