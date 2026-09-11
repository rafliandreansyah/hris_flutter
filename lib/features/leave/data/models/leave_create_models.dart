import 'package:equatable/equatable.dart';

/// Opsi jenis cuti/izin yang didapat dari endpoint `GET /leave-request/types`.
class LeaveTypeOptionModel extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? description;
  final bool status;
  final int? fixedDays;
  final bool isDeducted;
  final bool requiresApprove;
  final bool requiresFile;
  final int? maxDays;

  const LeaveTypeOptionModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.status = true,
    this.fixedDays,
    this.isDeducted = false,
    this.requiresApprove = true,
    this.requiresFile = false,
    this.maxDays,
  });

  factory LeaveTypeOptionModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeOptionModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status'] as bool? ?? true,
      fixedDays: (json['fixedDays'] as num?)?.toInt(),
      isDeducted: json['isDeducted'] as bool? ?? false,
      requiresApprove: json['requiresApprove'] as bool? ?? true,
      requiresFile: json['requiresFile'] as bool? ?? false,
      maxDays: (json['maxDays'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'status': status,
        'fixedDays': fixedDays,
        'isDeducted': isDeducted,
        'requiresApprove': requiresApprove,
        'requiresFile': requiresFile,
        'maxDays': maxDays,
      };

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        status,
        fixedDays,
        isDeducted,
        requiresApprove,
        requiresFile,
        maxDays,
      ];
}

/// Model respons pengajuan cuti baru dari endpoint `POST /leave-request`.
class CreateLeaveResultModel extends Equatable {
  final bool success;
  final String message;
  final String? id;

  const CreateLeaveResultModel({
    required this.success,
    required this.message,
    this.id,
  });

  factory CreateLeaveResultModel.fromJson(Map<String, dynamic> json) {
    String? createdId;
    if (json['data'] is Map<String, dynamic>) {
      createdId = (json['data'] as Map<String, dynamic>)['id']?.toString();
    } else if (json['data'] is String) {
      createdId = json['data'].toString();
    }

    return CreateLeaveResultModel(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      id: createdId,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': id != null ? {'id': id} : null,
      };

  @override
  List<Object?> get props => [success, message, id];
}
