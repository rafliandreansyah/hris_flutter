import 'package:equatable/equatable.dart';

abstract class AnnouncementDetailEvent extends Equatable {
  const AnnouncementDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event pemuatan awal data detail pengumuman.
class AnnouncementDetailStarted extends AnnouncementDetailEvent {
  final String id;

  const AnnouncementDetailStarted(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event penyegaran data detail pengumuman (pull-to-refresh).
class AnnouncementDetailRefreshed extends AnnouncementDetailEvent {
  const AnnouncementDetailRefreshed();
}

/// Event pengiriman konfirmasi pembacaan pengumuman (Acknowledge).
class AnnouncementDetailAcknowledgeSubmitted extends AnnouncementDetailEvent {
  const AnnouncementDetailAcknowledgeSubmitted();
}
