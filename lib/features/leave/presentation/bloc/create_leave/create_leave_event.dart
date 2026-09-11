import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';

abstract class CreateLeaveEvent extends Equatable {
  const CreateLeaveEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat form pengajuan cuti dibuka, untuk mengambil daftar jenis cuti.
class CreateLeaveStarted extends CreateLeaveEvent {
  const CreateLeaveStarted();
}

/// Event saat user memilih atau mengubah jenis cuti.
class CreateLeaveTypeChanged extends CreateLeaveEvent {
  final LeaveTypeOptionModel? leaveType;

  const CreateLeaveTypeChanged(this.leaveType);

  @override
  List<Object?> get props => [leaveType];
}

/// Event saat user menekan tombol submit untuk mengirim pengajuan cuti.
class CreateLeaveSubmitted extends CreateLeaveEvent {
  final String leaveTypeId;
  final String startDate;
  final int totalDays;
  final String notes;
  final XFile? file;

  const CreateLeaveSubmitted({
    required this.leaveTypeId,
    required this.startDate,
    required this.totalDays,
    required this.notes,
    this.file,
  });

  @override
  List<Object?> get props => [
        leaveTypeId,
        startDate,
        totalDays,
        notes,
        file?.path,
      ];
}
