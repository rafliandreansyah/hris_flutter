import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';

abstract class SubmissionSettingRepository {
  Future<SubmissionSettingModel> getSubmissionSetting();
}
