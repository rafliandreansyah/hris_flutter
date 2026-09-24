import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class SubmitResignationRequestModel {
  final String effectiveDate;
  final String reasonCategory;
  final String reasonNotes;
  final bool isEarlyNotice;
  final String? earlyNoticeReason;
  final String? handoverToEmployeeId;
  final String? handoverNotes;
  final XFile? file;
  final String? resignationLetterUrl;

  const SubmitResignationRequestModel({
    required this.effectiveDate,
    required this.reasonCategory,
    required this.reasonNotes,
    this.isEarlyNotice = false,
    this.earlyNoticeReason,
    this.handoverToEmployeeId,
    this.handoverNotes,
    this.file,
    this.resignationLetterUrl,
  });

  /// Mengonversi request ke [FormData] untuk pengiriman multipart/form-data.
  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      'effectiveDate': effectiveDate,
      'reasonCategory': reasonCategory,
      'reasonNotes': reasonNotes,
      'isEarlyNotice': isEarlyNotice.toString(),
    };

    if (earlyNoticeReason != null && earlyNoticeReason!.trim().isNotEmpty) {
      map['earlyNoticeReason'] = earlyNoticeReason!.trim();
    }
    if (handoverToEmployeeId != null &&
        handoverToEmployeeId!.trim().isNotEmpty) {
      map['handoverToEmployeeId'] = handoverToEmployeeId!.trim();
    }
    if (handoverNotes != null && handoverNotes!.trim().isNotEmpty) {
      map['handoverNotes'] = handoverNotes!.trim();
    }
    if (resignationLetterUrl != null &&
        resignationLetterUrl!.trim().isNotEmpty) {
      map['resignationLetterUrl'] = resignationLetterUrl!.trim();
    }

    final formData = FormData.fromMap(map);

    if (file != null) {
      final fileName = file!.path.split('/').last;
      final bytes = await file!.readAsBytes();
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            bytes,
            filename: fileName,
          ),
        ),
      );
    }

    return formData;
  }
}
