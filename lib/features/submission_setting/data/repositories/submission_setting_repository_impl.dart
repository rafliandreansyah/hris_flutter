import 'package:hris_flutter/features/submission_setting/data/datasources/submission_setting_remote_datasource.dart';
import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';
import 'package:hris_flutter/features/submission_setting/domain/repositories/submission_setting_repository.dart';

class SubmissionSettingRepositoryImpl implements SubmissionSettingRepository {
  final SubmissionSettingRemoteDataSource _remote;

  SubmissionSettingRepositoryImpl({SubmissionSettingRemoteDataSource? remote})
      : _remote = remote ?? SubmissionSettingRemoteDataSourceImpl();

  @override
  Future<SubmissionSettingModel> getSubmissionSetting() => _remote.getSubmissionSetting();
}
