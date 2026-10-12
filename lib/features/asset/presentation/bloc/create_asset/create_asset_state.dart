import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';

enum CreateAssetStatus { initial, loading, success, failure }

class CreateAssetState extends Equatable {
  final CreateAssetStatus status;
  final List<AssetCategoryModel> categories;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;

  const CreateAssetState({
    this.status = CreateAssetStatus.initial,
    this.categories = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
  });

  CreateAssetState copyWith({
    CreateAssetStatus? status,
    List<AssetCategoryModel>? categories,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return CreateAssetState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        isSubmitting,
        isSuccess,
        errorMessage,
        successMessage,
      ];
}
