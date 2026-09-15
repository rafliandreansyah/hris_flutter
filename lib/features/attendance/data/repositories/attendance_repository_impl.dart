import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  // In-memory state for offline/demo simulation if API endpoints are mock or backend is development
  AttendanceTodayData? _cachedData;

  AttendanceRepositoryImpl({AttendanceRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? AttendanceRemoteDataSourceImpl();

  @override
  Future<AttendanceTodayData> getTodayAttendance() async {
    final json = await remoteDataSource.fetchAttendanceInfo();
    final data = json['data'] as Map<String, dynamic>?;

    if (data == null) {
      final msg = json['message']?.toString();
      throw ApiException(
        message: msg != null && msg.isNotEmpty
            ? msg
            : 'Data absensi tidak ditemukan dari server.',
        statusCode: 404,
      );
    }

    final attSummary = data['attendanceSummary'] as Map<String, dynamic>?;
    final todayAtt = (data['todayAttendance'] ??
        attSummary?['todayAttendance']) as Map<String, dynamic>?;
    final schedule = data['todaySchedule'] as Map<String, dynamic>?;
    final shift = schedule?['shift'] as Map<String, dynamic>?;
    final company = data['company'] as Map<String, dynamic>?;
    final dept = data['department'] as Map<String, dynamic>?;
    final pos = data['position'] as Map<String, dynamic>?;

    // Parse all Work Locations into WorkLocationItem list
    final workLocations = data['employeeWorkLocation'] as List<dynamic>?;
    final List<WorkLocationItem> availableWorkLocations = [];
    WorkLocationItem? selectedWorkLocation;

    if (workLocations != null && workLocations.isNotEmpty) {
      for (final item in workLocations) {
        if (item is! Map<String, dynamic>) continue;
        final locMap = item;
        final wl = (locMap['workLocation'] as Map<String, dynamic>?) ?? locMap;
        final rawLat = wl['latitude'] ?? locMap['latitude'];
        final rawLng = wl['longitude'] ?? locMap['longitude'];
        final isDefault = locMap['isDefault'] == true || wl['isDefault'] == true;
        final isAnyWhere = wl['isAnyWhere'] == true || locMap['isAnyWhere'] == true;
        final id = (wl['id'] ?? locMap['workLocationId'] ?? locMap['id'] ?? '').toString();
        final name = (wl['name'] ?? locMap['name']) as String? ?? 'Unnamed Location';
        final address = (wl['address'] ?? locMap['address']) as String? ?? '';
        final radius = ((wl['radius'] ?? locMap['radius']) as num?)?.toDouble() ?? 50.0;

        availableWorkLocations.add(
          WorkLocationItem(
            id: id,
            name: name,
            address: address,
            radius: radius,
            latitude: rawLat != null ? double.tryParse(rawLat.toString()) : null,
            longitude: rawLng != null ? double.tryParse(rawLng.toString()) : null,
            isAnyWhere: isAnyWhere,
            isDefault: isDefault,
          ),
        );
      }

      // Select default work location: cari yang isDefault == true lebih dahulu
      if (availableWorkLocations.isNotEmpty) {
        selectedWorkLocation = availableWorkLocations.firstWhere(
          (e) => e.isDefault,
          orElse: () => availableWorkLocations.first,
        );
      }
    }

    // Determine office info from selected work location
    final String officeName;
    final String officeDetail;
    final double officeLat;
    final double officeLng;
    final double geofenceRadius;
    final bool isInsideGeofence;

    if (selectedWorkLocation == null) {
      // Poin 4: Tidak memiliki lokasi kerja
      officeName = 'Lokasi kerja tidak tersedia';
      officeDetail = 'Belum ada lokasi kerja yang ditentukan';
      officeLat = -6.2253;
      officeLng = 106.8097;
      geofenceRadius = 0.0;
      isInsideGeofence = false;
    } else if (selectedWorkLocation.isAnyWhere) {
      // Poin 5: isAnyWhere — bisa absen di mana saja
      officeName = selectedWorkLocation.name;
      officeDetail = selectedWorkLocation.address.isNotEmpty
          ? selectedWorkLocation.address
          : 'Bisa absen di mana saja';
      officeLat = selectedWorkLocation.latitude ?? -6.2253;
      officeLng = selectedWorkLocation.longitude ?? 106.8097;
      geofenceRadius = 0.0;
      isInsideGeofence = true;
    } else {
      // Normal work location
      officeName = selectedWorkLocation.name;
      officeDetail = selectedWorkLocation.address.isNotEmpty
          ? selectedWorkLocation.address
          : 'HQ Office — Main Lobby';
      officeLat = selectedWorkLocation.latitude ?? -6.2253;
      officeLng = selectedWorkLocation.longitude ?? 106.8097;
      final rawRadius = selectedWorkLocation.radius;
      geofenceRadius = rawRadius < 5 ? 50.0 : rawRadius;
      isInsideGeofence = false;
    }

    // Parse Shift
    final isFlexible = shift?['isFlexibleTime'] == true;
    final rawStart = shift?['startTime'] as String?;
    final rawEnd = shift?['endTime'] as String?;
    final shiftStart = rawStart != null && rawStart.isNotEmpty
        ? AppDateUtil.formatTimeHHmm(rawStart, fallback: '09:00')
        : '09:00';
    final shiftEnd = rawEnd != null && rawEnd.isNotEmpty
        ? AppDateUtil.formatTimeHHmm(rawEnd, fallback: '18:00')
        : '18:00';
    final shiftName = isFlexible
        ? 'Flexible Shift'
        : 'Regular Shift ($shiftStart - $shiftEnd)';

    // Parse Attendance Times
    final inTimeRaw = todayAtt?['inTime'] as String?;
    final outTimeRaw = todayAtt?['outTime'] as String?;
    final inTimeStr = inTimeRaw != null && inTimeRaw.isNotEmpty
        ? AppDateUtil.formatTimeHHmm(inTimeRaw)
        : null;
    final outTimeStr = outTimeRaw != null && outTimeRaw.isNotEmpty
        ? AppDateUtil.formatTimeHHmm(outTimeRaw)
        : null;

    final isOnBreakVal = todayAtt?['isOnBreak'] as bool? ?? false;
    final breaks = todayAtt?['breaks'] as List<dynamic>?;
    String? breakOut;
    String? breakIn;
    if (breaks != null && breaks.isNotEmpty) {
      final firstBreak = breaks.first as Map<String, dynamic>;
      final rawBreakOut = firstBreak['startTime'] as String?;
      final rawBreakIn = firstBreak['endTime'] as String?;
      breakOut = rawBreakOut != null && rawBreakOut.isNotEmpty
          ? AppDateUtil.formatTimeHHmm(rawBreakOut)
          : null;
      breakIn = rawBreakIn != null && rawBreakIn.isNotEmpty
          ? AppDateUtil.formatTimeHHmm(rawBreakIn)
          : null;
    }

    final timeServerStr = data['timeServer'] as String?;
    final serverDateTime = timeServerStr != null
        ? DateTime.tryParse(timeServerStr) ?? DateTime.now()
        : DateTime.now();

    final firstName = data['firstName'] as String? ?? '';
    final lastName = data['lastName'] as String? ?? '';
    final fullName =
        '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Pegawai';

    final employeeId = data['employeeNumber'] as String? ??
        data['idNumber'] as String? ??
        (data['id'] as String?)?.substring(0, 4) ??
        '';

    final rawAttendanceMethod = data['attendanceMethod']?.toString().trim();
    final attendanceMethod = rawAttendanceMethod ?? '';

    _cachedData = AttendanceTodayData(
      inTime: inTimeStr,
      outTime: outTimeStr,
      breakOutTime: breakOut,
      breakInTime: breakIn,
      isOnBreak: isOnBreakVal,
      shiftName: shiftName,
      timezone: data['timezone'] as String? ?? 'Asia/Jakarta',
      serverTime: serverDateTime,
      employeeName: fullName,
      employeeRole: pos?['name'] as String? ?? 'Staff',
      employeeId: employeeId,
      photoUrl: data['photoUrl'] as String?,
      companyName: company?['name'] as String? ?? '',
      departmentName: dept?['name'] as String? ?? '',
      officeName: officeName,
      officeDetail: officeDetail,
      officeLatitude: officeLat,
      officeLongitude: officeLng,
      geofenceRadiusMeters: geofenceRadius,
      isInsideGeofence: isInsideGeofence,
      gpsAccuracy: '±5m',
      availableWorkLocations: availableWorkLocations,
      selectedWorkLocation: selectedWorkLocation,
      attendanceMethod: attendanceMethod,
    );
    return _cachedData!;
  }

  @override
  Future<CreateAttendanceResponse> recordAttendance(
    CreateAttendanceRequest request,
  ) async {
    return await remoteDataSource.recordAttendance(request);
  }

  @override
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
    String attendanceMethod = 'photo',
    String? workLocationId,
    XFile? photoFile,
  }) async {
    final current = _cachedData ?? await getTodayAttendance();
    final effectiveLocationId = workLocationId ??
        current.selectedWorkLocation?.id ??
        (current.availableWorkLocations.isNotEmpty
            ? current.availableWorkLocations.first.id
            : '');

    await remoteDataSource.recordAttendance(
      CreateAttendanceRequest(
        workLocationId: effectiveLocationId,
        attendanceMethod: attendanceMethod,
        latitude: latitude,
        longitude: longitude,
        attendanceType: 'in',
        address: address ?? current.officeDetail,
        file: photoFile,
      ),
    );

    try {
      return await getTodayAttendance();
    } catch (_) {
      final nowTime = DateFormat('HH:mm').format(DateTime.now());
      _cachedData = current.copyWith(
        inTime: nowTime,
        userLatitude: latitude,
        userLongitude: longitude,
      );
      return _cachedData!;
    }
  }

  @override
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
    String attendanceMethod = 'photo',
    String? workLocationId,
    XFile? photoFile,
  }) async {
    final current = _cachedData ?? await getTodayAttendance();
    final effectiveLocationId = workLocationId ??
        current.selectedWorkLocation?.id ??
        (current.availableWorkLocations.isNotEmpty
            ? current.availableWorkLocations.first.id
            : '');

    await remoteDataSource.recordAttendance(
      CreateAttendanceRequest(
        workLocationId: effectiveLocationId,
        attendanceMethod: attendanceMethod,
        latitude: latitude,
        longitude: longitude,
        attendanceType: 'out',
        address: address ?? current.officeDetail,
        file: photoFile,
      ),
    );

    try {
      return await getTodayAttendance();
    } catch (_) {
      final nowTime = DateFormat('HH:mm').format(DateTime.now());
      _cachedData = current.copyWith(
        outTime: nowTime,
        userLatitude: latitude,
        userLongitude: longitude,
      );
      return _cachedData!;
    }
  }

  @override
  Future<AttendanceTodayData> toggleBreak() async {
    final current = _cachedData ?? await getTodayAttendance();
    final nowTime = DateFormat('HH:mm').format(DateTime.now());

    if (!current.isOnBreak) {
      // Start break
      _cachedData = current.copyWith(
        isOnBreak: true,
        breakOutTime: nowTime,
      );
    } else {
      // End break
      _cachedData = current.copyWith(
        isOnBreak: false,
        breakInTime: nowTime,
      );
    }
    return _cachedData!;
  }

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await remoteDataSource.reportLocationIssue(
        issueDescription: issueDescription,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      // Silently handled for simulation if backend endpoint is unavailable
    }
  }

  @override
  Future<AttendanceLogListResponse> getAttendanceLogs({
    String? employeeId,
    bool lastMonth = false,
    int page = 1,
    int size = 20,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  }) async {
    String? targetEmployeeId = employeeId;
    if (targetEmployeeId == null || targetEmployeeId.isEmpty) {
      try {
        targetEmployeeId = await SecureStorageService.instance.getEmployeeId();
      } catch (_) {}
    }

    return remoteDataSource.getAttendanceLogs(
      employeeId: targetEmployeeId,
      lastMonth: lastMonth,
      page: page,
      size: size,
      startDate: startDate,
      endDate: endDate,
      type: type,
      status: status,
    );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() {
    return remoteDataSource.getAttendanceEmployees();
  }

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) {
    return remoteDataSource.getAttendanceSummary(employeeId: employeeId);
  }

  @override
  Future<AttendanceDetailModel> getAttendanceDetail(String id) {
    return remoteDataSource.getAttendanceDetail(id);
  }
}
