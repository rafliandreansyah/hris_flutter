import 'package:equatable/equatable.dart';

/// Data payload respons pembuatan absensi.
class CreateAttendanceData extends Equatable {
  final String id;

  const CreateAttendanceData({required this.id});

  factory CreateAttendanceData.fromJson(Map<String, dynamic> json) {
    return CreateAttendanceData(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id};

  @override
  List<Object?> get props => [id];
}

/// Pembungkus respons API dari endpoint `POST /attendances`.
class CreateAttendanceResponse extends Equatable {
  final bool success;
  final String message;
  final CreateAttendanceData? data;

  const CreateAttendanceResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CreateAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return CreateAttendanceResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? CreateAttendanceData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}
