import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_geofence_map_card.dart';

void main() {
  group('AttendanceGeofenceMapCard Widget Tests', () {
    testWidgets('renders office details and status pill correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttendanceGeofenceMapCard(
              officeLatitude: -6.2253,
              officeLongitude: 106.8097,
              userLatitude: -6.2253,
              userLongitude: 106.8097,
              geofenceRadiusMeters: 50.0,
              isInsideGeofence: true,
              gpsAccuracy: '±5m',
              isAnyWhere: false,
              hasWorkLocation: true,
              isGpsAcquired: true,
              officeName: 'Jakarta HQ Office',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Live GPS'), findsOneWidget);
      expect(find.text('Fokus Lokasi'), findsOneWidget);
      expect(find.text('GPS Accuracy: ±5m'), findsOneWidget);
      expect(find.text('Inside Geofence Radius'), findsOneWidget);
    });

    testWidgets('updates smoothly when office location changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttendanceGeofenceMapCard(
              officeLatitude: -6.2253,
              officeLongitude: 106.8097,
              userLatitude: -6.2253,
              userLongitude: 106.8097,
              geofenceRadiusMeters: 50.0,
              isInsideGeofence: true,
              gpsAccuracy: '±5m',
              isAnyWhere: false,
              hasWorkLocation: true,
              isGpsAcquired: true,
              officeName: 'Jakarta HQ Office',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Inside Geofence Radius'), findsOneWidget);

      // Rebuild with new office location (e.g. user selected Bandung Hub)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttendanceGeofenceMapCard(
              officeLatitude: -6.9175,
              officeLongitude: 107.6191,
              userLatitude: -6.2253,
              userLongitude: 106.8097,
              geofenceRadiusMeters: 100.0,
              isInsideGeofence: false,
              gpsAccuracy: '±8m',
              isAnyWhere: false,
              hasWorkLocation: true,
              isGpsAcquired: true,
              officeName: 'Bandung Hub',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Outside Geofence Radius'), findsOneWidget);
      expect(find.text('GPS Accuracy: ±8m'), findsOneWidget);
    });

    testWidgets('displays isAnyWhere badge when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttendanceGeofenceMapCard(
              officeLatitude: -6.2253,
              officeLongitude: 106.8097,
              userLatitude: -6.2253,
              userLongitude: 106.8097,
              geofenceRadiusMeters: 0.0,
              isInsideGeofence: true,
              gpsAccuracy: '±4m',
              isAnyWhere: true,
              hasWorkLocation: true,
              isGpsAcquired: true,
              officeName: 'Work Anywhere',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bisa Absen di Mana Saja'), findsWidgets);
    });

    testWidgets('displays No Work Location state when hasWorkLocation is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttendanceGeofenceMapCard(
              officeLatitude: -6.2253,
              officeLongitude: 106.8097,
              userLatitude: null,
              userLongitude: null,
              geofenceRadiusMeters: 50.0,
              isInsideGeofence: false,
              gpsAccuracy: 'Unavailable',
              isAnyWhere: false,
              hasWorkLocation: false,
              isGpsAcquired: false,
              officeName: '',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lokasi Kerja Tidak Tersedia'), findsWidgets);
    });
  });
}
