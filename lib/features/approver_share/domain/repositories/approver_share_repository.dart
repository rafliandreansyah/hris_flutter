import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';

abstract class ApproverShareRepository {
  Future<List<ApproverModel>> getApprovers({
    required String module,
    required String requestId,
  });
}
