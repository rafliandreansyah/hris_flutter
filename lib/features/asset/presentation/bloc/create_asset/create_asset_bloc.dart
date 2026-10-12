import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/create_asset/create_asset_state.dart';

class CreateAssetBloc extends Bloc<CreateAssetEvent, CreateAssetState> {
  final AssetRepository _repository;

  CreateAssetBloc({AssetRepository? repository})
      : _repository = repository ?? AssetRepositoryImpl(),
        super(const CreateAssetState()) {
    on<CreateAssetStarted>(_onStarted);
    on<CreateAssetSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateAssetStarted event,
    Emitter<CreateAssetState> emit,
  ) async {
    emit(state.copyWith(
      status: CreateAssetStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final categories = await _repository.getAssetCategories();
      emit(state.copyWith(
        status: CreateAssetStatus.success,
        categories: categories,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateAssetStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateAssetStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitted(
    CreateAssetSubmitted event,
    Emitter<CreateAssetState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await _repository.createAsset(event.payload);

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        successMessage: 'Unit aset baru berhasil didaftarkan.',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
