import 'package:equatable/equatable.dart';

/// Model domain lokasi kerja karyawan dari API `employeeWorkLocation`.
class WorkLocationItem extends Equatable {
  final String id;
  final String name;
  final String address;
  final double radius;
  final double? latitude;
  final double? longitude;
  final bool isAnyWhere;
  final bool isDefault;

  const WorkLocationItem({
    required this.id,
    required this.name,
    this.address = '',
    this.radius = 50.0,
    this.latitude,
    this.longitude,
    this.isAnyWhere = false,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        radius,
        latitude,
        longitude,
        isAnyWhere,
        isDefault,
      ];
}

/// Entity data absensi hari ini yang digunakan pada halaman Attendance & Check-In.
class AttendanceTodayData extends Equatable {
  final String? inTime;
  final String? outTime;
  final String? breakOutTime;
  final String? breakInTime;
  final bool isOnBreak;
  final String shiftName;
  final String timezone;
  final DateTime serverTime;
  final String employeeName;
  final String employeeRole;
  final String employeeId;
  final String? photoUrl;
  final String companyName;
  final String departmentName;
  final String officeName;
  final String officeDetail;
  final double officeLatitude;
  final double officeLongitude;
  final double geofenceRadiusMeters;
  final bool isInsideGeofence;
  final String gpsAccuracy;
  final double? userLatitude;
  final double? userLongitude;
  final List<WorkLocationItem> availableWorkLocations;
  final WorkLocationItem? selectedWorkLocation;

  const AttendanceTodayData({
    this.inTime,
    this.outTime,
    this.breakOutTime,
    this.breakInTime,
    this.isOnBreak = false,
    this.shiftName = 'Regular Shift (09:00 - 18:00)',
    this.timezone = 'Asia/Jakarta',
    required this.serverTime,
    this.employeeName = 'Alex Rivera',
    this.employeeRole = 'Senior Product Designer',
    this.employeeId = '8829',
    this.photoUrl,
    this.companyName = 'Oasish Global Tech',
    this.departmentName = 'Design & Product',
    this.officeName = 'Jakarta HQ Office',
    this.officeDetail = 'HQ Office — Main Lobby',
    this.officeLatitude = -6.2253,
    this.officeLongitude = 106.8097,
    this.geofenceRadiusMeters = 50.0,
    this.isInsideGeofence = true,
    this.gpsAccuracy = '±5m',
    this.userLatitude,
    this.userLongitude,
    this.availableWorkLocations = const [],
    this.selectedWorkLocation,
  });

  bool get isClockedIn => inTime != null && inTime!.isNotEmpty && inTime != '--:--';
  bool get isClockedOut => outTime != null && outTime!.isNotEmpty && outTime != '--:--';

  /// Apakah user memiliki lokasi kerja yang ditentukan.
  bool get hasWorkLocation => selectedWorkLocation != null;

  AttendanceTodayData copyWith({
    String? inTime,
    String? outTime,
    String? breakOutTime,
    String? breakInTime,
    bool? isOnBreak,
    String? shiftName,
    String? timezone,
    DateTime? serverTime,
    String? employeeName,
    String? employeeRole,
    String? employeeId,
    String? photoUrl,
    String? companyName,
    String? departmentName,
    String? officeName,
    String? officeDetail,
    double? officeLatitude,
    double? officeLongitude,
    double? geofenceRadiusMeters,
    bool? isInsideGeofence,
    String? gpsAccuracy,
    double? userLatitude,
    double? userLongitude,
    List<WorkLocationItem>? availableWorkLocations,
    WorkLocationItem? selectedWorkLocation,
  }) {
    return AttendanceTodayData(
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
      breakOutTime: breakOutTime ?? this.breakOutTime,
      breakInTime: breakInTime ?? this.breakInTime,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      shiftName: shiftName ?? this.shiftName,
      timezone: timezone ?? this.timezone,
      serverTime: serverTime ?? this.serverTime,
      employeeName: employeeName ?? this.employeeName,
      employeeRole: employeeRole ?? this.employeeRole,
      employeeId: employeeId ?? this.employeeId,
      photoUrl: photoUrl ?? this.photoUrl,
      companyName: companyName ?? this.companyName,
      departmentName: departmentName ?? this.departmentName,
      officeName: officeName ?? this.officeName,
      officeDetail: officeDetail ?? this.officeDetail,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      availableWorkLocations: availableWorkLocations ?? this.availableWorkLocations,
      selectedWorkLocation: selectedWorkLocation ?? this.selectedWorkLocation,
    );
  }

  @override
  List<Object?> get props => [
        inTime,
        outTime,
        breakOutTime,
        breakInTime,
        isOnBreak,
        shiftName,
        timezone,
        serverTime,
        employeeName,
        employeeRole,
        employeeId,
        photoUrl,
        companyName,
        departmentName,
        officeName,
        officeDetail,
        officeLatitude,
        officeLongitude,
        geofenceRadiusMeters,
        isInsideGeofence,
        gpsAccuracy,
        userLatitude,
        userLongitude,
        availableWorkLocations,
        selectedWorkLocation,
      ];
}
