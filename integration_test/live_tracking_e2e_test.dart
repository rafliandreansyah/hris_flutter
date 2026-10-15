import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/tracking/presentation/pages/live_tracking_screen.dart';
import 'package:hris_flutter/features/tracking/presentation/widgets/live_tracking_summary_bar.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('TRACK-01: Live Tracking menampilkan header & ringkasan tim', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Live Tracking', screen: LiveTrackingScreen);

    // Peta/lokasi dapat meminta izin saat layar dibuka.
    await grantPermissionIfVisible($);
    expect(find.text('Live Tracking'), findsWidgets);
    expect(find.text('Monitoring armada karyawan'), findsOneWidget);

    await waitFor(
      $,
      find.byType(LiveTrackingSummaryBar),
      reason: 'ringkasan status karyawan (summary bar)',
    );
    expectNoErrorState();

    await goBackToDashboard($);
  });
}
