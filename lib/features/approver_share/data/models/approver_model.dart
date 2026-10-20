import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';

/// Atasan yang berhak approve sebuah pengajuan (`GET /approvers`).
/// [phone] & [email] berasal dari master pegawai di server.
class ApproverModel extends Equatable {
  final String id;
  final String? employeeNumber;
  final String fullName;
  final String? position;
  final String? department;
  final String? company;
  final String? avatarUrl;
  final String? phone;
  final String? email;

  const ApproverModel({
    required this.id,
    required this.fullName,
    this.employeeNumber,
    this.position,
    this.department,
    this.company,
    this.avatarUrl,
    this.phone,
    this.email,
  });

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  factory ApproverModel.fromJson(Map<String, dynamic> json) {
    return ApproverModel(
      id: json['id']?.toString() ?? '',
      employeeNumber: _text(json['employeeNumber']),
      fullName: _text(json['fullName']) ?? _text(json['name']) ?? '-',
      position: _name(json['position']),
      department: _name(json['department']),
      company: _name(json['company']),
      avatarUrl: resolveFileUrl(_text(json['avatarUrl']) ?? _text(json['photoUrl'])),
      phone: _text(json['phone']) ?? _text(json['phoneNumber']),
      email: _text(json['email']),
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  // Server bisa mengirim string atau objek `{ name }`.
  static String? _name(dynamic value) =>
      value is Map ? _text(value['name']) : _text(value);

  @override
  List<Object?> get props => [
        id,
        employeeNumber,
        fullName,
        position,
        department,
        company,
        avatarUrl,
        phone,
        email,
      ];
}
