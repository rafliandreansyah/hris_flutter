import 'package:hris_flutter/core/utils/app_error_message.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_state.dart';

class AssetDetailBloc extends Bloc<AssetDetailEvent, AssetDetailState> {
  final AssetRepository _repository;
  final SecureStorageService _storageService;
  String? _currentAssetId;

  AssetDetailBloc({
    AssetRepository? repository,
    SecureStorageService? storageService,
  })  : _repository = repository ?? AssetRepositoryImpl(),
        _storageService = storageService ?? SecureStorageService.instance,
        super(const AssetDetailState()) {
    on<AssetDetailStarted>(_onStarted);
    on<AssetDetailRefreshed>(_onRefreshed);
    on<AssetDetailAssignmentApproved>(_onAssignmentApproved);
    on<AssetDetailAssignmentRejected>(_onAssignmentRejected);
    on<AssetDetailDirectTransferred>(_onDirectTransferred);
    on<AssetDetailPoolHandedOver>(_onPoolHandedOver);
  }

  Future<void> _onStarted(
    AssetDetailStarted event,
    Emitter<AssetDetailState> emit,
  ) async {
    _currentAssetId = event.assetId;
    emit(state.copyWith(
      status: AssetDetailStatus.loading,
      clearError: true,
      clearActionMessage: true,
    ));

    final canHandover =
        _storageService.hasPermissionInMemory(AppPermissions.assetHandover);
    final canCreate =
        _storageService.hasPermissionInMemory(AppPermissions.assetCreate);
    final employeeId = await _storageService.getEmployeeId();

    try {
      final asset = await _repository.getAssetDetail(event.assetId);

      emit(state.copyWith(
        status: AssetDetailStatus.success,
        asset: asset,
        canHandover: canHandover,
        canCreate: canCreate,
        currentEmployeeId: employeeId,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AssetDetailStatus.failure,
        errorMessage: e.message,
        errorStatusCode: e.statusCode,
        canHandover: canHandover,
        canCreate: canCreate,
        currentEmployeeId: employeeId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetDetailStatus.failure,
        errorMessage: AppErrorMessage.from(e),
        canHandover: canHandover,
        canCreate: canCreate,
        currentEmployeeId: employeeId,
      ));
    }
  }

  Future<void> _onRefreshed(
    AssetDetailRefreshed event,
    Emitter<AssetDetailState> emit,
  ) async {
    final assetId = _currentAssetId ?? state.asset?.id;
    if (assetId == null) return;

    try {
      final asset = await _repository.getAssetDetail(assetId);
      emit(state.copyWith(
        status: AssetDetailStatus.success,
        asset: asset,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(errorMessage: AppErrorMessage.from(e)));
    }
  }

  Future<void> _onAssignmentApproved(
    AssetDetailAssignmentApproved event,
    Emitter<AssetDetailState> emit,
  ) async {
    emit(state.copyWith(
      actionStatus: AssetDetailActionStatus.loading,
      clearActionMessage: true,
    ));

    try {
      await _repository.approveAssignment(
        assignmentId: event.assignmentId,
        conditionOnCheckin: event.conditionOnCheckin,
        recipientNotes: event.notes,
        signatureUrl: event.signatureUrl,
        handoverPhotoUrl: event.handoverPhotoUrl,
      );

      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.success,
        actionMessage:
            'Fasilitas berhasil diterima dan menjadi tanggung jawab Anda.',
      ));

      add(const AssetDetailRefreshed());
    } on ApiException catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssignmentRejected(
    AssetDetailAssignmentRejected event,
    Emitter<AssetDetailState> emit,
  ) async {
    emit(state.copyWith(
      actionStatus: AssetDetailActionStatus.loading,
      clearActionMessage: true,
    ));

    try {
      await _repository.rejectAssignment(
        assignmentId: event.assignmentId,
        rejectionReason: event.reason,
      );

      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.success,
        actionMessage: 'Penyerahan fasilitas telah ditolak.',
      ));

      add(const AssetDetailRefreshed());
    } on ApiException catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDirectTransferred(
    AssetDetailDirectTransferred event,
    Emitter<AssetDetailState> emit,
  ) async {
    final assetId = _currentAssetId ?? state.asset?.id;
    if (assetId == null) return;

    emit(state.copyWith(
      actionStatus: AssetDetailActionStatus.loading,
      clearActionMessage: true,
    ));

    try {
      await _repository.directTransferAsset(assetId, event.payload);

      const successMsg =
          'Permintaan alih tangan berhasil dikirim, menunggu konfirmasi penerima.';

      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.success,
        actionMessage: successMsg,
      ));

      add(const AssetDetailRefreshed());
    } on ApiException catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPoolHandedOver(
    AssetDetailPoolHandedOver event,
    Emitter<AssetDetailState> emit,
  ) async {
    final assetId = _currentAssetId ?? state.asset?.id;
    if (assetId == null) return;

    emit(state.copyWith(
      actionStatus: AssetDetailActionStatus.loading,
      clearActionMessage: true,
    ));

    try {
      await _repository.handoverAsset(assetId, event.payload);

      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.success,
        actionMessage: 'Serah terima fasilitas berhasil diproses.',
      ));

      add(const AssetDetailRefreshed());
    } on ApiException catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AssetDetailActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }
}
