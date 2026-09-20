import 'dart:io';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

/// Request payload untuk pembuatan surat peringatan baru ke `POST /warning-letter`.
class CreateWarningLetterRequest extends Equatable {
  final String employeeId;
  final String warningLetterTypeId;
  final String reason;
  final String issuedDate;
  final String? sanction;
  final XFile? file;

  const CreateWarningLetterRequest({
    required this.employeeId,
    required this.warningLetterTypeId,
    required this.reason,
    required this.issuedDate,
    this.sanction,
    this.file,
  });

  /// Konversi ke [FormData] untuk pengiriman multipart ke API backend.
  Future<FormData> toFormData() async {
    final Map<String, dynamic> map = {
      'employeeId': employeeId,
      'warningLetterTypeId': warningLetterTypeId,
      'reason': reason,
      'issuedDate': issuedDate,
    };

    if (sanction != null && sanction!.trim().isNotEmpty) {
      map['sanction'] = sanction!.trim();
    }

    if (file != null) {
      final nameCandidate = file!.name.isNotEmpty
          ? file!.name
          : (file!.path.isNotEmpty
              ? file!.path.split(RegExp(r'[/\\]')).last
              : '');
      final fileName =
          nameCandidate.isNotEmpty ? nameCandidate : 'attachment.pdf';
      final fileObj = file!.path.isNotEmpty ? File(file!.path) : null;
      if (fileObj != null && fileObj.existsSync()) {
        map['file'] = await MultipartFile.fromFile(
          file!.path,
          filename: fileName,
        );
      } else {
        final bytes = await file!.readAsBytes();
        map['file'] = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        );
      }
    }

    return FormData.fromMap(map);
  }

  @override
  List<Object?> get props => [
        employeeId,
        warningLetterTypeId,
        reason,
        issuedDate,
        sanction,
        file?.path,
      ];
}

/// Data hasil pembuatan surat peringatan dari response backend.
class CreateWarningLetterResponseData extends Equatable {
  final String id;
  final String referenceNumber;

  const CreateWarningLetterResponseData({
    required this.id,
    required this.referenceNumber,
  });

  factory CreateWarningLetterResponseData.fromJson(Map<String, dynamic> json) {
    return CreateWarningLetterResponseData(
      id: json['id']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
    };
  }

  @override
  List<Object?> get props => [id, referenceNumber];
}

/// Response lengkap dari `POST /warning-letter`.
class CreateWarningLetterResponse extends Equatable {
  final bool success;
  final String message;
  final CreateWarningLetterResponseData? data;

  const CreateWarningLetterResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CreateWarningLetterResponse.fromJson(Map<String, dynamic> json) {
    return CreateWarningLetterResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? CreateWarningLetterResponseData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}
