import 'package:equatable/equatable.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:image_picker/image_picker.dart';

abstract class CreateWarningLetterEvent extends Equatable {
  const CreateWarningLetterEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat form dibuka, memuat master tipe SP dan daftar pegawai.
class CreateWarningLetterStarted extends CreateWarningLetterEvent {
  const CreateWarningLetterStarted();
}

/// Event ketika pegawai dipilih oleh user.
class CreateWarningLetterEmployeeSelected extends CreateWarningLetterEvent {
  final EmployeeDirectoryItem employee;

  const CreateWarningLetterEmployeeSelected(this.employee);

  @override
  List<Object?> get props => [employee];
}

/// Event ketika tipe surat peringatan dipilih.
class CreateWarningLetterTypeSelected extends CreateWarningLetterEvent {
  final WarningLetterTypeModel type;

  const CreateWarningLetterTypeSelected(this.type);

  @override
  List<Object?> get props => [type];
}

/// Event ketika tanggal penerbitan diubah.
class CreateWarningLetterIssuedDateChanged extends CreateWarningLetterEvent {
  final DateTime date;

  const CreateWarningLetterIssuedDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event ketika alasan pelanggaran diubah.
class CreateWarningLetterReasonChanged extends CreateWarningLetterEvent {
  final String reason;

  const CreateWarningLetterReasonChanged(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// Event ketika sanksi tindakan disiplin diubah.
class CreateWarningLetterSanctionChanged extends CreateWarningLetterEvent {
  final String sanction;

  const CreateWarningLetterSanctionChanged(this.sanction);

  @override
  List<Object?> get props => [sanction];
}

/// Event ketika berkas lampiran/bukti dipilih atau dihapus.
class CreateWarningLetterFileChanged extends CreateWarningLetterEvent {
  final XFile? file;
  final ImageCompressResult? compressResult;

  const CreateWarningLetterFileChanged({this.file, this.compressResult});

  @override
  List<Object?> get props => [file?.path, compressResult?.compressedSizeBytes];
}

/// Event saat tombol submit ditekan.
class CreateWarningLetterSubmitted extends CreateWarningLetterEvent {
  const CreateWarningLetterSubmitted();
}
