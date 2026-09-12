import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class CreateOvertimeEvent extends Equatable {
  const CreateOvertimeEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat formulir tambah lembur pertama kali dibuka.
class CreateOvertimeStarted extends CreateOvertimeEvent {
  final DateTime? initialStartTime;

  const CreateOvertimeStarted({this.initialStartTime});

  @override
  List<Object?> get props => [initialStartTime];
}

/// Event saat pengguna memilih tanggal & jam mulai lembur (`startOvertime`).
class CreateOvertimeStartChanged extends CreateOvertimeEvent {
  final DateTime startOvertime;
  final bool isUserExplicitTime;

  const CreateOvertimeStartChanged(
    this.startOvertime, {
    this.isUserExplicitTime = true,
  });

  @override
  List<Object?> get props => [startOvertime, isUserExplicitTime];
}

/// Event saat memicu pemanggilan API `GET /overtime/schedule?dateTimeStart=...`.
class CreateOvertimeFetchSchedule extends CreateOvertimeEvent {
  final DateTime dateTimeStart;

  const CreateOvertimeFetchSchedule(this.dateTimeStart);

  @override
  List<Object?> get props => [dateTimeStart];
}

/// Event saat pengguna mengubah jam selesai secara manual (pada mode tidak terkunci).
class CreateOvertimeEndChanged extends CreateOvertimeEvent {
  final DateTime endOvertime;

  const CreateOvertimeEndChanged(this.endOvertime);

  @override
  List<Object?> get props => [endOvertime];
}

/// Event saat pengguna menekan tombol kirim form pengajuan lembur.
class CreateOvertimeSubmitted extends CreateOvertimeEvent {
  final DateTime startOvertime;
  final DateTime endOvertime;
  final String notes;
  final String? workScheduleId;
  final XFile file;

  const CreateOvertimeSubmitted({
    required this.startOvertime,
    required this.endOvertime,
    required this.notes,
    this.workScheduleId,
    required this.file,
  });

  @override
  List<Object?> get props => [
        startOvertime,
        endOvertime,
        notes,
        workScheduleId,
        file.path,
      ];
}
