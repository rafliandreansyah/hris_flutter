import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_detail_more_menu.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('RequestCardHeader', () {
    testWidgets('hanya menampilkan nama + jabatan dan penanda Anda',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RequestCardHeader(
            name: 'Budi Santoso',
            role: 'Backend Engineer',
            department: 'Engineering',
            isSelf: true,
            trailing: AppStatusChip(label: 'Menunggu Persetujuan'),
          ),
        ),
      );

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Backend Engineer'), findsOneWidget);
      expect(find.text('Engineering'), findsNothing);
      expect(find.text('Pengajuan Anda'), findsOneWidget);
      expect(find.text('Menunggu Persetujuan'), findsOneWidget);
    });

    testWidgets('memakai departemen bila jabatan kosong', (tester) async {
      await tester.pumpWidget(
        _wrap(const RequestCardHeader(name: 'Ani', role: '', department: 'HR')),
      );
      expect(find.text('HR'), findsOneWidget);
    });
  });

  group('RequestDetailPersonCard', () {
    testWidgets('menampilkan info lengkap tanpa terpotong & tanpa kontak',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RequestDetailPersonCard(
            title: 'Informasi Pengaju',
            name: 'Budi Santoso',
            position: 'Backend Engineer',
            department: 'Engineering',
            company: 'PT Nama Perusahaan Yang Sangat Panjang Sekali Tbk',
            employeeNumber: 'EMP-001',
            email: 'budi@example.com',
            phone: '08123456789',
          ),
        ),
      );

      expect(find.text('INFORMASI PENGAJU'), findsOneWidget);
      expect(
        find.text('PT Nama Perusahaan Yang Sangat Panjang Sekali Tbk'),
        findsOneWidget,
      );
      expect(find.text('EMP-001'), findsOneWidget);
      // Kontak hanya untuk approver.
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('budi@example.com'), findsNothing);
    });

    testWidgets('approver melihat tombol Telepon, WhatsApp, dan Email',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RequestDetailPersonCard(
            title: 'Informasi Pengaju',
            name: 'Budi Santoso',
            email: 'budi@example.com',
            phone: '08123456789',
            showContactActions: true,
          ),
        ),
      );

      expect(find.text('Telepon'), findsWidgets);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
    });

    testWidgets('catatan penolakan memakai label Alasan Penolakan',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RequestDetailPersonCard(
            title: 'Pejabat Penyetuju',
            name: 'Alex',
            notes: 'Kuota habis',
            notesLabel: 'Alasan Penolakan',
            isRejected: true,
          ),
        ),
      );

      expect(find.text('Alasan Penolakan'), findsOneWidget);
      expect(find.text('Kuota habis'), findsOneWidget);
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
    });
  });

  group('AppDetailMoreMenu', () {
    testWidgets('menggabungkan Bagikan & Salin Link dalam satu menu',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                AppDetailMoreMenu(
                  items: [
                    AppDetailMenuItem.share(() => tapped.add('share')),
                    AppDetailMenuItem.copyLink(() => tapped.add('link')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.share2), findsNothing);
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      expect(find.text('Bagikan'), findsOneWidget);
      expect(find.text('Salin Link'), findsOneWidget);

      await tester.tap(find.text('Salin Link'));
      await tester.pumpAndSettle();
      expect(tapped, ['link']);
    });

    testWidgets('tidak dirender bila tidak ada item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppDetailMoreMenu(items: []))),
      );
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    });
  });

  group('AppStatusChip', () {
    testWidgets('default tanpa titik indikator', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppStatusChip(label: 'Approved')),
      );
      final dots = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(dots, findsNothing);
    });
  });
}
