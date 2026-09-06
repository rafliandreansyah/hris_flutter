/// Model respons dari endpoint `/employee/dashboard`.
class DashboardResponseModel {
  final bool success;
  final String? message;
  final DashboardData? data;

  const DashboardResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? DashboardData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

/// Data payload utama dashboard karyawan.
class DashboardData {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final String? timezone;
  final String? photoUrl;
  final CompanyInfo? company;
  final DepartmentInfo? department;
  final PositionInfo? position;
  final EmployeeDeviceInfo? employeeDevice;
  final TodayScheduleInfo? todaySchedule;
  final String? timeServer;
  final List<AnnouncementItem> latestAnnouncement;
  final AttendanceSummaryInfo? attendanceSummary;

  const DashboardData({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.idNumber,
    this.employeeNumber,
    this.timezone,
    this.photoUrl,
    this.company,
    this.department,
    this.position,
    this.employeeDevice,
    this.todaySchedule,
    this.timeServer,
    this.latestAnnouncement = const [],
    this.attendanceSummary,
  });

  String get fullName => lastName != null && lastName!.isNotEmpty
      ? '$firstName $lastName'
      : firstName;

  String get initials {
    if (firstName.trim().isEmpty) return 'U';
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '${firstName.trim()[0]}${lastName!.trim()[0]}'.toUpperCase();
    }
    final trimmed = firstName.trim();
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed[0].toUpperCase();
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      idNumber: json['idNumber'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
      timezone: json['timezone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      company: json['company'] != null
          ? CompanyInfo.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] != null
          ? DepartmentInfo.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] != null
          ? PositionInfo.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      employeeDevice: json['employeeDevice'] != null
          ? EmployeeDeviceInfo.fromJson(
              json['employeeDevice'] as Map<String, dynamic>)
          : null,
      todaySchedule: json['todaySchedule'] != null
          ? TodayScheduleInfo.fromJson(
              json['todaySchedule'] as Map<String, dynamic>)
          : null,
      timeServer: json['timeServer'] as String?,
      latestAnnouncement: (json['latestAnnouncement'] as List<dynamic>?)
              ?.map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      attendanceSummary: json['attendanceSummary'] != null
          ? AttendanceSummaryInfo.fromJson(
              json['attendanceSummary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'idNumber': idNumber,
      'employeeNumber': employeeNumber,
      'timezone': timezone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'company': company?.toJson(),
      'department': department?.toJson(),
      'position': position?.toJson(),
      'employeeDevice': employeeDevice?.toJson(),
      'todaySchedule': todaySchedule?.toJson(),
      'timeServer': timeServer,
      'latestAnnouncement':
          latestAnnouncement.map((e) => e.toJson()).toList(),
      'attendanceSummary': attendanceSummary?.toJson(),
    };
  }
}

class CompanyInfo {
  final String id;
  final String name;

  const CompanyInfo({required this.id, required this.name});

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class DepartmentInfo {
  final String id;
  final String name;
  final String? code;

  const DepartmentInfo({required this.id, required this.name, this.code});

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) {
    return DepartmentInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

class PositionInfo {
  final String id;
  final String name;
  final String? code;

  const PositionInfo({required this.id, required this.name, this.code});

  factory PositionInfo.fromJson(Map<String, dynamic> json) {
    return PositionInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

class EmployeeDeviceInfo {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;

  const EmployeeDeviceInfo({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
  });

  factory EmployeeDeviceInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeDeviceInfo(
      id: json['id'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String?,
      deviceModel: json['deviceModel'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
    };
  }
}

class TodayScheduleInfo {
  final String id;
  final String? workDate;
  final ShiftInfo? shift;

  const TodayScheduleInfo({
    required this.id,
    this.workDate,
    this.shift,
  });

  factory TodayScheduleInfo.fromJson(Map<String, dynamic> json) {
    return TodayScheduleInfo(
      id: json['id'] as String? ?? '',
      workDate: json['workDate'] as String?,
      shift: json['shift'] != null
          ? ShiftInfo.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workDate': workDate,
        'shift': shift?.toJson(),
      };
}

class ShiftInfo {
  final String id;
  final String? startTime;
  final String? endTime;
  final bool isFlexibleTime;
  final bool isFlexibleBreak;
  final String? breakStart;
  final String? breakEnd;
  final bool isNightShift;
  final bool status;

  const ShiftInfo({
    required this.id,
    this.startTime,
    this.endTime,
    this.isFlexibleTime = false,
    this.isFlexibleBreak = false,
    this.breakStart,
    this.breakEnd,
    this.isNightShift = false,
    this.status = true,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      id: json['id'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      isFlexibleTime: json['isFlexibleTime'] as bool? ?? false,
      isFlexibleBreak: json['isFlexibleBreak'] as bool? ?? false,
      breakStart: json['breakStart'] as String?,
      breakEnd: json['breakEnd'] as String?,
      isNightShift: json['isNightShift'] as bool? ?? false,
      status: json['status'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'isFlexibleTime': isFlexibleTime,
      'isFlexibleBreak': isFlexibleBreak,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
      'isNightShift': isNightShift,
      'status': status,
    };
  }
}

class AnnouncementItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? createdAt;

  const AnnouncementItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.createdAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}

class AttendanceSummaryInfo {
  final TodayAttendanceInfo? todayAttendance;
  final AttendanceInfoMonth? attendanceInfoThisMonth;
  final QuotaLeaveBalance? quotaLeaveBalanceThisYear;

  const AttendanceSummaryInfo({
    this.todayAttendance,
    this.attendanceInfoThisMonth,
    this.quotaLeaveBalanceThisYear,
  });

  factory AttendanceSummaryInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryInfo(
      todayAttendance: json['todayAttendance'] != null
          ? TodayAttendanceInfo.fromJson(
              json['todayAttendance'] as Map<String, dynamic>)
          : null,
      attendanceInfoThisMonth: json['attendanceInfoThisMonth'] != null
          ? AttendanceInfoMonth.fromJson(
              json['attendanceInfoThisMonth'] as Map<String, dynamic>)
          : null,
      quotaLeaveBalanceThisYear: json['quotaLeaveBalanceThisYear'] != null
          ? QuotaLeaveBalance.fromJson(
              json['quotaLeaveBalanceThisYear'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayAttendance': todayAttendance?.toJson(),
      'attendanceInfoThisMonth': attendanceInfoThisMonth?.toJson(),
      'quotaLeaveBalanceThisYear': quotaLeaveBalanceThisYear?.toJson(),
    };
  }
}

class TodayAttendanceInfo {
  final String? inTime;
  final String? outTime;
  final bool isOnBreak;
  final int totalBreakMinutes;
  final int overbreakMinutes;
  final List<BreakItem> breaks;

  const TodayAttendanceInfo({
    this.inTime,
    this.outTime,
    this.isOnBreak = false,
    this.totalBreakMinutes = 0,
    this.overbreakMinutes = 0,
    this.breaks = const [],
  });

  factory TodayAttendanceInfo.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceInfo(
      inTime: json['inTime'] as String?,
      outTime: json['outTime'] as String?,
      isOnBreak: json['isOnBreak'] as bool? ?? false,
      totalBreakMinutes: (json['totalBreakMinutes'] as num?)?.toInt() ?? 0,
      overbreakMinutes: (json['overbreakMinutes'] as num?)?.toInt() ?? 0,
      breaks: (json['breaks'] as List<dynamic>?)
              ?.map((e) => BreakItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inTime': inTime,
      'outTime': outTime,
      'isOnBreak': isOnBreak,
      'totalBreakMinutes': totalBreakMinutes,
      'overbreakMinutes': overbreakMinutes,
      'breaks': breaks.map((e) => e.toJson()).toList(),
    };
  }
}

class BreakItem {
  final String id;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final String? note;

  const BreakItem({
    required this.id,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.note,
  });

  factory BreakItem.fromJson(Map<String, dynamic> json) {
    return BreakItem(
      id: json['id'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'note': note,
    };
  }
}

class AttendanceInfoMonth {
  final int totalAttendance;
  final int lateDays;

  const AttendanceInfoMonth({
    this.totalAttendance = 0,
    this.lateDays = 0,
  });

  factory AttendanceInfoMonth.fromJson(Map<String, dynamic> json) {
    return AttendanceInfoMonth(
      totalAttendance: (json['totalAttendance'] as num?)?.toInt() ?? 0,
      lateDays: (json['lateDays'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAttendance': totalAttendance,
      'lateDays': lateDays,
    };
  }
}

class QuotaLeaveBalance {
  final int totalQuota;
  final int totalUsed;

  const QuotaLeaveBalance({
    this.totalQuota = 0,
    this.totalUsed = 0,
  });

  int get remaining => (totalQuota - totalUsed).clamp(0, totalQuota);

  factory QuotaLeaveBalance.fromJson(Map<String, dynamic> json) {
    return QuotaLeaveBalance(
      totalQuota: (json['totalQuota'] as num?)?.toInt() ?? 0,
      totalUsed: (json['totalUsed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuota': totalQuota,
      'totalUsed': totalUsed,
    };
  }
}
