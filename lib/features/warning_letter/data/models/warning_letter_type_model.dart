import 'package:equatable/equatable.dart';

/// Model untuk tipe surat peringatan dari endpoint `/warning-letter/type`.
class WarningLetterTypeModel extends Equatable {
  final String id;
  final String name;
  final int level;
  final int validityPeriodMonths;

  const WarningLetterTypeModel({
    required this.id,
    required this.name,
    required this.level,
    required this.validityPeriodMonths,
  });

  factory WarningLetterTypeModel.fromJson(Map<String, dynamic> json) {
    return WarningLetterTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: (json['level'] is num) ? (json['level'] as num).toInt() : 0,
      validityPeriodMonths: (json['validityPeriodMonths'] is num)
          ? (json['validityPeriodMonths'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'validityPeriodMonths': validityPeriodMonths,
    };
  }

  @override
  List<Object?> get props => [id, name, level, validityPeriodMonths];
}
