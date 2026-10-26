import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/services/notification_navigation_handler.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';

void main() {
  group('NotificationNavigationHandler Unit Tests', () {
    late NotificationNavigationHandler handler;

    setUp(() {
      handler = NotificationNavigationHandler.instance;
      handler.clearPendingPayload();
    });

    test('cold start pending payload lifecycle works correctly', () {
      expect(handler.pendingPayload, isNull);

      handler.setPendingPayload({'type': 'leave_request', 'id': 'req-123'});
      expect(handler.pendingPayload, isNotNull);
      expect(handler.pendingPayload?['type'], 'leave_request');
      expect(handler.pendingPayload?['id'], 'req-123');

      handler.clearPendingPayload();
      expect(handler.pendingPayload, isNull);
    });

    test('consumePendingPayload returns false when no pending payload or no context', () {
      expect(handler.consumePendingPayload(), isFalse);
    });

    test('handleMessage saves to pending payload when no navigator context available', () {
      const message = RemoteMessage(data: {'type': 'announcement', 'id': 'ann-1'});
      handler.handleMessage(message);

      expect(handler.pendingPayload, isNotNull);
      expect(handler.pendingPayload?['id'], 'ann-1');
    });

    testWidgets('handlePayload navigates to LEAVE_DETAIL when type is leave_request with id', (tester) async {
      String? navigatedRoute;
      Object? navigatedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.LEAVE_DETAIL,
            builder: (context, state) {
              navigatedRoute = Routes.LEAVE_DETAIL;
              navigatedExtra = state.extra;
              return const Scaffold(body: Text('Leave Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'type': 'leave_request',
        'id': 'leave-123',
      });

      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(navigatedRoute, Routes.LEAVE_DETAIL);
      expect(navigatedExtra, {'id': 'leave-123', 'isApprover': false});
    });

    testWidgets('handlePayload identifies isApprover true when type is _new_submission', (tester) async {
      String? navigatedRoute;
      Object? navigatedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.OVERTIME_DETAIL,
            builder: (context, state) {
              navigatedRoute = Routes.OVERTIME_DETAIL;
              navigatedExtra = state.extra;
              return const Scaffold(body: Text('Overtime Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'type': 'overtime_new_submission',
        'id': 'ot-456',
      });

      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(navigatedRoute, Routes.OVERTIME_DETAIL);
      expect(navigatedExtra, {'id': 'ot-456', 'isApprover': true});
    });

    testWidgets('handlePayload navigates to ATTENDANCE_REQUEST_DETAIL with id', (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.ATTENDANCE_REQUEST_DETAIL,
            builder: (context, state) {
              navigatedRoute = Routes.ATTENDANCE_REQUEST_DETAIL;
              return const Scaffold(body: Text('Attendance Request Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'type': 'attendance_request',
        'id': 'att-789',
      });

      expect(handled, isTrue);
      await tester.pumpAndSettle();
      expect(navigatedRoute, Routes.ATTENDANCE_REQUEST_DETAIL);
    });

    testWidgets('handlePayload handles server resignation payload (resignationId & module RESIGNATION)', (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.RESIGNATION,
            builder: (context, state) {
              navigatedRoute = Routes.RESIGNATION;
              return const Scaffold(body: Text('Resignation Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'resignationId': 'res-101',
        'module': 'RESIGNATION',
      });

      expect(handled, isTrue);
      await tester.pumpAndSettle();
      expect(navigatedRoute, Routes.RESIGNATION);
    });

    testWidgets('handlePayload handles asset handover payload', (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.ASSETS,
            builder: (context, state) {
              navigatedRoute = Routes.ASSETS;
              return const Scaffold(body: Text('Assets Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'type': 'asset_handover',
        'assetId': 'asset-99',
      });

      expect(handled, isTrue);
      await tester.pumpAndSettle();
      expect(navigatedRoute, Routes.ASSETS);
    });

    testWidgets('handlePayload handles reimbursement payload', (tester) async {
      String? navigatedRoute;
      Object? navigatedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.REIMBURSEMENT_DETAIL,
            builder: (context, state) {
              navigatedRoute = Routes.REIMBURSEMENT_DETAIL;
              navigatedExtra = state.extra;
              return const Scaffold(body: Text('Reimbursement Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'type': 'reimbursement',
        'id': 'reimb-01',
      });
      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(navigatedRoute, Routes.REIMBURSEMENT_DETAIL);
      expect(navigatedExtra, 'reimb-01');
    });

    testWidgets('handlePayload handles cash advance payload', (tester) async {
      String? navigatedRoute;
      Object? navigatedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.CASH_ADVANCE_DETAIL,
            builder: (context, state) {
              navigatedRoute = Routes.CASH_ADVANCE_DETAIL;
              navigatedExtra = state.extra;
              return const Scaffold(body: Text('Cash Advance Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'type': 'cash_advance',
        'id': 'ca-02',
      });
      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(navigatedRoute, Routes.CASH_ADVANCE_DETAIL);
      expect(navigatedExtra, 'ca-02');
    });

    testWidgets('handlePayload handles web actionUrl paths', (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.ATTENDANCE_LOGS,
            builder: (context, state) {
              navigatedRoute = Routes.ATTENDANCE_LOGS;
              return const Scaffold(body: Text('Riwayat Presensi'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {
        'actionUrl': '/report-kehadiran',
      });

      expect(handled, isTrue);
      await tester.pumpAndSettle();
      expect(navigatedRoute, Routes.ATTENDANCE_LOGS);
    });

    testWidgets('handleNotificationItem extracts data and delegates cleanly', (tester) async {
      String? navigatedRoute;
      Object? navigatedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: Routes.WARNING_LETTER_DETAIL,
            builder: (context, state) {
              navigatedRoute = Routes.WARNING_LETTER_DETAIL;
              navigatedExtra = state.extra;
              return const Scaffold(body: Text('Warning Letter Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      const item = NotificationItemModel(
        id: 'wl-item-1',
        title: 'Surat Peringatan Baru',
        body: 'Anda menerima SP 1',
        type: 'warning_letter',
        data: {'id': 'wl-doc-88'},
      );

      final handled = handler.handleNotificationItem(context, item);

      expect(handled, isTrue);
      await tester.pumpAndSettle();
      expect(navigatedRoute, Routes.WARNING_LETTER_DETAIL);
      expect(navigatedExtra, 'wl-doc-88');
    });

    testWidgets('handlePayload returns false for unknown payload', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final BuildContext context = tester.element(find.text('Home'));

      final handled = handler.handlePayload(context, {'type': 'unknown_type'});
      expect(handled, isFalse);
    });

    group('Pengingat otomatis server', () {
      Future<(bool, List<String>)> run(WidgetTester tester, Map<String, dynamic> payload) async {
        final routes = <String>[];
        GoRoute stub(String path) => GoRoute(
              path: path,
              builder: (context, state) {
                routes.add(path);
                return const Scaffold(body: Text('Stub'));
              },
            );
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('Home'))),
            stub(Routes.ATTENDANCE_REQUESTS),
            stub(Routes.ATTENDANCE_REQUEST_DETAIL),
            stub(Routes.LEAVE),
            stub(Routes.LEAVE_DETAIL),
            stub(Routes.OVERTIME),
            stub(Routes.OVERTIME_DETAIL),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final context = tester.element(find.text('Home'));
        final handled = handler.handlePayload(context, payload);
        await tester.pumpAndSettle();
        return (handled, routes);
      }

      testWidgets('lupa absen pulang → daftar pengajuan absensi, bukan detail (id notifikasi diabaikan)', (tester) async {
        final (handled, routes) = await run(tester, {
          'type': 'attendance_forgot_checkout',
          'id': 'notification-id-bukan-pengajuan',
          'attendanceId': 'att-1',
        });
        expect(handled, isTrue);
        expect(routes, [Routes.ATTENDANCE_REQUESTS]);
      });

      testWidgets('pengingat & eskalasi approver → daftar modul sesuai module', (tester) async {
        for (final type in ['approval_reminder', 'approval_escalation']) {
          final cases = {
            'attendance': Routes.ATTENDANCE_REQUESTS,
            'leave': Routes.LEAVE,
            'overtime': Routes.OVERTIME,
          };
          for (final entry in cases.entries) {
            final (handled, routes) = await run(tester, {
              'type': type,
              'module': entry.key,
              'id': 'notification-id',
            });
            expect(handled, isTrue, reason: '$type/${entry.key}');
            expect(routes, [entry.value], reason: '$type/${entry.key}');
          }
        }
      });

      testWidgets('pengingat tanpa module dikenal → tidak ditangani (fallback modal)', (tester) async {
        final (handled, routes) = await run(tester, {'type': 'approval_reminder'});
        expect(handled, isFalse);
        expect(routes, isEmpty);
      });
    });

    group('Siklus Karyawan (lifecycle_*)', () {
      Future<(bool, List<String>, List<Object?>)> run(
        WidgetTester tester,
        Map<String, dynamic> payload,
      ) async {
        final routes = <String>[];
        final extras = <Object?>[];
        GoRoute stub(String path) => GoRoute(
              path: path,
              builder: (context, state) {
                routes.add(path);
                extras.add(state.extra);
                return const Scaffold(body: Text('Stub'));
              },
            );
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('Home'))),
            stub(Routes.LIFECYCLE_EVALUATION_FORM),
            stub(Routes.LIFECYCLE_EVALUATIONS),
            stub(Routes.LIFECYCLE_TASKS),
            stub(Routes.LIFECYCLE_TEAM_CONTRACTS),
            stub(Routes.RESIGNATION),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final context = tester.element(find.text('Home'));
        final handled = handler.handlePayload(context, payload);
        await tester.pumpAndSettle();
        return (handled, routes, extras);
      }

      testWidgets('lifecycle_evaluation → form dengan fallback ke hasil', (tester) async {
        final (handled, routes, extras) = await run(tester, {
          'type': 'lifecycle_evaluation',
          'id': 'ev-1',
          'module': 'LIFECYCLE',
          'actionUrl': '/lifecycle/evaluation/ev-1',
        });
        expect(handled, isTrue);
        expect(routes, [Routes.LIFECYCLE_EVALUATION_FORM]);
        expect(extras.single, {'id': 'ev-1', 'fallbackToResult': true});
      });

      testWidgets('lifecycle_evaluation tanpa id → daftar penilaian', (tester) async {
        final (handled, routes, _) = await run(tester, {'type': 'lifecycle_evaluation'});
        expect(handled, isTrue);
        expect(routes, [Routes.LIFECYCLE_EVALUATIONS]);
      });

      testWidgets('lifecycle_contract → kontrak berakhir tim (atasan)', (tester) async {
        final (handled, routes, _) =
            await run(tester, {'type': 'lifecycle_contract', 'id': 'k-1'});
        expect(handled, isTrue);
        expect(routes, [Routes.LIFECYCLE_TEAM_CONTRACTS]);
      });

      testWidgets('lifecycle_offboarding → layar resign', (tester) async {
        final (handled, routes, _) =
            await run(tester, {'type': 'lifecycle_offboarding', 'id': 'off-1'});
        expect(handled, isTrue);
        expect(routes, [Routes.RESIGNATION]);
      });

      testWidgets('lifecycle_task & lifecycle_onboarding → daftar tugas', (tester) async {
        for (final t in ['lifecycle_task', 'lifecycle_onboarding']) {
          final (handled, routes, _) = await run(tester, {'type': t, 'id': 'x'});
          expect(handled, isTrue, reason: t);
          expect(routes, [Routes.LIFECYCLE_TASKS], reason: t);
        }
      });

      testWidgets('lifecycle_movement → fallback modal (tidak ditangani)', (tester) async {
        final (handled, routes, _) =
            await run(tester, {'type': 'lifecycle_movement', 'id': 'x', 'module': 'LIFECYCLE'});
        expect(handled, isFalse);
        expect(routes, isEmpty);
      });

      testWidgets('module LIFECYCLE tanpa type spesifik tidak jatuh ke modul lain', (tester) async {
        final (handled, routes, _) = await run(tester, {
          'type': 'lifecycle_offboarding',
          'module': 'LIFECYCLE',
          'actionUrl': '/approval/leaves/abc',
        });
        expect(handled, isTrue);
        expect(routes, [Routes.RESIGNATION]);
      });
    });
  });
}
