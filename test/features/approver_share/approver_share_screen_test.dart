import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/share_link_util.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';
import 'package:hris_flutter/features/approver_share/domain/repositories/approver_share_repository.dart';
import 'package:hris_flutter/features/approver_share/presentation/pages/approver_share_screen.dart';

class _FakeRepo implements ApproverShareRepository {
  Completer<List<ApproverModel>>? pending;
  List<ApproverModel> approvers = const [];
  Exception? error;

  @override
  Future<List<ApproverModel>> getApprovers({
    required String module,
    required String requestId,
  }) async {
    if (pending != null) return pending!.future;
    if (error != null) throw error!;
    return approvers;
  }
}

const _args = ApproverShareArgs(
  module: ShareModule.leave,
  requestId: 'l1',
  summary: 'Ringkasan cuti',
  subject: 'Cuti Budi',
);

Widget _app(_FakeRepo repo) => MaterialApp(
      home: ApproverShareScreen(args: _args, repository: repo),
    );

void main() {
  testWidgets('menampilkan shimmer saat memuat', (tester) async {
    final repo = _FakeRepo()..pending = Completer();
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.byType(RequestCardShimmerLoading), findsOneWidget);
    repo.pending!.complete(const []);
  });

  testWidgets('menampilkan atasan dengan tombol WhatsApp & Email sesuai kontak',
      (tester) async {
    final repo = _FakeRepo()
      ..approvers = const [
        ApproverModel(
          id: 'e1',
          fullName: 'Siti Atasan',
          position: 'Manager',
          phone: '08123',
          email: 'siti@kantor.id',
        ),
        ApproverModel(id: 'e2', fullName: 'Budi Tanpa Kontak'),
      ];
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Bagikan ke Atasan'), findsOneWidget);
    expect(find.byType(EmployeeInfoRow), findsNWidgets(2));
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(
      find.text('Nomor HP & email atasan belum tersedia di data pegawai.'),
      findsOneWidget,
    );
    // Salin link & bagikan manual selalu tersedia di bawah.
    expect(find.text('Salin Link'), findsOneWidget);
    expect(find.text('Bagikan Lainnya'), findsOneWidget);
  });

  testWidgets('daftar kosong menampilkan empty state dengan Salin Link',
      (tester) async {
    await tester.pumpWidget(_app(_FakeRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Atasan'), findsOneWidget);
    // Satu di empty state, satu di bottom bar.
    expect(find.text('Salin Link'), findsNWidgets(2));
  });

  testWidgets('error API menampilkan pesan dari server dan tombol Coba Lagi',
      (tester) async {
    final repo = _FakeRepo()
      ..error = const ApiException(message: 'Akses ditolak', statusCode: 403);
    await tester.pumpWidget(_app(repo));
    // Dialog error punya animasi berulang, jadi pakai pump berdurasi, bukan pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Gagal Memuat Atasan'), findsOneWidget);
    expect(find.text('Akses ditolak'), findsWidgets);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
