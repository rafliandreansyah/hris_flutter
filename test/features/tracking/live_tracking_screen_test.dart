import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:hris_flutter/features/tracking/presentation/pages/live_tracking_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'mock_tracking_repository.dart';

void main() {
  Widget buildTestableWidget({required LiveTrackingBloc bloc}) {
    return MaterialApp(
      home: BlocProvider<LiveTrackingBloc>.value(
        value: bloc,
        child: const LiveTrackingScreen(isTest: true),
      ),
    );
  }

  group('LiveTrackingScreen Widget Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets(
      'renders title, search bar, filter chips, and summary bar when data loaded',
      (tester) async {
      final repo = MockTrackingRepository();
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false)
        ..add(const LiveTrackingStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Live Tracking'), findsOneWidget);
      expect(find.text('Monitoring armada karyawan'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Presensi'), findsWidgets); // chip + summary
      expect(find.text('Dinas'), findsWidgets); // chip + summary
      expect(find.text('Total'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(LucideIcons.focus), findsOneWidget);
    });

    testWidgets('typing search query updates search text in bloc', (tester) async {
      final repo = MockTrackingRepository();
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false)
        ..add(const LiveTrackingStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ahmad');
      await tester.pumpAndSettle();

      expect(bloc.state.searchQuery, 'Ahmad');
      expect(bloc.state.filteredEmployees.length, 1);
    });

    testWidgets('tapping status filter chip filters employees', (tester) async {
      final repo = MockTrackingRepository();
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false)
        ..add(const LiveTrackingStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Tap on 'Dinas' chip
      await tester.tap(find.widgetWithText(GestureDetector, 'Dinas').first);
      await tester.pumpAndSettle();

      expect(bloc.state.selectedStatus, 'activity');
    });

    testWidgets('displays error container with retry button when API fails', (tester) async {
      final repo = MockTrackingRepository();
      repo.shouldThrow = true;
      repo.errorMessage = 'Gagal memuat koordinat live tracking';

      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false)
        ..add(const LiveTrackingStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat koordinat live tracking'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}
