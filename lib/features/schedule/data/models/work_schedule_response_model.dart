import 'package:equatable/equatable.dart';

class WorkScheduleResponse extends Equatable {
  final bool success;
  final String message;
  final WorkScheduleData? data;

  const WorkScheduleResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory WorkScheduleResponse.fromJson(Map<String, dynamic> json) {
    return WorkScheduleResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? WorkScheduleData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };

  @override
  List<Object?> get props => [success, message, data];
}

class WorkScheduleData extends Equatable {
  final String id;
  final WorkScheduleEmployee? employee;
  final List<WorkScheduleItem> workSchedules;

  const WorkScheduleData({
    required this.id,
    this.employee,
    this.workSchedules = const [],
  });

  factory WorkScheduleData.fromJson(Map<String, dynamic> json) {
    return WorkScheduleData(
      id: json['id'] as String? ?? '',
      employee: json['employee'] != null
          ? WorkScheduleEmployee.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : null,
      workSchedules: (json['workSchedules'] as List<dynamic>?)
              ?.map(
                (e) => WorkScheduleItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee': employee?.toJson(),
        'workSchedules': workSchedules.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, employee, workSchedules];
}

class WorkScheduleEmployee extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? employeeNumber;
  final String? idNumber;
  final String? companyName;
  final String? departmentName;
  final String? positionName;
  final String? levelName;

  const WorkScheduleEmployee({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.photoUrl,
    this.employeeNumber,
    this.idNumber,
    this.companyName,
    this.departmentName,
    this.positionName,
    this.levelName,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) {
      return firstName.trim();
    }
    return '$firstName $lastName'.trim();
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = (lastName != null && lastName!.isNotEmpty)
        ? lastName![0].toUpperCase()
        : '';
    return '$first$last';
  }

  factory WorkScheduleEmployee.fromJson(Map<String, dynamic> json) {
    String? extractName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['name'] as String?;
      }
      if (value is String) return value;
      return null;
    }

    return WorkScheduleEmployee(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
      idNumber: json['idNumber'] as String?,
      companyName: extractName(json['company']),
      departmentName: extractName(json['department']),
      positionName: extractName(json['position']),
      levelName: extractName(json['level']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'employeeNumber': employeeNumber,
        'idNumber': idNumber,
        'company': {'name': companyName},
        'department': {'name': departmentName},
        'position': {'name': positionName},
        'level': {'name': levelName},
      };

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        photoUrl,
        employeeNumber,
        idNumber,
        companyName,
        departmentName,
        positionName,
        levelName,
      ];
}

class WorkScheduleItem extends Equatable {
  final String id;
  final String workDate;
  final bool isDayOff;
  final String? dayOffNotes;
  final WorkScheduleShift? shift;

  const WorkScheduleItem({
    required this.id,
    required this.workDate,
    this.isDayOff = false,
    this.dayOffNotes,
    this.shift,
  });

  DateTime? get parsedDate {
    try {
      return DateTime.parse(workDate);
    } catch (_) {
      return null;
    }
  }

  bool isSameDay(DateTime other) {
    final dt = parsedDate;
    if (dt == null) return false;
    return dt.year == other.year &&
        dt.month == other.month &&
        dt.day == other.day;
  }

  factory WorkScheduleItem.fromJson(Map<String, dynamic> json) {
    return WorkScheduleItem(
      id: json['id'] as String? ?? '',
      workDate: json['workDate'] as String? ?? '',
      isDayOff: json['isDayOff'] as bool? ?? false,
      dayOffNotes: json['dayOffNotes'] as String?,
      shift: json['shift'] != null
          ? WorkScheduleShift.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workDate': workDate,
        'isDayOff': isDayOff,
        'dayOffNotes': dayOffNotes,
        'shift': shift?.toJson(),
      };

  @override
  List<Object?> get props => [id, workDate, isDayOff, dayOffNotes, shift];
}

class WorkScheduleShift extends Equatable {
  final String id;
  final String? name;
  final String? startTime;
  final String? endTime;
  final bool isFlexibleTime;
  final bool isFlexibleBreak;
  final String? breakStart;
  final String? breakEnd;
  final bool isNightShift;
  final String? color;

  const WorkScheduleShift({
    required this.id,
    this.name,
    this.startTime,
    this.endTime,
    this.isFlexibleTime = false,
    this.isFlexibleBreak = false,
    this.breakStart,
    this.breakEnd,
    this.isNightShift = false,
    this.color,
  });

  factory WorkScheduleShift.fromJson(Map<String, dynamic> json) {
    return WorkScheduleShift(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      isFlexibleTime: json['isFlexibleTime'] as bool? ?? false,
      isFlexibleBreak: json['isFlexibleBreak'] as bool? ?? false,
      breakStart: json['breakStart'] as String?,
      breakEnd: json['breakEnd'] as String?,
      isNightShift: json['isNightShift'] as bool? ?? false,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'isFlexibleTime': isFlexibleTime,
        'isFlexibleBreak': isFlexibleBreak,
        'breakStart': breakStart,
        'breakEnd': breakEnd,
        'isNightShift': isNightShift,
        'color': color,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        startTime,
        endTime,
        isFlexibleTime,
        isFlexibleBreak,
        breakStart,
        breakEnd,
        isNightShift,
        color,
      ];
}
