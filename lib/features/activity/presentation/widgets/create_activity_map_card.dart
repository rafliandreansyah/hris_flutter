import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_realtime_map_card.dart';

export 'package:hris_flutter/core/widgets/app_realtime_map_card.dart';

/// Card Peta Google Maps khusus Form Create Activity sesuai spesifikasi Google Stitch
/// Menggunakan komponen global [AppRealtimeMapCard] dengan:
/// - Container dan header berbingkai yang selaras dengan [ActivityMapCard]
/// - Lingkaran biru (blue dot) real-time GPS tanpa marker pin manual
/// - Akurasi dan koordinat GPS dinamis dari sensor perangkat (bukan hardcode)
class CreateActivityMapCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String gpsAccuracy;
  final LocationChangedCallback? onLocationChanged;
  final AddressDetectedCallback? onAddressDetected;
  final bool showOpenInMaps;

  const CreateActivityMapCard({
    super.key,
    this.latitude = -6.2088,
    this.longitude = 106.8456,
    this.gpsAccuracy = '±3m',
    this.onLocationChanged,
    this.onAddressDetected,
    this.showOpenInMaps = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppRealtimeMapCard(
      title: 'Lokasi Aktivitas',
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      mapHeight: 150.0,
      enableTracking: true,
      showOpenInMaps: showOpenInMaps,
      onLocationChanged: onLocationChanged,
      onAddressDetected: onAddressDetected,
    );
  }
}
