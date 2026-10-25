import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';
import 'package:hris_flutter/features/submission_setting/data/repositories/submission_setting_repository_impl.dart';
import 'package:hris_flutter/features/submission_setting/domain/repositories/submission_setting_repository.dart';

enum SubmissionSettingStatus { initial, loading, loaded, failure }

class SubmissionSettingState extends Equatable {
  final SubmissionSettingStatus status;
  final SubmissionSettingModel? data;
  final String? message;

  const SubmissionSettingState({
    this.status = SubmissionSettingStatus.initial,
    this.data,
    this.message,
  });

  @override
  List<Object?> get props => [status, data, message];
}

/// Menyimpan setelan kuota & batas tanggal pengajuan dari perusahaan karyawan.
/// Data lama dipertahankan saat refresh gagal, sehingga form tetap memakai batas terakhir yang diketahui.
class SubmissionSettingCubit extends Cubit<SubmissionSettingState> {
  final SubmissionSettingRepository _repository;

  SubmissionSettingCubit({SubmissionSettingRepository? repository})
      : _repository = repository ?? SubmissionSettingRepositoryImpl(),
        super(const SubmissionSettingState());

  /// Mengambil cubit bila tersedia di pohon widget; null jika tidak (mis. pada widget test).
  static SubmissionSettingCubit? maybeOf(BuildContext context) {
    try {
      return BlocProvider.of<SubmissionSettingCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  /// Batas tanggal terakhir yang diketahui untuk [type]; null bila belum dimuat / tidak ada cubit.
  static DateWindowModel? windowOf(BuildContext context, SubmissionWindowType type) =>
      maybeOf(context)?.state.data?.windowFor(type);

  Future<void> load() async {
    emit(SubmissionSettingState(
      status: SubmissionSettingStatus.loading,
      data: state.data,
    ));
    try {
      final data = await _repository.getSubmissionSetting();
      emit(SubmissionSettingState(status: SubmissionSettingStatus.loaded, data: data));
    } on ApiException catch (e) {
      emit(SubmissionSettingState(
        status: SubmissionSettingStatus.failure,
        data: state.data,
        message: e.message,
      ));
    } catch (e) {
      emit(SubmissionSettingState(
        status: SubmissionSettingStatus.failure,
        data: state.data,
        message: e.toString(),
      ));
    }
  }
}
