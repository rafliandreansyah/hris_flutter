import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:image_picker/image_picker.dart';

abstract class CreatePlanActivityEvent extends Equatable {
  const CreatePlanActivityEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman create plan activity pertama kali dibuka.
/// Memuat daftar jenis aktivitas dan daftar pegawai bawahan.
class CreatePlanActivityStarted extends CreatePlanActivityEvent {
  const CreatePlanActivityStarted();
}

/// Event saat user memilih pegawai bawahan dari modal picker.
class CreatePlanActivityEmployeeSelected extends CreatePlanActivityEvent {
  final EmployeeDirectoryItem employee;

  const CreatePlanActivityEmployeeSelected(this.employee);

  @override
  List<Object?> get props => [employee];
}

/// Event saat user memilih tipe aktivitas dari modal picker.
class CreatePlanActivityTypeSelected extends CreatePlanActivityEvent {
  final ActivityTypeModel activityType;

  const CreatePlanActivityTypeSelected(this.activityType);

  @override
  List<Object?> get props => [activityType];
}

/// Event saat atasan men-submit rencana aktivitas bawahan.
class CreatePlanActivitySubmitted extends CreatePlanActivityEvent {
  final String employeeId;
  final String activityTypeId;
  final String startTime;
  final String locationName;
  final String locationAddress;
  final String description;
  final double latitude;
  final double longitude;
  final XFile? file;

  const CreatePlanActivitySubmitted({
    required this.employeeId,
    required this.activityTypeId,
    required this.startTime,
    required this.locationName,
    required this.locationAddress,
    required this.description,
    this.latitude = 0,
    this.longitude = 0,
    this.file,
  });

  @override
  List<Object?> get props => [
        employeeId,
        activityTypeId,
        startTime,
        locationName,
        locationAddress,
        description,
        latitude,
        longitude,
        file?.path,
      ];
}
