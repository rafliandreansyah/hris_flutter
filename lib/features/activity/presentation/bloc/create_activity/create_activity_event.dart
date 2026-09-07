import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class CreateActivityEvent extends Equatable {
  const CreateActivityEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman create activity pertama kali dibuka.
/// Memuat daftar activity types dari API.
class CreateActivityStarted extends CreateActivityEvent {
  const CreateActivityStarted();
}

/// Event saat user menekan tombol submit form create activity.
class CreateActivitySubmitted extends CreateActivityEvent {
  final String activityTypeId;
  final double latitude;
  final double longitude;
  final String locationName;
  final String locationAddress;
  final String description;
  final XFile? file;

  const CreateActivitySubmitted({
    required this.activityTypeId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.locationAddress,
    required this.description,
    this.file,
  });

  @override
  List<Object?> get props => [
        activityTypeId,
        latitude,
        longitude,
        locationName,
        locationAddress,
        description,
        file?.path,
      ];
}
